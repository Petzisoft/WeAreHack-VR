@echo off
rem NetHack-Galerie: alle NetHack-Monster in zwei Reihen (Monitor)
cd /d "%~dp0"
start "" "godot\Godot_v4.7.2-stable_win64.exe" --path rogue-godot res://werkzeuge/monster_galerie.tscn -- --spiel=nethack
