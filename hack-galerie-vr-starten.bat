@echo off
rem Hack-Galerie in VR (erst KRVR starten)
cd /d "%~dp0"
start "" "godot\Godot_v4.7.2-stable_win64.exe" --xr-mode on --path rogue-godot res://werkzeuge/monster_galerie.tscn -- --spiel=hack
