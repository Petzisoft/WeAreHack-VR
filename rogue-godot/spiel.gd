## Welches Spiel läuft? Ein Godot-Projekt für alle drei Spiele von "We Are Hack".
## Gewählt wird im Startmenü (start.tscn, setzen()) oder beim Start mit  -- --spiel=nethack  (ohne Angabe: Rogue).
## Hier stehen nur die Unterschiede: Programm, Fühler-Datei, Namen für Vorspann und Fenster,
## woran man Statuszeile und Ebene erkennt.
extends RefCounted

const ROGUE := "rogue"
const NETHACK := "nethack"
const HACK := "hack"

const DATEN := {
	ROGUE: {
		"name": "Rogue (1980)", "name_vr": "Rogue (1980) VR",
		# Autoren und Jahr laut Copyright in rogue-src/LICENSE.TXT
		"original": "Das Original von 1980", "autoren": "von Michael Toy, Ken Arnold und Glenn Wichman",
		"programm": "",   # leer = Standard der Brücke (build\rogue.exe)
		"fuehler": "wearehack_monster.txt",
		"status": "Level:", "ebene": "Level:\\s*(\\d+)",
		"musik": "res://modelle/ton/vorspann/musik",
	},
	HACK: {
		"name": "Hack (1982)", "name_vr": "Hack (1982) VR",
		# Copyright 1982 Jay Fenlason (hack-src/COPYRIGHT-JF), Hack 1.0 von Andries Brouwer (CWI, hack-src/COPYRIGHT)
		"original": "Das Original von 1982", "autoren": "von Jay Fenlason und Andries Brouwer",
		"programm": "../hack-spiel/hack.exe",
		"fuehler": "wearehack_hack.txt",
		"status": "Level ", "ebene": "Level\\s+(\\d+)",
		"musik": "res://modelle/ton/vorspann/hack/musik",
	},
	NETHACK: {
		"name": "NetHack (1987)", "name_vr": "NetHack (1987) VR",
		# Jahr laut nethack-src/dat/history (NetHack 1.4, 1987), Copyright laut dat/license
		"original": "Das Original von 1987", "autoren": "von Mike Stephenson und dem NetHack DevTeam",
		"programm": "../nethack-spiel/NetHack.exe",
		"fuehler": "wearehack_nethack.txt",
		"status": "Dlvl:", "ebene": "Dlvl:\\s*(\\d+)",
		"musik": "res://modelle/ton/vorspann/nethack/musik",
	},
}

static var _aktuell := ""


## Name des laufenden Spiels ("rogue" oder "nethack").
static func welches() -> String:
	if _aktuell == "":
		_aktuell = ROGUE
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--spiel="):
				var s := a.substr(8).to_lower()
				if DATEN.has(s):
					_aktuell = s
	return _aktuell


## Vom Startmenü: dieses Spiel läuft (vor dem Laden von dungeon.tscn aufrufen).
static func setzen(s: String) -> void:
	if DATEN.has(s):
		_aktuell = s


static func ist_nethack() -> bool:
	return welches() == NETHACK


static func ist_hack() -> bool:
	return welches() == HACK


## Spiele mit Sonde und NetHack-artiger Bedienung (Hack und NetHack): Gelände und Monster kommen aus der Sonde,
## Gegenstandsfragen enden auf "?*]", Textseiten schließt Esc.
static func mit_sonde() -> bool:
	return welches() == NETHACK or welches() == HACK


static func wert(schluessel: String) -> String:
	return DATEN[welches()][schluessel]


## Voller Pfad zum Spielprogramm oder "" (dann nimmt die Brücke build\rogue.exe).
static func programm_pfad() -> String:
	var p := wert("programm")
	if p == "":
		return ""
	return ProjectSettings.globalize_path("res://").path_join(p).simplify_path()
