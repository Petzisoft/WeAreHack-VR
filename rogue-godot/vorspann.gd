## Vorspann beim Spielstart: Spielname, darunter Originalspiel, Jahr und Autoren, dazu Musik in Schleife,
## bis der Spieler OK drückt (Taste, Mausklick, Controller A oder VR-Knopf). Dann blendet alles aus.
## Wiederverwendbar für Hack (1982) VR und NetHack (1987) VR: Datei kopieren, Musik als
## res://modelle/ton/vorspann/musik.ogg (oder .mp3) ablegen und z. B. so aufrufen:
##   Vorspann.zeigen(anzeigen, "Hack (1982) VR", "Das Original von 1982", "von Jay Fenlason ...")
## Solange der Vorspann steht, fragen steuerung.gd und vr.gd mit Vorspann.aktiv(self) nach
## und schicken Knöpfe hierher statt an das Spiel. Fehlt die Musik, bleibt es still.
extends ColorRect

const GRUPPE := "vorspann"
const MUSIK := "res://modelle/ton/vorspann/musik"   # ohne Endung, .ogg wird bevorzugt
const EINBLENDEN := 0.6
const AUSBLENDEN := 1.0
const SPERRE := 0.8        # so lange nach dem Start zählt kein Tastendruck (versehentliches Weiterklicken)

var _musik: AudioStreamPlayer
var _seit := 0.0
var _zu := false
var _musik_pfad := MUSIK   # je Spiel eigene Musik (spiel.gd)


## Baut den Vorspann in `eltern` (z. B. die Anzeigen-Ebene) und startet ihn.
static func zeigen(eltern: Node, titel: String, original: String, autoren: String, musik := MUSIK) -> Node:
	var v = load("res://vorspann.gd").new()
	v._musik_pfad = musik
	v._bauen(titel, original, autoren)
	eltern.add_child(v)
	v._starten()
	return v


## Der laufende Vorspann, oder null.
static func aktiv(knoten: Node) -> Node:
	return knoten.get_tree().get_first_node_in_group(GRUPPE)


func _bauen(titel: String, original: String, autoren: String) -> void:
	add_to_group(GRUPPE)
	color = Color(0, 0, 0, 1.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var spalte := VBoxContainer.new()
	spalte.alignment = BoxContainer.ALIGNMENT_CENTER
	spalte.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	spalte.add_theme_constant_override("separation", 18)
	spalte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(spalte)
	for z in [[titel, 64, Color(0.95, 0.8, 0.45)], [original, 28, Color(0.9, 0.88, 0.8)],
			[autoren, 24, Color(0.75, 0.73, 0.68)], ["", 24, Color.WHITE]]:
		spalte.add_child(_zeile(z[0], z[1], z[2]))
	var ok := Button.new()
	ok.text = "  OK  "
	ok.add_theme_font_size_override("font_size", 30)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for zustand in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.25, 0.18, 0.08) if zustand != "normal" else Color(0.12, 0.09, 0.05)
		sb.border_color = Color(0.95, 0.8, 0.45)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		sb.content_margin_left = 28
		sb.content_margin_right = 28
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		ok.add_theme_stylebox_override(zustand, sb)
	ok.add_theme_color_override("font_color", Color(0.95, 0.8, 0.45))
	ok.pressed.connect(schliessen)
	spalte.add_child(ok)
	spalte.add_child(_zeile("Taste, Mausklick oder A drücken", 18, Color(0.6, 0.58, 0.54)))
	_musik = AudioStreamPlayer.new()
	_musik.stream = _musik_laden()
	add_child(_musik)


func _zeile(text: String, groesse: int, farbe: Color) -> Label:
	var l := Label.new()
	var stil := LabelSettings.new()
	var schrift := SystemFont.new()
	schrift.font_names = PackedStringArray(["Consolas", "Cascadia Mono", "Courier New", "monospace"])
	stil.font = schrift
	stil.font_size = groesse
	stil.font_color = farbe
	stil.outline_size = 4
	stil.outline_color = Color.BLACK
	l.label_settings = stil
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _musik_laden() -> AudioStream:
	var ogg := ProjectSettings.globalize_path(_musik_pfad + ".ogg")
	if FileAccess.file_exists(ogg):
		var st := AudioStreamOggVorbis.load_from_file(ogg)
		st.loop = true
		return st
	var mp3 := ProjectSettings.globalize_path(_musik_pfad + ".mp3")
	if FileAccess.file_exists(mp3):
		var st := AudioStreamMP3.new()
		st.data = FileAccess.get_file_as_bytes(mp3)
		st.loop = true
		return st
	return null


func _starten() -> void:
	var text: Control = get_child(0)
	text.modulate.a = 0.0
	create_tween().tween_property(text, "modulate:a", 1.0, EINBLENDEN)
	if _musik.stream:
		_musik.play()


func _process(delta: float) -> void:
	_seit += delta


## Jede Taste, jeder Mausklick und jeder Controller-Knopf schließt den Vorspann (und geht nicht ans Spiel).
func _input(event: InputEvent) -> void:
	var gedrueckt := (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) \
			and event.is_pressed() and not event.is_echo()
	if gedrueckt:
		get_viewport().set_input_as_handled()
		schliessen()


## OK: Musik und Bild blenden aus, danach verschwindet der Vorspann.
func schliessen() -> void:
	if _zu or _seit < SPERRE:
		return
	_zu = true
	remove_from_group(GRUPPE)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, AUSBLENDEN)
	if _musik.playing:
		tw.tween_property(_musik, "volume_db", -40.0, AUSBLENDEN)
	tw.chain().tween_callback(queue_free)
