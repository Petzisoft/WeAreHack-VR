## Startmenü von "We Are Hack" (Peter 23.11.: ein Spiel mit allen dreien): Rogue (1980), Hack (1982), NetHack (1987).
## Hack ist noch nicht portiert und deshalb ausgegraut ("kommt bald"). Danach startet dungeon.tscn mit dem gewählten
## Spiel, der Vorspann des Spiels kommt wie bisher.
## Bedienung: Maus (zeigen, klicken), Tastatur (hoch/runter oder W/S, Enter/Leertaste, 1-3, Esc beendet),
## Gamepad (Steuerkreuz/Stick, A) und in VR (--xr-mode on) die Controller: Stick hoch/runter, A oder Abzug.
## In VR schwebt das Menü wie die Spieltafel 1,2 m vor den Augen.
## Sprache: Eintrag "Language / Sprache" schaltet Englisch (Standard) / Deutsch um, gespeichert in sprache.gd.
## Test: -- --menuetest (werkzeuge/startmenue_test.gd).
extends Node3D

const Spiel = preload("res://spiel.gd")
const Sprache = preload("res://sprache.gd")
const GOLD := Color(0.95, 0.8, 0.45)
const TAFEL_ABSTAND := 1.2
const NAME := "We Are Hack"   # vorläufig (Peter kann ihn noch ändern)

# [Anzeigetext, Spiel-Kennung oder "" (ausgegraut) oder "ende", Zusatz]
const EINTRAEGE := [
	["Rogue (1980)", "rogue", ""],
	["Hack (1982)", "", "kommt bald"],
	["NetHack (1987)", "nethack", ""],
	["Language / Sprache", "sprache", ""],
	["Beenden", "ende", ""],
]

var index := 0
var knoepfe: Array[Button] = []
var gewaehlt := ""          # nach der Wahl: "rogue", "nethack" oder "ende"
var vr_aktiv := false
var _ebene: CanvasLayer
var _wurzel: Control
var _vp: SubViewport
var _cam: XRCamera3D
var _links: XRController3D
var _rechts: XRController3D
var _vorher := {}
var _stick_uhr := 0.0
var _seit := 0.0


func _ready() -> void:
	Sprache.einrichten()
	get_window().title = NAME
	var we := WorldEnvironment.new()
	we.environment = Environment.new()
	we.environment.background_mode = Environment.BG_COLOR
	we.environment.background_color = Color.BLACK
	add_child(we)
	_ebene = CanvasLayer.new()
	add_child(_ebene)
	_wurzel = _bauen()
	_ebene.add_child(_wurzel)
	_vr_starten()
	_markieren(0)
	if "--menuetest" in OS.get_cmdline_user_args():
		load("res://werkzeuge/startmenue_test.gd").laufen(self)


func _bauen() -> Control:
	var hg := ColorRect.new()
	hg.color = Color.BLACK
	hg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var spalte := VBoxContainer.new()
	spalte.alignment = BoxContainer.ALIGNMENT_CENTER
	spalte.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	spalte.add_theme_constant_override("separation", 16)
	hg.add_child(spalte)
	spalte.add_child(_zeile(NAME, 72, GOLD))
	spalte.add_child(_zeile("Welches Spiel?", 28, Color(0.9, 0.88, 0.8)))
	spalte.add_child(_zeile("", 10, Color.WHITE))
	for i in EINTRAEGE.size():
		var e: Array = EINTRAEGE[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(720, 0)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.focus_mode = Control.FOCUS_NONE   # Auswahl führt das Menü selbst (auch für VR)
		b.add_theme_font_override("font", _schrift())
		b.add_theme_font_size_override("font_size", 30 if e[1] in ["ende", "sprache"] else 40)
		b.disabled = e[1] == ""
		for zustand in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(zustand, _kasten(false))
		b.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75))
		b.add_theme_color_override("font_hover_color", Color(0.85, 0.82, 0.75))
		b.add_theme_color_override("font_pressed_color", GOLD)
		b.add_theme_color_override("font_disabled_color", Color(0.38, 0.37, 0.35))
		b.mouse_entered.connect(func(): if not b.disabled: _markieren(i))
		b.pressed.connect(func(): _markieren(i); waehlen())
		knoepfe.append(b)
		spalte.add_child(b)
	spalte.add_child(_zeile("", 10, Color.WHITE))
	spalte.add_child(_zeile("Hoch/Runter wählen, Enter, Klick oder A startet", 20, Color(0.6, 0.58, 0.54)))
	_texte()
	return hg


func _schrift() -> SystemFont:
	var s := SystemFont.new()
	s.font_names = PackedStringArray(["Consolas", "Cascadia Mono", "Courier New", "monospace"])
	return s


func _kasten(aktiv: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.25, 0.18, 0.08) if aktiv else Color(0.06, 0.05, 0.04)
	sb.border_color = GOLD if aktiv else Color(0.3, 0.26, 0.2)
	sb.set_border_width_all(3 if aktiv else 1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


func _zeile(text: String, groesse: int, farbe: Color) -> Label:
	var l := Label.new()
	var stil := LabelSettings.new()
	stil.font = _schrift()
	stil.font_size = groesse
	stil.font_color = farbe
	stil.outline_size = 4
	stil.outline_color = Color.BLACK
	l.label_settings = stil
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Eintrag i hervorheben (ausgegraute werden übersprungen).
func _markieren(i: int) -> void:
	index = clampi(i, 0, knoepfe.size() - 1)
	for k in knoepfe.size():
		var b := knoepfe[k]
		var an := k == index
		for zustand in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(zustand, _kasten(an))
		b.add_theme_color_override("font_color", GOLD if an else Color(0.85, 0.82, 0.75))
		b.add_theme_color_override("font_hover_color", GOLD if an else Color(0.85, 0.82, 0.75))


## Einen Schritt hoch (-1) oder runter (+1), über ausgegraute Einträge hinweg.
func schritt(r: int) -> void:
	var i := index
	for _n in knoepfe.size():
		i = (i + r + knoepfe.size()) % knoepfe.size()
		if not knoepfe[i].disabled:
			_markieren(i)
			return


## Knopftexte in der gewählten Sprache (feste Texte übersetzt Godot selbst, diese sind zusammengesetzt).
func _texte() -> void:
	for i in EINTRAEGE.size():
		var e: Array = EINTRAEGE[i]
		var b := knoepfe[i]
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		if e[1] == "sprache":
			b.text = "Language:  English" if Sprache.englisch() else "Sprache:  Deutsch"
		else:
			b.text = Sprache.t(e[0]) + ("   – " + Sprache.t(e[2]) if e[2] != "" else "")


## Englisch <-> Deutsch (wird gespeichert).
func sprache_umschalten() -> void:
	Sprache.setzen("de" if Sprache.englisch() else "en")
	_texte()


## Den markierten Eintrag starten.
func waehlen() -> void:
	if gewaehlt != "" or knoepfe[index].disabled or _seit < 0.3:
		return
	if EINTRAEGE[index][1] == "sprache":
		sprache_umschalten()
		return
	gewaehlt = EINTRAEGE[index][1]
	var tw := create_tween()
	tw.tween_property(_wurzel, "modulate:a", 0.0, 0.5)
	tw.tween_callback(_weiter)


func _weiter() -> void:
	if gewaehlt == "ende":
		get_tree().quit()
		return
	Spiel.setzen(gewaehlt)
	get_tree().change_scene_to_file("res://dungeon.tscn")


func _input(event: InputEvent) -> void:
	if gewaehlt != "":
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP, KEY_W, KEY_K: schritt(-1)
			KEY_DOWN, KEY_S, KEY_J: schritt(1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE: waehlen()
			KEY_ESCAPE:
				_markieren(EINTRAEGE.size() - 1)
			KEY_1, KEY_2, KEY_3:
				var i: int = event.keycode - KEY_1
				if not knoepfe[i].disabled:
					_markieren(i)
					waehlen()
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_UP: schritt(-1)
			JOY_BUTTON_DPAD_DOWN: schritt(1)
			JOY_BUTTON_A, JOY_BUTTON_START: waehlen()
	elif event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_Y:
		_stick(-event.axis_value)


## Stick (Gamepad oder VR): + = hoch. Ein Schritt, beim Halten (VR) alle 0,35 s der nächste.
func _stick(y: float) -> void:
	if absf(y) < 0.6:
		_stick_uhr = 0.0
		return
	if _stick_uhr <= 0.0:
		schritt(-1 if y > 0 else 1)
		_stick_uhr = 0.35


func _process(delta: float) -> void:
	_seit += delta
	if _stick_uhr > 0.0:
		_stick_uhr = maxf(_stick_uhr - delta, 0.0)
	if not vr_aktiv or gewaehlt != "":
		return
	var y := 0.0
	for c in [_links, _rechts]:
		var v: Vector2 = c.get_vector2("primary")
		if absf(v.y) > absf(y):
			y = v.y
	_stick(y)
	for c in [_links, _rechts]:
		if _neu(c, "ax", c.is_button_pressed("ax_button")) or _neu(c, "abzug", c.get_float("trigger") > 0.7):
			waehlen()


func _neu(c: XRController3D, name: String, jetzt: bool) -> bool:
	var s := str(c.tracker) + name
	var war: bool = _vorher.get(s, false)
	_vorher[s] = jetzt
	return jetzt and not war


# ---------------------------------------------------------------- VR: Menü auf einer Tafel vor den Augen

func _vr_starten() -> void:
	var xr := XRServer.find_interface("OpenXR")
	if xr == null or not xr.is_initialized():
		return
	get_viewport().use_xr = true
	var origin := XROrigin3D.new()
	add_child(origin)
	_cam = XRCamera3D.new()
	origin.add_child(_cam)
	_cam.make_current()
	_links = XRController3D.new()
	_links.tracker = "left_hand"
	origin.add_child(_links)
	_rechts = XRController3D.new()
	_rechts.tracker = "right_hand"
	origin.add_child(_rechts)
	_vp = SubViewport.new()
	_vp.size = Vector2i(1280, 800)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	_ebene.reparent(_vp, false)
	var tafel := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.28, 0.8) * TAFEL_ABSTAND
	tafel.mesh = q
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = _vp.get_texture()
	tafel.material_override = mat
	tafel.position = Vector3(0, 0, -TAFEL_ABSTAND)
	_cam.add_child(tafel)
	vr_aktiv = true
	print("Startmenü: VR")
