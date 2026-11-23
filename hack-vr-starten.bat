@echo off
rem Startet Hack (1982) VR (OpenXR-Laufzeit wie KRVR muss laufen)
cd /d "%~dp0"
start "" "godot\Godot_v4.7.2-stable_win64.exe" --xr-mode on --path rogue-godot res://dungeon.tscn -- --spiel=hack
