#!/bin/bash
# Baut NetHack 3.6.7 (Konsolenversion, tty) aus nethack-src mit MSYS2-UCRT64-gcc.
# Ergebnis: nethack-spiel\NetHack.exe samt Datendateien. Aufruf ueber nethack-bauen.bat.
# Das Makefile von NetHack braucht cmd.exe und mingw32-make, darum dieses eigene Skript.
# Achtung: der Projektpfad enthaelt Leerzeichen -> innen nur relative Pfade benutzen.
set -e
export PATH=/ucrt64/bin:/usr/bin:$PATH
cd "$(dirname "$0")"
SPIEL="$(pwd)/nethack-spiel"
mkdir -p nethack-spiel nethack-src/obj-wah
cd nethack-src
O=../obj-wah        # von util, src, dat aus gesehen

CFLAGS="-c -O2 -w -std=gnu11 -mms-bitfields -fcommon -I../include -I../sys/winnt -I../win/share -DTILES -DMSWIN_GRAPHICS -DWIN32CON -DDLB -D_WIN32_WINNT=0x0601 -DWINVER=0x0601 -DSAFEPROCS"
cc() { gcc $CFLAGS "$@"; }

echo "== 1. makedefs"
cd util
cc -o $O/makedefs.o makedefs.c
cc -o $O/monst.o ../src/monst.c
cc -o $O/objects.o ../src/objects.c
gcc -o makedefs.exe $O/makedefs.o $O/monst.o $O/objects.o
for a in -v -o -p -z -d -r -q -h -s -e; do echo "makedefs $a"; ./makedefs.exe $a; done

echo "== 2. lev_comp, dgn_comp"
cp -f ../sys/share/lev_comp.h ../sys/share/dgn_comp.h ../include/
cp -f ../sys/share/lev_yacc.c ../sys/share/lev_lex.c ../sys/share/dgn_yacc.c ../sys/share/dgn_lex.c .
for f in lev_yacc lev_lex lev_main dgn_yacc dgn_lex dgn_main panic; do cc -o $O/u_$f.o $f.c; done
cc -o $O/alloc.o ../src/alloc.c
cc -o $O/decl.o ../src/decl.c
cc -o $O/drawing.o ../src/drawing.c
gcc -o levcomp.exe $O/u_lev_yacc.o $O/u_lev_lex.o $O/u_lev_main.o $O/u_panic.o $O/alloc.o $O/decl.o $O/drawing.o $O/monst.o $O/objects.o
gcc -o dgncomp.exe $O/u_dgn_yacc.o $O/u_dgn_lex.o $O/u_dgn_main.o $O/u_panic.o $O/alloc.o

echo "== 2b. tilemap (erzeugt src/tile.c)"
cc -o $O/tilemap.o ../win/share/tilemap.c
gcc -o tilemap.exe $O/tilemap.o $O/u_panic.o $O/alloc.o $O/decl.o $O/drawing.o $O/monst.o $O/objects.o
./tilemap.exe

echo "== 3. Ebenen und Verlies"
cd ../dat
for d in *.des; do echo "levcomp $d"; ../util/levcomp.exe "$d"; done
../util/dgncomp.exe dungeon.pdf

echo "== 4. Spiel"
cd ../src
OBJS=""
for f in *.c; do
  b=${f%.c}
  echo "cc $f"; cc -o $O/g_$b.o $f; OBJS="$OBJS $O/g_$b.o"
done
for f in ../sys/winnt/windmain.c ../sys/winnt/winnt.c ../sys/winnt/win10.c ../sys/winnt/nttty.c ../sys/winnt/ntsound.c \
         ../sys/share/pmatchregex.c ../sys/share/nhlan.c ../win/share/safeproc.c \
         ../win/tty/topl.c ../win/tty/getline.c ../win/tty/wintty.c; do
  b=$(basename $f .c)
  echo "cc $f"; cc -o $O/s_$b.o $f; OBJS="$OBJS $O/s_$b.o"
done
cc -DGUISTUB -o $O/s_guistub.o ../sys/winnt/stubs.c; OBJS="$OBJS $O/s_guistub.o"
echo "Linken"
gcc -static -o "$SPIEL/NetHack.exe" $OBJS -lgdi32 -lwinmm -lshell32 -lole32 -luuid -lbcrypt

echo "== 5. Datenarchiv nhdat"
cd ../util
cc -o $O/u_dlb_main.o dlb_main.c
gcc -o dlb_main.exe $O/u_dlb_main.o $O/g_dlb.o $O/alloc.o $O/u_panic.o
cd ../dat
cp -f ../sys/winnt/porthelp porthelp
: > dlb.lst
for f in data oracles options ttyoptions guioptions porthelp quest.dat rumors help hh cmdhelp keyhelp history opthelp wizhelp dungeon license engrave epitaph bogusmon tribute; do
  [ -f "$f" ] && echo "$f" >> dlb.lst
done
ls *.lev >> dlb.lst
rm -f nhdat*
../util/dlb_main.exe cIf dlb.lst nhdat
ls nhdat*
cp -f nhdat* "$SPIEL/"
cp -f license symbols "$SPIEL/" 2>/dev/null || true
cp -f ../sys/winnt/sysconf.template "$SPIEL/sysconf"
cp -f ../sys/winnt/sysconf.template ../sys/winnt/.nethackrc.template opthelp ../doc/Guidebook.txt "$SPIEL/"
cp -f symbols "$SPIEL/symbols.template"
for f in record logfile xlogfile; do [ -f "$SPIEL/$f" ] || : > "$SPIEL/$f"; done
echo "Fertig: $SPIEL/NetHack.exe"
