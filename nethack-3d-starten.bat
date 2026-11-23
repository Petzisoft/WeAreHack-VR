@echo off
rem Startet NetHack (1987) als 3D-Dungeon am Monitor (gleiches Godot-Projekt wie Rogue)
cd /d "%~dp0"
start "" "godot\Godot_v4.7.2-stable_win64.exe" --path rogue-godot res://dungeon.tscn -- --spiel=nethack
