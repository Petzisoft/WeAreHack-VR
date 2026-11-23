@echo off
rem Startet Rogue als 3D-Dungeon in Ego-Perspektive (Schritt 3)
cd /d "%~dp0"
start "" "godot\Godot_v4.7.2-stable_win64.exe" --path rogue-godot res://dungeon.tscn
