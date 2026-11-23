## Einfache Auswahlliste für den Controller: Steuerkreuz/Stick hoch-runter, A nimmt, B bricht ab.
## Wird für das Befehlsmenü, die Gegenstandsauswahl und Ja/Nein-Fragen benutzt.
extends PanelContainer

const SICHTBAR := 12

var eintraege: Array = []   # Liste aus [Anzeigetext, Wert]
var index := 0
var _oben := 0
var _titel: Label
var _zeilen: Array[Label] = []
var _stil_normal: LabelSettings
var _stil_aktiv: LabelSettings


func _ready() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.03, 0.05, 0.94)
	sb.border_color = Color(0.85, 0.7, 0.3)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	add_theme_stylebox_override("panel", sb)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH

	var schrift := SystemFont.new()
	schrift.font_names = PackedStringArray(["Consolas", "Cascadia Mono", "Courier New", "monospace"])
	_stil_normal = LabelSettings.new()
	_stil_normal.font = schrift
	_stil_normal.font_size = 22
	_stil_normal.font_color = Color(0.85, 0.85, 0.8)
	_stil_aktiv = _stil_normal.duplicate()
	_stil_aktiv.font_color = Color(1.0, 0.85, 0.3)
	var titel_stil := _stil_normal.duplicate() as LabelSettings
	titel_stil.font_color = Color(0.6, 0.8, 1.0)

	var spalte := VBoxContainer.new()
	add_child(spalte)
	_titel = Label.new()
	_titel.label_settings = titel_stil
	spalte.add_child(_titel)
	spalte.add_child(HSeparator.new())
	for i in SICHTBAR:
		var l := Label.new()
		l.label_settings = _stil_normal
		spalte.add_child(l)
		_zeilen.append(l)
	var fuss := Label.new()
	var fuss_stil := _stil_normal.duplicate() as LabelSettings
	fuss_stil.font_size = 16
	fuss_stil.font_color = Color(0.6, 0.6, 0.6)
	fuss.label_settings = fuss_stil
	fuss.text = "Klick, Enter, Buchstabe oder A = auswählen     Esc oder B = abbrechen"
	spalte.add_child(HSeparator.new())
	spalte.add_child(fuss)
	visible = false


func zeigen(titel: String, liste: Array) -> void:
	eintraege = liste
	index = 0
	_oben = 0
	_titel.text = titel
	visible = true
	_neu_zeichnen()


func bewegen(n: int) -> void:
	if eintraege.is_empty():
		return
	index = posmod(index + n, eintraege.size())
	_neu_zeichnen()


## Eintrag i hervorheben (z. B. vom VR-Laserstrahl getroffen).
func markieren(i: int) -> void:
	if i >= 0 and i < eintraege.size():
		index = i
		_neu_zeichnen()


## Index des Eintrags mit diesem Wert (z. B. Buchstabe "c"), oder -1.
func index_von(w: Variant) -> int:
	for i in eintraege.size():
		if str(eintraege[i][1]) == str(w):
			return i
	return -1


## Index des Eintrags unter dem Mauszeiger (Bildschirmkoordinaten), oder -1.
func eintrag_bei(pos: Vector2) -> int:
	for i in SICHTBAR:
		var l := _zeilen[i]
		if l.visible and l.get_global_rect().has_point(pos):
			return _oben + i
	return -1


func wert() -> Variant:
	return eintraege[index][1] if index < eintraege.size() else null


func _neu_zeichnen() -> void:
	if index < _oben:
		_oben = index
	elif index >= _oben + SICHTBAR:
		_oben = index - SICHTBAR + 1
	for i in SICHTBAR:
		var j := _oben + i
		var l := _zeilen[i]
		l.visible = j < eintraege.size()
		if l.visible:
			var pfeil := "▲ " if (i == 0 and _oben > 0) else ("▼ " if (i == SICHTBAR - 1 and j < eintraege.size() - 1) else "  ")
			l.text = ("▶ " if j == index else "  ") + str(eintraege[j][0]) + "  " + pfeil.strip_edges()
			l.label_settings = _stil_aktiv if j == index else _stil_normal
	# Größe an den Inhalt anpassen und mittig halten
	reset_size()
