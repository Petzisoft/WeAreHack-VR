@echo off
rem Monster-Galerie: alle 26 Rogue-Monster in einer Reihe (Monitor)
cd /d "%~dp0"
start "" "godot\Godot_v4.7.2-stable_win64.exe" --path rogue-godot res://werkzeuge/monster_galerie.tscn
