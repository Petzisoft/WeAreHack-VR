@echo off
rem Baut NetHack 3.6.7 mit der We-Are-Hack-Sonde (Ergebnis: nethack-spiel\NetHack.exe)
rem Dauert ein paar Minuten. Protokoll: nethack-src\bau-log.txt
cd /d "%~dp0"
set MSYSTEM=UCRT64
set CHERE_INVOKING=1
echo NetHack wird gebaut, bitte warten ...
C:\msys64\usr\bin\bash.exe -lc "bash ./nethack-bauen.sh" > nethack-src\bau-log.txt 2>&1
if exist nethack-spiel\NetHack.exe (
  echo.
  echo Fertig: nethack-spiel\NetHack.exe wurde gebaut.
) else (
  echo.
  echo Es gab einen Fehler. Details in nethack-src\bau-log.txt
)
pause
