@echo off
rem Startet NetHack pur in der Konsole und daneben ein Fenster mit den Werten der Sonde
cd /d "%~dp0nethack-spiel"
set NETHACKOPTIONS=name:%USERNAME%,number_pad:0,!hitpointbar,time,showexp,autopickup,pickup_types:$
start "NetHack-Sonde" powershell -NoProfile -Command "$host.UI.RawUI.WindowTitle='NetHack-Sonde'; while($true){ Clear-Host; if(Test-Path $env:TEMP\wearehack_nethack.txt){ Get-Content $env:TEMP\wearehack_nethack.txt } else { 'Noch keine Sonde - erst im Spiel einen Zug machen.' }; Start-Sleep -Milliseconds 700 }"
start "NetHack" NetHack.exe
