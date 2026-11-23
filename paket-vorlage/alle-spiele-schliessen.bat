@echo off
rem Schliesst alle laufenden We-Are-Hack-Fenster (Godot, Bruecke, Rogue, Hack, NetHack)
taskkill /f /im Godot_v4.7.2-stable_win64.exe >nul 2>&1
taskkill /f /im rogue-bruecke.exe >nul 2>&1
taskkill /f /im rogue.exe >nul 2>&1
taskkill /f /im hack.exe >nul 2>&1
taskkill /f /im NetHack.exe >nul 2>&1
echo Alle Spielfenster geschlossen.
timeout /t 2 >nul
