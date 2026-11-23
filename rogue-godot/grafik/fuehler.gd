## Liest die Fühler-Datei, die Rogue vor jedem Befehl schreibt (%TEMP%\wearehack_monster.txt,
## siehe fuehler_schreiben in rogue-src/command.c). Am Spielablauf ändert der Fühler nichts.
## Zeilen: "gang x y tiefe", "klang nr art waffe ergebnis", "ausruestung waffe n ...",
## je Monster "x y Buchstabe lp max_lp flags tarnung" (und weitere, die noch nicht benutzt werden).
extends RefCounted

const ISRUN := 8192   # Monster-Flag 0020000 (oktal): wach und jagt dich

var pfad := OS.get_environment("TEMP").path_join(preload("res://spiel.gd").wert("fuehler"))   # Rogue: wearehack_monster.txt
var fest := false     # nur Testwerkzeuge: Datei nicht lesen, Werte werden von Hand gesetzt
var aktiv := false    # es wurden schon einmal Monsterwerte gelesen
var monster := {}     # Vector2i -> {c, hp, max, flags}
var _letzter_inhalt := ""


## Neues Spiel: die Datei des letzten Spiels löschen, sonst zeigt die Grafik kurz dessen Gänge und Monster.
func zuruecksetzen() -> void:
	if not fest and FileAccess.file_exists(pfad):
		DirAccess.remove_absolute(pfad)
	monster = {}
	aktiv = false
	_letzter_inhalt = ""


func _text() -> String:
	return FileAccess.get_file_as_string(pfad)


## Monsterwerte neu einlesen (nur wenn sich die Datei geändert hat).
func monster_lesen() -> void:
	if fest or not FileAccess.file_exists(pfad):
		return
	var inhalt := _text()
	if inhalt == _letzter_inhalt or inhalt == "":
		return
	_letzter_inhalt = inhalt
	var neu := {}
	for zeile in inhalt.split("\n", false):
		var t := zeile.strip_edges().split(" ", false)
		if t.size() >= 6 and t[0].is_valid_int():
			neu[Vector2i(t[0].to_int(), t[1].to_int())] = {"c": t[2], "hp": t[3].to_int(), "max": maxi(t[4].to_int(), 1), "flags": t[5].to_int()}
	monster = neu
	aktiv = true


## Gangfelder vor dem Spieler, die Rogue noch nicht zeigt: trägt ziel[feld] = tiefe ein.
func gaenge_lesen(ziel: Dictionary) -> void:
	if fest:
		return
	for z in _text().split("\n", false):
		if z.begins_with("gang "):
			var t := z.strip_edges().split(" ")
			if t.size() >= 4:
				ziel[Vector2i(int(t[1]), int(t[2]))] = int(t[3])


## Letztes Waffenereignis als [klang-Zeile oder "", Bogen in der Hand]. Leer, wenn die Datei leer ist.
func klang_lesen() -> Array:
	var inhalt := _text()
	if inhalt == "":
		return []
	var zeile := ""
	var bogen := false
	for z in inhalt.split("\n"):
		if z.begins_with("klang "):
			zeile = z
		elif z.begins_with("ausruestung waffe "):
			bogen = z.split(" ")[2] == "2"
	return [zeile, bogen]
