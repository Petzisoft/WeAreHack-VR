@echo off
rem Startet We Are Hack am Bildschirm (Startmenue: Rogue, Hack, NetHack)
cd /d "%~dp0"
start "" "godot\Godot_v4.7.2-stable_win64.exe" --path rogue-godot res://start.tscn
