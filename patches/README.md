# Patches für fremde Quellen

Die fremden Quellen liegen als eigene Git-Klone im Projektordner und sind
**nicht** Teil dieses Repos (siehe `.gitignore`). Unsere Änderungen daran
stehen hier als Patch-Dateien, damit sie mitversioniert sind.

Stand: 22.11.2026.

## rogue/ – Rogue 5.4 (für `rogue-src\`)

- Quelle: https://github.com/Davidslv/rogue
- Branch: `master`
- Basis-Commit: `f4653c2a2ee6981a73abe9dfda055134285e1e79` (= `origin/master`)
- Unser Commit: `ca80144` – Fühler-Datei, Klang-/Gangmeldungen, PDCurses-Fix in `main.c`
- Erzeugt mit: `git -C rogue-src format-patch origin/master -o patches/rogue`

Anwenden:

```
git clone https://github.com/Davidslv/rogue rogue-src
git -C rogue-src checkout f4653c2a2ee6981a73abe9dfda055134285e1e79
git -C rogue-src am ../patches/rogue/*.patch
```

## nethack/ – NetHack 3.6.7 (für `nethack-src\`)

- Quelle: https://github.com/NetHack/NetHack.git
- Tag: `NetHack-3.6.7_Released` (Commit `ed600d9f0f3c37677418f0150f59363ca641f3dc`)
- Unser Commit: `6d2b169` – Sonde `src/wah_sonde.c` (+ Aufruf in `src/allmain.c`) für die 3D-/VR-Ansicht
- Erzeugt mit: `git -C nethack-src format-patch NetHack-3.6.7_Released -o patches/nethack`

Anwenden:

```
git clone https://github.com/NetHack/NetHack.git nethack-src
git -C nethack-src checkout NetHack-3.6.7_Released
git -C nethack-src am ../patches/nethack/*.patch
```

Danach bauen mit `nethack-bauen.bat`.

## unirig/ – UniRig (für `werkzeuge\UniRig\`)

- Quelle: https://github.com/VAST-AI-Research/UniRig.git
- Branch: `main`, Basis-Commit `6793c66` („Update README.md“)
- Keine lokalen Commits, nur ungespeicherte Änderungen:
  - `0001-unirig-lokale-aenderungen.diff` (aus `git diff`):
    `configs/model/unirig_ar_350m_1024_81920_float32.yaml` (`flash_attention_2` → `sdpa`)
    und `run.py` (Box als sichere Klasse für `torch.load`).
  - `eigene-skripte/`: unsere eigenen Skripte, die im UniRig-Ordner liegen
    (nicht vom UniRig-Projekt): `monster3d_fertig.py`, `troll_*.py`,
    `gewichte_neu.py`, `keule_anstecken.py`, `dreh_gif.py`.
- Nicht übernommen: die Arbeitsordner `aus/`, `ein/`, `mixamo/` (3D-Modelle).

Anwenden:

```
git clone https://github.com/VAST-AI-Research/UniRig.git werkzeuge/UniRig
git -C werkzeuge/UniRig checkout 6793c66
git -C werkzeuge/UniRig apply ../../patches/unirig/0001-unirig-lokale-aenderungen.diff
copy patches\unirig\eigene-skripte\*.py werkzeuge\UniRig\
```

## hack-src\ – Hack 1.0.3

Dateien aus NetBSD `src/games/hack`, kein Git, bisher unverändert –
daher kein Patch.
