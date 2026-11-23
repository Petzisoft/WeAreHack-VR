## Die 2D-Anzeigen über dem Dungeon: Meldungen oben, Werte unten, Karte oben rechts,
## Original-Textbild (Inventar, Menüs), Hilfe und der Kasten am Spielende.
## In VR wandert diese Ebene auf die Tafel vor den Augen (vr.gd).
extends CanvasLayer

const TextRaster = preload("res://text_raster.gd")

const MELDUNG_SEKUNDEN := 2.5   # so lange bleibt eine Rogue-Meldung stehen
const MELDUNGEN_MAX := 4

const Sprache = preload("res://sprache.gd")
const HILFE_TEXT := Sprache.HILFE_DE         # Englisch: Sprache.HILFE_EN (Godot übersetzt das Label)
const HILFE_CONTROLLER := Sprache.CONTROLLER_DE

var meldung_kasten: PanelContainer
var meldung_label: Label
var status_kasten: PanelContainer
var status_label: Label
var karte: TextRaster
var volltext: TextRaster
var hilfe_kasten: PanelContainer
var ende_kasten: PanelContainer
var ende_label: Label
var _meldungen: Array = []   # [Text, verbleibende Sekunden]
var letzte_meldung := ""


func _init() -> void:
	var stil := LabelSettings.new()
	stil.font = _schrift()
	stil.font_size = 20
	stil.font_color = Color(0.95, 0.93, 0.85)
	stil.outline_size = 4
	stil.outline_color = Color.BLACK

	meldung_kasten = _kasten()
	meldung_kasten.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	meldung_label = Label.new()
	meldung_label.label_settings = stil
	meldung_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	meldung_kasten.add_child(meldung_label)

	status_kasten = _kasten()
	status_kasten.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	status_kasten.grow_vertical = Control.GROW_DIRECTION_BEGIN
	status_label = Label.new()
	status_label.label_settings = stil
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_kasten.add_child(status_label)

	karte = TextRaster.new()
	karte.art = TextRaster.Art.KARTE
	karte.hintergrund = Color(0, 0, 0, 0.55)
	karte.anchor_left = 1.0
	karte.anchor_right = 1.0
	karte.offset_left = -496
	karte.offset_right = -16
	karte.offset_top = 56
	karte.offset_bottom = 56 + 23 * 6

	volltext = TextRaster.new()
	volltext.art = TextRaster.Art.TEXT
	volltext.hintergrund = Color(0.02, 0.02, 0.03, 0.92)
	volltext.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	volltext.visible = false

	hilfe_kasten = _kasten(Color(0, 0, 0, 0.85))
	var hilfe_stil := stil.duplicate() as LabelSettings
	hilfe_stil.font_size = 17
	var spalten_box := HBoxContainer.new()
	spalten_box.add_theme_constant_override("separation", 48)
	for t in [HILFE_TEXT, HILFE_CONTROLLER]:
		var hilfe := Label.new()
		hilfe.label_settings = hilfe_stil
		hilfe.text = t
		spalten_box.add_child(hilfe)
	hilfe_kasten.add_child(spalten_box)
	_mittig(hilfe_kasten)

	ende_kasten = _kasten(Color(0, 0, 0, 0.9))
	ende_label = Label.new()
	ende_label.label_settings = stil
	ende_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ende_kasten.add_child(ende_label)
	_mittig(ende_kasten)
	ende_kasten.visible = false

	for c in [meldung_kasten, status_kasten, karte, volltext, hilfe_kasten, ende_kasten]:
		add_child(c)


## Gleichbreite Schrift, wie Rogue sie in der Konsole hat.
static func _schrift() -> SystemFont:
	var schrift := SystemFont.new()
	schrift.font_names = PackedStringArray(["Consolas", "Cascadia Mono", "Courier New", "monospace"])
	return schrift


func _kasten(farbe := Color(0, 0, 0, 0.6)) -> PanelContainer:
	var k := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = farbe
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	k.add_theme_stylebox_override("panel", sb)
	k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return k


func _mittig(k: Control) -> void:
	k.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	k.grow_horizontal = Control.GROW_DIRECTION_BOTH
	k.grow_vertical = Control.GROW_DIRECTION_BOTH


func ende_zeigen(text: String) -> void:
	ende_label.text = text
	ende_kasten.visible = true


# ---------------------------------------------------------------- Meldungen

## Neue Meldungszeile von Rogue: bis zu vier Meldungen stehen untereinander.
func meldung_merken(m: String) -> void:
	var text := m.replace("--More--", "").strip_edges()
	if text != "" and text != letzte_meldung:
		_meldungen.append([text, MELDUNG_SEKUNDEN])
		if _meldungen.size() > MELDUNGEN_MAX:
			_meldungen.pop_front()
	letzte_meldung = text
	_meldungen_zeigen()


## Meldungen laufen ab; eine offene Frage von Rogue (frage = true) bleibt stehen.
func meldungen_altern(delta: float, frage: bool) -> void:
	var vorher := _meldungen.size()
	for e in _meldungen:
		if not (frage and e[0] == letzte_meldung):
			e[1] -= delta
	_meldungen = _meldungen.filter(func(e): return e[1] > 0.0)
	if _meldungen.size() != vorher:
		_meldungen_zeigen()


func _meldungen_zeigen() -> void:
	var zeilen := PackedStringArray()
	for e in _meldungen:
		zeilen.append(e[0])
	meldung_label.text = "\n".join(zeilen)
	meldung_kasten.visible = not zeilen.is_empty() and not volltext.visible
