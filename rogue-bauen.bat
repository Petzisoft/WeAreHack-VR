@echo off
rem Baut rogue.exe aus dem Quellcode in rogue-src (Ergebnis: build\rogue.exe)
cd /d "%~dp0"
if not exist build mkdir build
set MSYSTEM=UCRT64
set CHERE_INVOKING=1
C:\msys64\usr\bin\bash.exe -lc "cd rogue-src && gcc -std=gnu89 -O2 -w -DPDC_FORCE_UTF8 -I/ucrt64/include/pdcurses -DALLSCORES -DNUMSCORES=10 -DNUMNAME='\"Ten\"' -DSCOREFILE='\"rogue54.scr\"' -DLOCKFILE='\"rogue54.lck\"' vers.c extern.c armor.c chase.c command.c daemon.c daemons.c fight.c init.c io.c list.c mach_dep.c main.c mdport.c misc.c monsters.c move.c new_level.c options.c pack.c passages.c potions.c rings.c rip.c rooms.c save.c scrolls.c state.c sticks.c things.c weapons.c wizard.c xcrypt.c -static -l:libpdcurses_wincon.a -lwinmm -o ../build/rogue.exe > ../build/build-log.txt 2>&1"
if exist build\rogue.exe (
  echo.
  echo Fertig: build\rogue.exe wurde gebaut.
) else (
  echo.
  echo Es gab einen Fehler. Details in build\build-log.txt
)
pause
