@echo off
rem Baut Hack 1.0.3 (1982/1985) fuer Windows (Ergebnis: hack-spiel\hack.exe)
rem Protokoll: build-hack\bau-log.txt
cd /d "%~dp0"
if not exist build-hack mkdir build-hack
set MSYSTEM=UCRT64
set CHERE_INVOKING=1
echo Hack wird gebaut, bitte warten ...
C:\msys64\usr\bin\bash.exe -lc "bash ./hack-bauen.sh" > build-hack\bau-log.txt 2>&1
if exist build-hack\hack.exe (
  echo.
  echo Fertig: hack-spiel\hack.exe wurde gebaut.
) else (
  echo.
  echo Es gab einen Fehler. Details in build-hack\bau-log.txt
)
if not "%1"=="ohnepause" pause
