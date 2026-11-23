/*
 * rogue-bruecke.c  -  Verbindung zwischen Rogue und Godot ("We Are Hack")
 *
 * Startet build\rogue.exe in einer unsichtbaren 80x25-Konsole, liest deren
 * Zeichenraster aus und schreibt es als Text auf stdout. Bytes, die auf stdin
 * ankommen, werden als Tastendruecke an Rogue weitergegeben.
 * Rogue selbst bleibt dabei voellig unveraendert.
 *
 * Protokoll (Bruecke -> Godot), UTF-8, zeilenweise:
 *   FRAME <spalten> <zeilen> <cursor_x> <cursor_y>
 *   <zeilen> Textzeilen mit je <spalten> Zeichen
 *   ...
 *   EXIT                       (Rogue wurde beendet)
 *   ERROR <text>               (etwas ging schief)
 *
 * Protokoll (Godot -> Bruecke): jedes Byte ist eine Taste (ASCII,
 * 1..26 = Strg+A..Z, 27 = Escape, 13 = Enter, 8 = Ruecktaste).
 *
 * Aufruf: rogue-bruecke.exe [pfad\zu\rogue.exe]
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define COLS 80
#define ROWS 25
/* Exit-Code des Starters, wenn rogue.exe nicht startet: STARTFEHLER + Windows-Fehlercode */
#define STARTFEHLER 100000

static HANDLE out_pipe, in_pipe;      /* Verbindung zu Godot */
static HANDLE con_in, con_out;        /* unsichtbare Konsole von Rogue */
static HANDLE rogue_proc, the_job;

static void send_text(const char *s)
{
    DWORD n;
    WriteFile(out_pipe, s, (DWORD)strlen(s), &n, NULL);
}

static void fail(const char *what)
{
    char buf[256];
    snprintf(buf, sizeof buf, "ERROR %s (Code %lu)\n", what, GetLastError());
    send_text(buf);
}

/* Ist der Starter beendet, weil rogue.exe nicht starten konnte? Dann den Grund an Godot melden. */
static int startfehler_melden(HANDLE starter)
{
    DWORD code = 0;
    char b[160];
    if (WaitForSingleObject(starter, 0) != WAIT_OBJECT_0 || !GetExitCodeProcess(starter, &code)
        || code < STARTFEHLER)
        return 0;
    snprintf(b, sizeof b, "ERROR rogue.exe konnte nicht gestartet werden (Windows-Fehler %lu)\n",
             (unsigned long)(code - STARTFEHLER));
    send_text(b);
    return 1;
}

/* Eine Taste als Druecken + Loslassen in die Konsole von Rogue schreiben */
static void send_key(unsigned char ch)
{
    INPUT_RECORD rec[2];
    WORD vk = 0;
    DWORD state = 0, n;

    if (ch == 27)       vk = VK_ESCAPE;
    else if (ch == 13 || ch == 10) { vk = VK_RETURN; ch = 13; }
    else if (ch == 8)   vk = VK_BACK;
    else if (ch == 9)   vk = VK_TAB;
    else if (ch >= 1 && ch <= 26) { vk = (WORD)('A' + ch - 1); state = LEFT_CTRL_PRESSED; }
    else {
        SHORT s = VkKeyScanA((CHAR)ch);
        if (s != -1) {
            vk = LOBYTE(s);
            if (HIBYTE(s) & 1) state |= SHIFT_PRESSED;
        }
    }

    ZeroMemory(rec, sizeof rec);
    rec[0].EventType = KEY_EVENT;
    rec[0].Event.KeyEvent.bKeyDown = TRUE;
    rec[0].Event.KeyEvent.wRepeatCount = 1;
    rec[0].Event.KeyEvent.wVirtualKeyCode = vk;
    rec[0].Event.KeyEvent.wVirtualScanCode = (WORD)MapVirtualKeyA(vk, 0);
    rec[0].Event.KeyEvent.uChar.UnicodeChar = (WCHAR)ch;
    rec[0].Event.KeyEvent.dwControlKeyState = state;
    rec[1] = rec[0];
    rec[1].Event.KeyEvent.bKeyDown = FALSE;
    WriteConsoleInputW(con_in, rec, 2, &n);
}

/* Liest Tasten von Godot (laeuft in eigenem Thread) */
static DWORD WINAPI input_thread(LPVOID arg)
{
    unsigned char buf[64];
    DWORD n, i;
    (void)arg;
    while (ReadFile(in_pipe, buf, sizeof buf, &n, NULL) && n > 0)
        for (i = 0; i < n; i++)
            send_key(buf[i]);
    /* Godot hat die Verbindung geschlossen -> Rogue beenden */
    TerminateJobObject(the_job, 0);
    ExitProcess(0);
    return 0;
}

static void size_console(void)
{
    COORD size = { COLS, ROWS };
    SMALL_RECT win = { 0, 0, COLS - 1, ROWS - 1 };
    SMALL_RECT tiny = { 0, 0, 0, 0 };
    /* Erst Fenster klein, dann Puffer, dann Fenster passend */
    SetConsoleWindowInfo(con_out, TRUE, &tiny);
    SetConsoleScreenBufferSize(con_out, size);
    SetConsoleWindowInfo(con_out, TRUE, &win);
}

int main(int argc, char **argv)
{
    char exe[MAX_PATH], dir[MAX_PATH], cmd[3 * MAX_PATH], *slash;
    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    HANDLE job;
    JOBOBJECT_EXTENDED_LIMIT_INFORMATION jl;
    WCHAR screen[COLS * ROWS], last[COLS * ROWS];
    COORD last_cur = { -1, -1 };
    int first = 1;

    char self[MAX_PATH], scmd[5 * MAX_PATH];
    int i;

    /* --- Starter-Modus: laeuft in der versteckten Konsole, stellt sie auf
     *     80x25 und startet erst dann Rogue darin. --- */
    if (argc > 2 && strcmp(argv[1], "--starter") == 0) {
        DWORD code = 1;
        if (strlen(argv[2]) >= sizeof dir)
            return STARTFEHLER + ERROR_FILENAME_EXCED_RANGE;
        snprintf(dir, sizeof dir, "%s", argv[2]);
        if ((slash = strrchr(dir, '\\')) != NULL) *slash = 0;
        snprintf(cmd, sizeof cmd, "\"%.250s\"", argv[2]);
        /* weitere Argumente an das Spiel weitergeben (z. B. Rogue-Spielstand zum Laden) */
        for (i = 3; i < argc; i++)
            snprintf(cmd + strlen(cmd), sizeof cmd - strlen(cmd), " \"%.250s\"", argv[i]);
        con_out = CreateFileA("CONOUT$", GENERIC_READ | GENERIC_WRITE,
                              FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
        ShowWindow(GetConsoleWindow(), SW_HIDE);
        size_console();
        ZeroMemory(&si, sizeof si);
        si.cb = sizeof si;
        if (!CreateProcessA(argv[2], cmd, NULL, NULL, FALSE, 0, NULL, dir, &si, &pi))
            return (int)(STARTFEHLER + GetLastError());
        WaitForSingleObject(pi.hProcess, INFINITE);
        GetExitCodeProcess(pi.hProcess, &code);
        return (int)code;
    }

    out_pipe = GetStdHandle(STD_OUTPUT_HANDLE);
    in_pipe  = GetStdHandle(STD_INPUT_HANDLE);

    /* Pfad zu rogue.exe: Argument, sonst ..\build\rogue.exe neben der Bruecke */
    {
        DWORD n = GetModuleFileNameA(NULL, self, MAX_PATH);
        if (n == 0 || n >= MAX_PATH) {
            send_text("ERROR Der Ordnerpfad des Spiels ist zu lang. Bitte das Spiel in einen kuerzeren Ordner legen.\n");
            return 1;
        }
    }
    {
        char roh[MAX_PATH + 32];
        DWORD n;
        if (argc > 1) {
            snprintf(roh, sizeof roh, "%s", argv[1]);
        } else {
            snprintf(dir, sizeof dir, "%s", self);
            if ((slash = strrchr(dir, '\\')) != NULL) *slash = 0;
            snprintf(roh, sizeof roh, "%s\\..\\build\\rogue.exe", dir);
        }
        n = GetFullPathNameA(roh, MAX_PATH, exe, NULL);
        if (n == 0 || n >= MAX_PATH) {
            send_text("ERROR Der Ordnerpfad des Spiels ist zu lang. Bitte das Spiel in einen kuerzeren Ordner legen.\n");
            return 1;
        }
    }
    if (GetFileAttributesA(exe) == INVALID_FILE_ATTRIBUTES) {
        char b[MAX_PATH + 48];
        snprintf(b, sizeof b, "ERROR rogue.exe nicht gefunden: %s\n", exe);
        send_text(b);
        return 1;
    }
    snprintf(scmd, sizeof scmd, "\"%s\" --starter \"%s\"", self, exe);
    for (i = 2; i < argc; i++)
        snprintf(scmd + strlen(scmd), sizeof scmd - strlen(scmd), " \"%.250s\"", argv[i]);

    /* Rogue soll sterben, wenn die Bruecke endet */
    job = CreateJobObjectA(NULL, NULL);
    ZeroMemory(&jl, sizeof jl);
    jl.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
    SetInformationJobObject(job, JobObjectExtendedLimitInformation, &jl, sizeof jl);
    the_job = job;

    /* Starter (und damit Rogue) mit eigener, versteckter Konsole starten */
    ZeroMemory(&si, sizeof si);
    si.cb = sizeof si;
    si.dwFlags = STARTF_USESHOWWINDOW | STARTF_USECOUNTCHARS;
    si.wShowWindow = SW_HIDE;
    si.dwXCountChars = COLS;
    si.dwYCountChars = ROWS;
    if (!CreateProcessA(self, scmd, NULL, NULL, FALSE,
                        CREATE_NEW_CONSOLE | CREATE_SUSPENDED,
                        NULL, NULL, &si, &pi)) {
        fail("rogue.exe konnte nicht gestartet werden");
        return 1;
    }
    AssignProcessToJobObject(job, pi.hProcess);
    ResumeThread(pi.hThread);
    rogue_proc = pi.hProcess;

    /* An Rogues Konsole andocken, um sie lesen und beschreiben zu koennen */
    FreeConsole();
    {
        int tries;
        BOOL ok = FALSE;
        for (tries = 0; tries < 100 && !ok; tries++) {
            ok = AttachConsole(pi.dwProcessId);
            if (!ok) Sleep(20);
        }
        if (!ok) {
            /* Starter schon fertig? Dann konnte er rogue.exe nicht starten -> echten Grund melden */
            if (!startfehler_melden(pi.hProcess))
                fail("Konsole von Rogue nicht erreichbar");
            TerminateProcess(pi.hProcess, 1);
            return 1;
        }
    }
    /* AttachConsole kann die Standard-Handles umbiegen -> Godot-Rohre behalten */
    SetStdHandle(STD_OUTPUT_HANDLE, out_pipe);
    SetStdHandle(STD_INPUT_HANDLE, in_pipe);

    con_out = CreateFileA("CONOUT$", GENERIC_READ | GENERIC_WRITE,
                          FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
    con_in  = CreateFileA("CONIN$", GENERIC_READ | GENERIC_WRITE,
                          FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
    if (con_out == INVALID_HANDLE_VALUE || con_in == INVALID_HANDLE_VALUE) {
        fail("Konsole nicht lesbar"); TerminateProcess(pi.hProcess, 1); return 1;
    }
    ShowWindow(GetConsoleWindow(), SW_HIDE);

    CloseHandle(pi.hThread);
    CreateThread(NULL, 0, input_thread, NULL, 0, NULL);

    /* Hauptschleife: Bildschirm abfragen und bei Aenderung senden */
    for (;;) {
        CONSOLE_SCREEN_BUFFER_INFO info;
        COORD origin = { 0, 0 };
        DWORD got, alive;
        int r;

        alive = WaitForSingleObject(pi.hProcess, 30);

        /* PDCurses legt einen eigenen Bildschirmpuffer an und schaltet um.
         * CONOUT$ zeigt immer auf den gerade aktiven -> jedes Mal neu oeffnen. */
        {
            HANDLE h = CreateFileA("CONOUT$", GENERIC_READ | GENERIC_WRITE,
                                   FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
            if (h != INVALID_HANDLE_VALUE) {
                CloseHandle(con_out);
                con_out = h;
            }
        }

        if (GetConsoleScreenBufferInfo(con_out, &info)) {
            /* Rogue kann die Groesse beim Start aendern; Fensterbereich lesen */
            origin.X = info.srWindow.Left;
            origin.Y = info.srWindow.Top;
            for (r = 0; r < ROWS; r++) {
                COORD at = { origin.X, (SHORT)(origin.Y + r) };
                if (!ReadConsoleOutputCharacterW(con_out, screen + r * COLS, COLS, at, &got))
                    got = 0;
                while (got < COLS) screen[r * COLS + got++] = L' ';
            }
            info.dwCursorPosition.X -= origin.X;
            info.dwCursorPosition.Y -= origin.Y;

            if (first || memcmp(screen, last, sizeof screen) != 0 ||
                info.dwCursorPosition.X != last_cur.X || info.dwCursorPosition.Y != last_cur.Y) {
                static char frame[COLS * ROWS * 4 + ROWS + 64];
                int len = snprintf(frame, 64, "FRAME %d %d %d %d\n", COLS, ROWS,
                                   info.dwCursorPosition.X, info.dwCursorPosition.Y);
                for (r = 0; r < ROWS; r++) {
                    WCHAR line[COLS];
                    int c;
                    for (c = 0; c < COLS; c++) {
                        WCHAR w = screen[r * COLS + c];
                        line[c] = (w < 32 || w == 127) ? L' ' : w;
                    }
                    len += WideCharToMultiByte(CP_UTF8, 0, line, COLS, frame + len,
                                               (int)sizeof frame - len - 2, NULL, NULL);
                    frame[len++] = '\n';
                }
                {
                    DWORD n;
                    if (!WriteFile(out_pipe, frame, (DWORD)len, &n, NULL))
                        break;  /* Godot ist weg */
                }
                memcpy(last, screen, sizeof screen);
                last_cur = info.dwCursorPosition;
                first = 0;
            }
        }
        if (alive == WAIT_OBJECT_0) {
            if (!startfehler_melden(pi.hProcess))
                send_text("EXIT\n");
            break;
        }
    }
    TerminateJobObject(job, 0);
    return 0;
}
