## NetHack (1987) VR: macht aus NetHacks Bildschirm und der NetHack-Sonde
## (%TEMP%\wearehack_nethack.txt, nethack-src/src/wah_sonde.c) ein Zeichenraster in Rogue-Zeichen,
## damit dungeon_3d.gd den Dungeon genauso bauen kann wie bei Rogue.
##   Gelände kommt aus der Sonde (eindeutig, z. B. Tür oder Wand), Gegenstände und Monster vom Bildschirm.
##   Monster werden zu "M" und ihr echter Name steht in `monster_namen` (für das Namensschild).
## NetHack selbst bleibt unverändert, die Sonde liest nur.
extends RefCounted

# Gelände der Sonde -> Rogue-Gelände (siehe Kopf von wah_sonde.c)
const GELAENDE := {
	"-": "-", "+": "+", "o": "+", "D": "+", ".": ".", "#": "#", ">": "%", "^": "^",
	"<": ".", "B": "-", "T": "-", "_": ".", "G": ".", "\\": ".", "S": ".", "{": ".",
	"}": "w", "I": "i", "L": "l", "=": ".",
}
# NetHack-Gegenstandsklasse -> Rogue-Zeichen (gleiche Figur wie bei Rogue, wo es passt)
const DINGE := {
	")": ")", "[": "]", "=": "=", "\"": ",", "!": "!", "?": "?", "+": "?", "/": "/",
	"$": "*", "%": ":", "(": "(", "*": "o", "`": "`", "0": "0", "_": "_",
}
# Besonderes Gelände bekommt ein Namensschild (dungeon_3d.gd stellt dafür eine Figur auf)
const BESONDERS := {
	"<": "Treppe ▲", "{": "Brunnen", "_": "Altar", "\\": "Thron", "G": "Grab", "S": "Spüle",
	"T": "Baum", "B": "Gitter", "D": "Tür (zu)",
}

var pfad := OS.get_environment("TEMP").path_join("wearehack_nethack.txt")
var monster_namen := {}   # Vector2i -> Name (englisch, aus NetHack)
var besonders := {}       # Vector2i -> Text für Namensschild (Brunnen, Altar ...)
var spieler := Vector2i(-1, -1)
var ebene := -1
var zweig := 0          # Zweig laut Sonde (0 Hauptdungeon, 1 Gehennom, 2 Minen, 4 Sokoban ...)
var gueltig := false      # gibt es eine Sonde, die zum Bild passt?


## Neues Spiel: alte Sonde löschen.
func zuruecksetzen() -> void:
	if FileAccess.file_exists(pfad):
		DirAccess.remove_absolute(pfad)
	gueltig = false


## Übersetzt das Bildschirmraster. Kartenzeilen 1 .. bis_zeile-1 werden ersetzt.
func uebersetzen(r: PackedStringArray, bis_zeile: int) -> PackedStringArray:
	gueltig = false
	monster_namen.clear()
	besonders.clear()
	if not FileAccess.file_exists(pfad):
		return r
	var karte := {}
	var dinge := {}
	var sichtbare := {}
	var getarnte := {}
	for z in FileAccess.get_file_as_string(pfad).split("\n", false):
		var t := z.split(" ", false)
		if t.is_empty():
			continue
		if t[0] == "karte" and t.size() >= 2:
			karte[int(t[1])] = z.substr(7 + t[1].length())
		elif t[0] == "spieler" and t.size() >= 3:
			spieler = Vector2i(int(t[1]), int(t[2]))
		elif t[0] == "ebene" and t.size() >= 2:
			ebene = int(t[1])
			if t.size() >= 4 and t[2] == "zweig":
				zweig = int(t[3])
		elif t[0] == "ding" and t.size() >= 5:
			dinge[Vector2i(int(t[1]), int(t[2]))] = t[3]
		elif t[0].is_valid_int() and t.size() >= 12 and t[10] == "1":
			# Feld 7 = M_AP_TYPE: 1 getarnt als Tür/Gelände, 2 als Gegenstand (Mimic). Getarnte Monster
			# bleiben unsichtbar: man sieht nur, was NetHack zeigt (z. B. eine normale Tür), bis man sie anfasst.
			if t[6] == "1" or t[6] == "2":
				getarnte[Vector2i(int(t[0]), int(t[1]))] = t[6]
			else:
				sichtbare[Vector2i(int(t[0]), int(t[1]))] = t[11].replace("_", " ")
	if karte.is_empty() or spieler.x < 0:
		return r
	var neu := r.duplicate()
	for y in range(1, mini(bis_zeile, r.size())):
		var schirm: String = r[y]
		var gel: String = karte.get(y, "")
		var zeile := ""
		for x in schirm.length():
			var p := Vector2i(x, y)
			var s := schirm[x]
			var g := gel[x] if x < gel.length() else " "
			var aus: String = GELAENDE.get(g, " ")
			if BESONDERS.has(g):
				besonders[p] = BESONDERS[g]
			if p == spieler:
				aus = "@"
			elif sichtbare.has(p) and s != " " and s != g:
				aus = "M"
				monster_namen[p] = sichtbare[p]
			elif getarnte.get(p, "") == "2" and DINGE.has(s):
				aus = DINGE[s]   # Mimic als Gegenstand: zeigt den Gegenstand, den NetHack anzeigt
			elif dinge.has(p) and s == dinge[p]:
				aus = DINGE.get(s, s)
			elif aus == " " and s in ".#":
				aus = s   # gesehen, aber noch nicht in der Sonde (kommt beim nächsten Zug)
			zeile += aus
		neu[y] = zeile
	gueltig = true
	return neu
