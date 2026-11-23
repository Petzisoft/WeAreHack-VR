; Setup fuer "We Are Hack" (Startmenue: Rogue (1980), Hack (1982), NetHack (1987)).
; Bauen: erst paket-bauen.bat, dann C:\msys64\ucrt64\bin\makensis.exe setup.nsi
; Entfernt beim Installieren die fruehere Installation "Rogue (1980) VR" (Ordner Rogue1980VR).
; Spielstaende (Speicherplaetze) liegen im Benutzerordner von Godot und bleiben erhalten.
Unicode true
SetCompressor /SOLID lzma
Name "We Are Hack"
OutFile "paket\WeAreHack-Setup.exe"
InstallDir "$LOCALAPPDATA\Programs\WeAreHack"
RequestExecutionLevel user
!include "MUI2.nsh"
!define GODOT "$INSTDIR\godot\Godot_v4.7.2-stable_win64.exe"
!define MONITOR "--path rogue-godot res://start.tscn"
!define VR "--xr-mode on --path rogue-godot res://start.tscn"
!define UNINST "Software\Microsoft\Windows\CurrentVersion\Uninstall\WeAreHack"
!define ALT_UNINST "Software\Microsoft\Windows\CurrentVersion\Uninstall\Rogue1980VR"
!define ALT_DIR "$LOCALAPPDATA\Programs\Rogue1980VR"
!define MUI_FINISHPAGE_RUN "${GODOT}"
!define MUI_FINISHPAGE_RUN_PARAMETERS "${MONITOR}"
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\LIESMICH.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "German"
Section
  ; fruehere Installation "Rogue (1980) VR" entfernen (Verknuepfungen, Apps-Eintrag, Ordner)
  Delete "$DESKTOP\Rogue (1980).lnk"
  Delete "$DESKTOP\Rogue (1980) VR.lnk"
  RMDir /r "$SMPROGRAMS\Rogue (1980) VR"
  DeleteRegKey HKCU "${ALT_UNINST}"
  RMDir /r "${ALT_DIR}"
  SetOutPath "$INSTDIR"
  File /r "paket\WeAreHack\*.*"
  CreateDirectory "$INSTDIR\hack-spiel\save"
  SetOutPath "$INSTDIR"
  CreateShortcut "$DESKTOP\We Are Hack.lnk" "${GODOT}" "${MONITOR}"
  CreateShortcut "$DESKTOP\We Are Hack VR.lnk" "${GODOT}" "${VR}"
  CreateDirectory "$SMPROGRAMS\We Are Hack"
  CreateShortcut "$SMPROGRAMS\We Are Hack\We Are Hack.lnk" "${GODOT}" "${MONITOR}"
  CreateShortcut "$SMPROGRAMS\We Are Hack\We Are Hack VR.lnk" "${GODOT}" "${VR}"
  CreateShortcut "$SMPROGRAMS\We Are Hack\Deinstallieren.lnk" "$INSTDIR\uninstall.exe"
  WriteUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "${UNINST}" "DisplayName" "We Are Hack"
  WriteRegStr HKCU "${UNINST}" "DisplayIcon" "${GODOT}"
  WriteRegStr HKCU "${UNINST}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
SectionEnd
Section "Uninstall"
  Delete "$DESKTOP\We Are Hack.lnk"
  Delete "$DESKTOP\We Are Hack VR.lnk"
  RMDir /r "$SMPROGRAMS\We Are Hack"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKCU "${UNINST}"
SectionEnd
