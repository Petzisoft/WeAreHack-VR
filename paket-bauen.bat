@echo off
rem Baut den Ordner paket\WeAreHack und die Datei paket\WeAreHack.zip zum Weitergeben
rem ("We Are Hack": Startmenue mit Rogue (1980) und NetHack (1987), Hack (1982) kommt spaeter).
rem Einfach doppelklicken, wenn sich am Spiel etwas geaendert hat. Danach das Setup:
rem   C:\msys64\ucrt64\bin\makensis.exe setup.nsi
cd /d "%~dp0"
set Z=paket\WeAreHack
if exist paket rmdir /s /q paket
mkdir "%Z%\godot" "%Z%\bruecke" "%Z%\build" "%Z%\rogue-godot" "%Z%\lizenzen" "%Z%\nethack-spiel" "%Z%\nethack-monster\3d" "%Z%\hack-monster\3d"
copy /y godot\Godot_v4.7.2-stable_win64.exe "%Z%\godot\" >nul
copy /y bruecke\rogue-bruecke.exe "%Z%\bruecke\" >nul
copy /y build\rogue.exe "%Z%\build\" >nul
copy /y rogue-godot\project.godot "%Z%\rogue-godot\" >nul
copy /y rogue-godot\*.gd "%Z%\rogue-godot\" >nul
copy /y rogue-godot\*.uid "%Z%\rogue-godot\" >nul
copy /y rogue-godot\*.tscn "%Z%\rogue-godot\" >nul
xcopy /e /i /q /y rogue-godot\grafik "%Z%\rogue-godot\grafik" >nul
rem Texturen (Poly Haven, CC0), Gegenstaende, Monster und Waffentoene
if exist rogue-godot\texturen xcopy /e /i /q /y rogue-godot\texturen "%Z%\rogue-godot\texturen" >nul
rem Hoehenbilder (_disp) und den Tuersatz rough_pine_door benutzt das Spiel nicht
del /q "%Z%\rogue-godot\texturen\*_disp.jpg" "%Z%\rogue-godot\texturen\rough_pine_door_*" 2>nul
if exist rogue-godot\modelle xcopy /e /i /q /y rogue-godot\modelle "%Z%\rogue-godot\modelle" >nul
copy /y rogue-godot\*.tres "%Z%\rogue-godot\" >nul 2>nul
rem Nicht weitergebbar (Qwen Image 2.1 nur Forschung): die Qwen-Posen des Aquators bleiben nur auf diesem PC.
rem Die Monster sind im Spiel 3D-Modelle; die Standbilder sind nur Ersatz, falls ein Modell fehlt.
del /q "%Z%\rogue-godot\modelle\monster\A_angriff*.png" "%Z%\rogue-godot\modelle\monster\A_ruhe*.png" 2>nul
rem NetHack (1987): Programm und Spieldaten, leere Bestenliste (nicht die von diesem PC)
for %%f in (NetHack.exe nhdat367 license Guidebook.txt opthelp symbols sysconf symbols.template sysconf.template .nethackrc.template) do copy /y "nethack-spiel\%%f" "%Z%\nethack-spiel\" >nul
type nul > "%Z%\nethack-spiel\record"
type nul > "%Z%\nethack-spiel\logfile"
type nul > "%Z%\nethack-spiel\xlogfile"
rem 3D-Monster fuer NetHack und Hack: nur die aktiven Modelle (keine alt_-Ordner, keine Rohbilder)
copy /y nethack-monster\3d\*.glb "%Z%\nethack-monster\3d\" >nul
copy /y nethack-monster\monster_namen.txt "%Z%\nethack-monster\" >nul
copy /y hack-monster\3d\*.glb "%Z%\hack-monster\3d\" >nul
rem Texturen in den KI-Modellen als JPEG statt PNG (nur im Paket), sonst wird das Setup groesser als 2 GB
python werkzeuge\glb_verkleinern.py "%Z%\nethack-monster\3d" "%Z%\hack-monster\3d"
if errorlevel 1 echo FEHLER: glb_verkleinern.py (Python mit Pillow noetig) & pause & exit /b 1
copy /y lizenzen\*.txt "%Z%\lizenzen\" >nul
rem NetHack-Lizenz.txt liegt in lizenzen\ (oben mitkopiert); englische Uebersicht THIRD_PARTY_NOTICES.md kommt aus paket-vorlage\
rem Quelltext zum Weitergeben (NetHack-Lizenz verlangt ihn): NetHack 3.6.7 und Rogue 5.4.4 mit unseren Aenderungen,
rem genau der committete Stand (git archive, keine Bau-Ausgaben), dazu die Aenderungen einzeln als Patch
mkdir "%Z%\quelltext\nethack" "%Z%\quelltext\rogue" "%Z%\quelltext\patches"
git -C nethack-src archive --format=tar HEAD | tar -x -C "%Z%\quelltext\nethack"
if errorlevel 1 echo FEHLER: NetHack-Quelltext & pause & exit /b 1
git -C rogue-src archive --format=tar HEAD | tar -x -C "%Z%\quelltext\rogue"
if errorlevel 1 echo FEHLER: Rogue-Quelltext & pause & exit /b 1
xcopy /e /i /q /y patches\nethack "%Z%\quelltext\patches\nethack" >nul
xcopy /e /i /q /y patches\rogue "%Z%\quelltext\patches\rogue" >nul
copy /y "paket-vorlage\*" "%Z%\" >nul
echo Packe ZIP-Datei, bitte warten ...
powershell -NoProfile -Command "Compress-Archive -Path 'paket\WeAreHack' -DestinationPath 'paket\WeAreHack.zip' -Force"
echo.
echo Fertig: paket\WeAreHack.zip
if not "%1"=="ohnepause" pause
