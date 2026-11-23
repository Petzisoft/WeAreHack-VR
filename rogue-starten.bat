@echo off
rem Startet Rogue im Konsolenfenster (80x24)
cd /d "%~dp0build"
mode con: cols=80 lines=25
rogue.exe
pause
