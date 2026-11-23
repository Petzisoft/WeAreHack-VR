## Schritt 2: zeigt Rogues 80x25-Zeichenraster als 2D-Text und reicht Tasten weiter.
extends Control

const HINTERGRUND := Color(0.02, 0.02, 0.03)
const TEXTFARBE := Color(0.85, 0.85, 0.85)
const CURSORFARBE := Color(1.0, 0.85, 0.2)

const RogueVerbindung = preload("res://rogue_verbindung.gd")

var rogue := RogueVerbindung.new()
var schrift := SystemFont.new()
var schriftgroesse := 16
var zelle := Vector2(10, 20)
var ende_meldung := ""
var _blink := 0.0


func _ready() -> void:
	schrift.font_names = PackedStringArray(["Consolas", "Cascadia Mono", "Courier New", "monospace"])
	focus_mode = Control.FOCUS_ALL
	grab_focus()
	resized.connect(_groesse_anpassen)
	rogue.bild_geaendert.connect(queue_redraw)
	rogue.beendet.connect(_rogue_beendet)
	_groesse_anpassen()
	_rogue_starten()
	if "--selbsttest" in OS.get_cmdline_user_args():
		_selbsttest()


# Nur für die Entwicklung: Taste senden, Bildschirmfoto speichern, beenden.
func _selbsttest() -> void:
	await get_tree().create_timer(3.0).timeout
	rogue.taste(ord("l"))
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../selbsttest.png"))
	print("SELBSTTEST raster=", rogue.raster.size(), " cursor=", rogue.cursor)
	for z in rogue.raster:
		if z.strip_edges() != "":
			print(z)
	get_tree().quit()


func _rogue_starten() -> void:
	ende_meldung = ""
	# Die Brücke liegt im Projektordner "We Are Hack\bruecke"
	var pfad := ProjectSettings.globalize_path("res://").path_join("../bruecke/rogue-bruecke.exe").simplify_path()
	rogue.starten(pfad)
	queue_redraw()


func _rogue_beendet(meldung: String) -> void:
	ende_meldung = meldung
	queue_redraw()


func _exit_tree() -> void:
	rogue.stoppen()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		rogue.stoppen()


# Schrift so groß wählen, dass 80x25 Zeichen ins Fenster passen.
func _groesse_anpassen() -> void:
	var probe := 32
	var b := schrift.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, probe).x
	var h := schrift.get_height(probe)
	var faktor := minf(size.x / (rogue.spalten * b), size.y / (rogue.zeilen * h))
	schriftgroesse = maxi(6, int(probe * faktor))
	zelle = Vector2(schrift.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, schriftgroesse).x,
			schrift.get_height(schriftgroesse))
	queue_redraw()


func _process(delta: float) -> void:
	_blink += delta
	if _blink > 0.5:
		_blink = 0.0
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), HINTERGRUND)
	var start := ((size - zelle * Vector2(rogue.spalten, rogue.zeilen)) / 2.0).floor()
	var oben := schrift.get_ascent(schriftgroesse)
	for i in rogue.raster.size():
		var zeile := rogue.raster[i]
		# Zeichen einzeln setzen, damit das Raster exakt bleibt
		for s in zeile.length():
			var z := zeile[s]
			if z != " ":
				draw_string(schrift, start + Vector2(s * zelle.x, i * zelle.y + oben), z,
						HORIZONTAL_ALIGNMENT_LEFT, -1, schriftgroesse, TEXTFARBE)
	# Blinkender Cursor (Strich unter dem Zeichen)
	if rogue.laeuft and fmod(Time.get_ticks_msec() / 1000.0, 1.0) < 0.6:
		var c := start + Vector2(rogue.cursor) * zelle
		draw_rect(Rect2(c + Vector2(0, zelle.y - 3), Vector2(zelle.x, 2)), CURSORFARBE)
	if ende_meldung != "":
		var text := ende_meldung + tr("\n\nEnter = neues Spiel     Esc = Programm beenden")
		var box := Rect2(size * Vector2(0.15, 0.35), size * Vector2(0.7, 0.3))
		draw_rect(box, Color(0, 0, 0, 0.85))
		draw_rect(box, CURSORFARBE, false, 2.0)
		draw_multiline_string(schrift, box.position + Vector2(20, 20 + oben), text,
				HORIZONTAL_ALIGNMENT_CENTER, box.size.x - 40, schriftgroesse, -1, CURSORFARBE)


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	accept_event()
	var k := event as InputEventKey

	if ende_meldung != "":
		if k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
			_rogue_starten()
		elif k.keycode == KEY_ESCAPE:
			get_tree().quit()
		return

	var code := 0
	match k.keycode:
		KEY_ESCAPE: code = 27
		KEY_ENTER, KEY_KP_ENTER: code = 13
		KEY_BACKSPACE: code = 8
		KEY_TAB: code = 9
		# Pfeiltasten -> Rogue-Bewegung (mit Umschalt: laufen)
		KEY_LEFT: code = ord("H" if k.shift_pressed else "h")
		KEY_RIGHT: code = ord("L" if k.shift_pressed else "l")
		KEY_UP: code = ord("K" if k.shift_pressed else "k")
		KEY_DOWN: code = ord("J" if k.shift_pressed else "j")
		KEY_HOME: code = ord("Y" if k.shift_pressed else "y")
		KEY_PAGEUP: code = ord("U" if k.shift_pressed else "u")
		KEY_END: code = ord("B" if k.shift_pressed else "b")
		KEY_PAGEDOWN: code = ord("N" if k.shift_pressed else "n")
	if code == 0 and k.ctrl_pressed and k.keycode >= KEY_A and k.keycode <= KEY_Z:
		code = k.keycode - KEY_A + 1  # Strg+A..Z
	if code == 0 and k.unicode > 0 and k.unicode < 128:
		code = k.unicode
	if code != 0:
		rogue.taste(code)
