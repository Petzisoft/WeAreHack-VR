# Third-party notices

We Are Hack is a fan project. It is not affiliated with or endorsed by the authors of Rogue,
the NetHack DevTeam, the Godot project or any of the creators listed below. Their names are
used only to give credit, never to promote this project.

The full licence texts are in the folder [`lizenzen/`](lizenzen/).

## Games

| Part | Copyright | Licence | What we did |
|---|---|---|---|
| **Rogue 5.4.4** | © 1980–1983, 1985, 1999 Michael Toy, Ken Arnold, Glenn Wichman (source via [Davidslv/rogue](https://github.com/Davidslv/rogue)) | BSD-style, `lizenzen/Rogue-Lizenz.txt` | Small additions so the 3D view can read the screen, see `patches/rogue/` |
| **NetHack 3.6.7** | © Stichting Mathematisch Centrum, M. Stephenson and the NetHack DevTeam ([nethack.org](https://www.nethack.org)) | NetHack General Public License, `lizenzen/NetHack-Lizenz.txt` | Added a read-only probe (`wah_sonde.c`) and one call to it, see `patches/nethack/`. Game rules are unchanged. |

**This is a modified version of NetHack, not the version distributed by the NetHack DevTeam.**
As required by the NetHack General Public License, the changed files carry a notice with the
date of the change, the complete NetHack source code with our changes is included in the
installer (folder `quelltext\nethack`), and our NetHack changes are licensed under the NetHack
General Public License. NetHack comes with no warranty.

Rogue was compiled with PDCurses (public domain, `lizenzen/PDCurses-Hinweis.txt`) and the
MinGW-w64 runtime (`lizenzen/MinGW-w64-Laufzeit-Lizenz.txt`, `lizenzen/winpthreads-Lizenz.txt`).

## Engine

**Godot Engine 4.7** – MIT licence, © 2014-present Godot Engine contributors, © 2007-2014 Juan
Linietsky, Ariel Manzur. Godot contains third-party components with their own free licences,
including FreeType (portions of this software are copyright © The FreeType Project,
www.freetype.org), ENet (MIT) and Mbed TLS (Apache 2.0). Full list: https://godotengine.org/license

## Textures, models, sounds and music (all CC0 1.0, public domain)

- Textures: [Poly Haven](https://polyhaven.com) – thank you to the Poly Haven team and photographers.
- Item models: [Quaternius](https://quaternius.com) "Ultimate RPG Items" and
  [Kay Lousberg](https://www.kaylousberg.com) "KayKit Dungeon Remastered" and "KayKit Adventurers".
- Weapon sounds: several CC0 packs from [OpenGameArt](https://opengameart.org).
- Intro music: "Fantasy Choir 1" and "Fantasy Choir 2" by cesisco (Cesar da Rocha),
  "Epic Endgame Cinematic" by cynicmusic, both via OpenGameArt.

The complete list with every file and its source is in `lizenzen/Grafik-Quellen.txt` (German).
None of these creators require attribution; we credit them anyway.

## AI-generated monsters

**All monster images and 3D monster models were created with artificial intelligence**, from
our own text descriptions, locally on our own PC. They do not copy characters from other games
or films.

| Tool | Licence | Used for |
|---|---|---|
| Krea 2 Turbo (Krea.ai) | Krea 2 Community License | Most monster images |
| Z-Image Turbo (Tongyi-MAI) | Apache 2.0 | A few monster images |
| BiRefNet | MIT | Cutting out the images |
| TRELLIS.2 (Microsoft), Pixal3D | MIT | Turning the images into 3D models |

Under the Krea 2 Community License (section 5.3) the generated images belong to their creator;
Krea claims no ownership. No AI model weights are included in this project. Images and models
from tools whose terms do not allow redistribution (MiniMax, Qwen Image) were removed and are
not part of this project.

This project is free and non-commercial.
