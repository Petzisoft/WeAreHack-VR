#!/bin/bash
# Rechnet aus dem (einen) Bild jedes NetHack-Monsters ein 3D-Modell mit TRELLIS.2 (grafik-test/trellis_api.py, MIT).
# Quelle: roh/<Schlüssel>_<nr>_00001_.png (neueste Datei; Fehlbilder vorher nach aussortiert/), Ziel: 3d/<Schlüssel>.glb
# Bereits vorhandene Modelle werden übersprungen. Aufruf: bash trellis_alle.sh
HIER="/c/Users/admin/Claude/We Are Hack/nethack-monster"
cd "$HIER"; mkdir -p 3d auftraege
# Nur ein Lauf gleichzeitig (Peter startete 21.11. schon um 17:40, die 22-Uhr-Aufgabe soll nicht doppelt rechnen)
if [ -f laeuft.lock ] && [ $(( $(date +%s) - $(stat -c %Y laeuft.lock) )) -lt 43200 ]; then echo "$(date) Lauf aktiv, Abbruch"; exit 0; fi
touch laeuft.lock; trap 'rm -f laeuft.lock' EXIT
export PYTHONIOENCODING=utf8 FLAECHEN=40000
for key in $(grep -v '^#' nethack_texte.txt | cut -d'|' -f2); do
  [ -f "3d/$key.glb" ] && continue
  roh=$(ls -t roh/${key}_[0-9]*_00001_.png 2>/dev/null | head -1)
  [ -z "$roh" ] && { echo "KEIN BILD $key"; continue; }
  until curl -s -m 5 -o /dev/null http://127.0.0.1:8188/system_stats; do sleep 30; done
  # mit Standprüfung (Peter 22.11.): aufrechte Figuren (Stil S/A/W) werden gemessen und bei Schieflage neu gerechnet
  stil=$(grep -h "^[^|]*|${key}|" nethack_texte.txt | cut -d'|' -f3); neu=$(grep -h "^${key}|" texte_neu.txt 2>/dev/null | tail -1 | cut -d'|' -f2); [ -n "$neu" ] && stil=$neu
  case "$stil" in S|A|W) auf=1;; *) auf=0;; esac
  "/c/Users/admin/Claude/We Are Hack/werkzeuge/UniRig/.venv/Scripts/python.exe" "../grafik-test/trellis_geprueft.py" "$HIER/$roh" "nh_${key}" "$HIER/3d/$key.glb" 0 $auf 2>&1 | grep -E "^(OK|KAPUTT|FEHLER)"
done
# Hack-Monster (Peters Auswahl) ebenso
HACK="/c/Users/admin/Claude/We Are Hack/hack-monster"
mkdir -p "$HACK/3d"
for roh in "$HACK"/gewaehlt/*_roh.png; do
  key=$(basename "$roh" _roh.png)
  [ -f "$HACK/3d/$key.glb" ] && continue
  until curl -s -m 5 -o /dev/null http://127.0.0.1:8188/system_stats; do sleep 30; done
  "/c/Users/admin/Claude/We Are Hack/werkzeuge/UniRig/.venv/Scripts/python.exe" "../grafik-test/trellis_geprueft.py" "$roh" "hk_${key}" "$HACK/3d/$key.glb" 0 1 2>&1 | grep -E "^(OK|KAPUTT|FEHLER)"
done
echo "ALLE 3D FERTIG"
