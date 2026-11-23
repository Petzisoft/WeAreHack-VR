#!/bin/bash
# Baut Hack 1.0.3 (NetBSD src/games/hack) fuer Windows mit MSYS2-UCRT64-gcc.
# Ergebnis: hack-spiel\hack.exe samt Datendateien (data, help, hh, rumors, record, perm, save\).
# Der Original-Quelltext bleibt unveraendert; die Windows-Anpassung steckt in hack-src/wah/
# (wah_compat.h wird vor jede Datei gesetzt, wah_term.c: ANSI-Ausgabe in die Konsole, Tasten roh).
# Achtung: der Projektpfad enthaelt Leerzeichen -> innen nur relative Pfade benutzen.
set -e
export PATH=/ucrt64/bin:/usr/bin:$PATH
cd "$(dirname "$0")"
mkdir -p build-hack hack-spiel/save
cd hack-src
CF="-std=gnu99 -O2 -w -I../build-hack -I. -Iwah -include wah/wah_compat.h"
echo "== makedefs"
gcc $CF -o ../build-hack/makedefs.exe makedefs.c wah/wah_term.c
../build-hack/makedefs.exe def.objects.h > ../build-hack/hack.onames.h
echo "== hack.exe"
gcc $CF $(ls *.c | grep -v '^makedefs.c$') wah/*.c -o ../build-hack/hack.exe
cp -f ../build-hack/hack.exe data help hh rumors ../hack-spiel/
# Bestenliste und Sperrdatei nur anlegen, wenn sie fehlen (nie einen Spielstand ueberschreiben)
[ -f ../hack-spiel/record ] || : > ../hack-spiel/record
[ -f ../hack-spiel/perm ] || : > ../hack-spiel/perm
echo "Fertig: hack-spiel/hack.exe"
