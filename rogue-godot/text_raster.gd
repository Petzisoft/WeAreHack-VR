## Zeichnet Rogues Zeichenraster: als Text (Vollbild, z. B. für Inventar und Menüs)
## oder als kleine Karte aus farbigen Kästchen (Übersicht oben rechts).
extends Control

enum Art { TEXT, KARTE }

var art := Art.TEXT
var raster: PackedStringArray = []
var spalten := 80
## Erste und letzte Zeile, die gezeichnet wird (-1 = bis zum Ende).
var von := 0
var bis := -1
## Spielerfeld und Blickwinkel (Bogenmaß, 0 = Nord, -PI/2 = Ost) für den Kartenpfeil.
var spieler := Vector2i(-1, -1)
var blick := 0.0
var hintergrund := Color(0, 0, 0, 0.85)
var schrift := SystemFont.new()
const TEXT_HOECHSTENS := 1.6   # kleine Textseiten höchstens so viel größer als die volle 80-Spalten-Seite


func _ready() -> void:
	schrift.font_names = PackedStringArray(["Consolas", "Cascadia Mono", "Courier New", "monospace"])
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func zeigen(r: PackedStringArray, sp: int, z_von: int, z_bis: int, feld: Vector2i, bl: float) -> void:
	raster = r
	spalten = sp
	von = z_von
	bis = z_bis
	spieler = feld
	blick = bl
	queue_redraw()


func _draw() -> void:
	if raster.is_empty():
		return
	var b := bis if bis >= 0 else raster.size() - 1
	b = mini(b, raster.size() - 1)
	var n := b - von + 1
	if n <= 0:
		return
	if art == Art.KARTE:
		_karte(n)
	else:
		_text(n)


## Textseite: der beschriebene Teil (z. B. das Inventar oben links) wird in die Bildmitte gerückt
## und bei kleinen Seiten etwas größer gezeichnet (Peter 21.11.: stand zu weit außen, in VR schlecht lesbar).
func _text(n: int) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), hintergrund)
	# Bereich mit Inhalt suchen
	var x0 := spalten
	var x1 := -1
	var y0 := n
	var y1 := -1
	var weiter := -1   # Zeile mit "--Press space to continue--": kommt direkt unter den Inhalt
	for i in n:
		var zeile := raster[von + i]
		if "Press space" in zeile:
			weiter = i
			continue
		var links := zeile.length() - zeile.strip_edges(true, false).length()
		var rechts := zeile.strip_edges(false, true).length() - 1
		if rechts >= links and rechts >= 0:
			x0 = mini(x0, links)
			x1 = maxi(x1, rechts)
			y0 = mini(y0, i)
			y1 = maxi(y1, i)
	if x1 < 0:
		return
	var breite := x1 - x0 + 1
	var hoehe := y1 - y0 + 1 + (2 if weiter >= 0 else 0)
	var probe := 32
	var bw := schrift.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, probe).x
	var bh := schrift.get_height(probe)
	var gr_voll := probe * minf(size.x / (spalten * bw), size.y / (n * bh))
	var gr_block := probe * minf(size.x * 0.8 / (breite * bw), size.y * 0.8 / (hoehe * bh))
	var gr := maxi(6, int(minf(gr_block, gr_voll * TEXT_HOECHSTENS)))
	var zelle := Vector2(schrift.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, gr).x, schrift.get_height(gr))
	var start := ((size - zelle * Vector2(breite, hoehe)) / 2.0).floor() - zelle * Vector2(x0, y0)
	var oben := schrift.get_ascent(gr)
	for i in n:
		var zeile := raster[von + i]
		var reihe := (y1 + 2) if i == weiter else i
		for s in zeile.length():
			var z := zeile[s]
			if z != " ":
				draw_string(schrift, start + Vector2(s * zelle.x, reihe * zelle.y + oben), z,
						HORIZONTAL_ALIGNMENT_LEFT, -1, gr, Color(0.88, 0.88, 0.85))


func _karte(n: int) -> void:
	var k := floorf(minf(size.x / spalten, size.y / n))
	if k < 1.0:
		return
	var start := Vector2(size.x - k * spalten, 0)
	draw_rect(Rect2(start, Vector2(k * spalten, k * n)), hintergrund)
	for i in n:
		var zeile := raster[von + i]
		for s in zeile.length():
			var farbe := _farbe(zeile[s])
			if farbe.a > 0.0:
				draw_rect(Rect2(start + Vector2(s, i) * k, Vector2(k, k)), farbe)
	# Pfeil für Spieler und Blickrichtung
	if spieler.y >= von and spieler.y < von + n:
		var mitte := start + (Vector2(spieler.x, spieler.y - von) + Vector2(0.5, 0.5)) * k
		var r := Vector2(-sin(blick), -cos(blick))
		var q := Vector2(-r.y, r.x)
		var punkte := PackedVector2Array([mitte + r * k * 2.6, mitte - r * k + q * k * 0.9, mitte - r * k - q * k * 0.9])
		draw_colored_polygon(punkte, Color(1, 0.9, 0.2))


func _farbe(c: String) -> Color:
	match c:
		" ": return Color(0, 0, 0, 0)
		"-", "|": return Color(0.6, 0.55, 0.5)
		".": return Color(0.28, 0.25, 0.22)
		"#": return Color(0.45, 0.33, 0.2)
		"+": return Color(0.85, 0.55, 0.2)
		"%": return Color(0.3, 0.9, 0.4)
		"@": return Color(1, 0.9, 0.2)
	var code := c.unicode_at(0)
	if code >= 65 and code <= 90:
		return Color(0.95, 0.25, 0.2)  # Monster
	return Color(0.3, 0.8, 0.95)  # Gegenstand
