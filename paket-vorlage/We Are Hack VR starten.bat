@echo off
rem Startet We Are Hack in VR. Vorher muss die VR-Software (OpenXR, z. B. SteamVR, Meta Quest Link oder KRVR) laufen.
cd /d "%~dp0"
start "" "godot\Godot_v4.7.2-stable_win64.exe" --xr-mode on --path rogue-godot res://start.tscn
