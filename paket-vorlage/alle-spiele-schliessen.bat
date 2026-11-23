@echo off
rem Schliesst alle laufenden We-Are-Hack-Fenster (Godot, Bruecke, Rogue, NetHack)
taskkill /f /im Godot_v4.7.2-stable_win64.exe >/dev/null 2>&1
taskkill /f /im rogue-bruecke.exe >/dev/null 2>&1
taskkill /f /im rogue.exe >/dev/null 2>&1
taskkill /f /im NetHack.exe >/dev/null 2>&1
echo Alle Spielfenster geschlossen.
timeout /t 2 >nul
