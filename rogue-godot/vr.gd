## VR über OpenXR (Start mit --xr-mode on): Kopf und Controller; alle 2D-Anzeigen liegen auf
## einer Tafel, die wie ein Bildschirm 1 m vor den Augen schwebt (Peter, 10.11.).
## Die Controller-Knöpfe werden auf die Gamepad-Belegung von steuerung.gd übersetzt.
extends Node3D

const Vorspann = preload("res://vorspann.gd")
const PAD := 1000   # Kennung des "virtuellen Gamepads" für steuerung.gd
const TAFEL_ABSTAND := 1.2   # Meter von den Augen bis zur Anzeigetafel

var d: Node3D
var aktiv := false
var origin: XROrigin3D
var cam: XRCamera3D
var links: XRController3D
var rechts: XRController3D
var tafel_vp: SubViewport
var tafel: MeshInstance3D
var achsen := {}       # JOY_AXIS_* -> Wert
var gehalten := {}     # JOY_BUTTON_* -> bool (für Steuerkreuz-Abfragen)
var _vorher := {}      # Knopfname -> bool


func starten(dungeon: Node3D) -> bool:
	d = dungeon
	var xr := XRServer.find_interface("OpenXR")
	if xr == null or not xr.is_initialized():
		print("VR: OpenXR nicht bereit, Monitor-Modus")
		return false
	get_viewport().use_xr = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	origin = XROrigin3D.new()
	d.spieler.add_child(origin)
	cam = XRCamera3D.new()
	cam.near = 0.05
	origin.add_child(cam)
	cam.make_current()
	links = _hand("left_hand")
	rechts = _hand("right_hand")
	_tafel_bauen()
	aktiv = true
	print("VR: aktiv, Laufzeit ", xr.get_name())
	return true


func _hand(tracker: String) -> XRController3D:
	var c := XRController3D.new()
	c.tracker = tracker
	origin.add_child(c)
	var mi := MeshInstance3D.new()
	var m := CapsuleMesh.new()
	m.radius = 0.035
	m.height = 0.16
	mi.mesh = m
	mi.rotation.x = PI / 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.32, 0.25)
	mat.roughness = 0.8
	mi.material_override = mat
	mi.visible = false   # vorerst keine Hände zeigen
	c.add_child(mi)
	return c


## Alle 2D-Anzeigen (CanvasLayer) wandern auf eine Tafel vor den Augen.
func _tafel_bauen() -> void:
	tafel_vp = SubViewport.new()
	tafel_vp.size = Vector2i(1280, 800)
	tafel_vp.transparent_bg = true
	tafel_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(tafel_vp)
	tafel = MeshInstance3D.new()
	tafel.mesh = QuadMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_texture = tafel_vp.get_texture()
	mat.no_depth_test = true      # Wände dürfen das HUD nicht verdecken
	mat.render_priority = 10
	tafel.material_override = mat
	# wie ein Bildschirm 1,2 m vor den Augen (Peter 21.11.: etwas weiter weg als 1 m), gleich groß wirkend
	(tafel.mesh as QuadMesh).size = Vector2(1.28, 0.8) * TAFEL_ABSTAND
	tafel.position = Vector3(0, 0, -TAFEL_ABSTAND)
	cam.add_child(tafel)
	_ebenen_umziehen.call_deferred()


func _ebenen_umziehen() -> void:
	# Meldungen nicht am oberen Rand, sondern etwas über der Blickmitte (am Rand kaum lesbar)
	var mk: Control = d.anzeigen.meldung_kasten
	mk.anchor_left = 0.2
	mk.anchor_right = 0.8
	mk.anchor_top = 0.3
	mk.anchor_bottom = 0.3
	mk.offset_left = 0
	mk.offset_right = 0
	mk.offset_top = 0
	mk.offset_bottom = 0
	mk.grow_vertical = Control.GROW_DIRECTION_END
	if preload("res://spiel.gd").ist_nethack():
		# NetHack hat zwei Statuszeilen: etwas höher, sonst sitzen sie zu tief im Blickfeld (Peter 21.11.)
		d.anzeigen.status_kasten.offset_bottom = -70
		d.anzeigen.status_kasten.offset_top = -70
	for wurzel in [d, d.steuerung, d.grafik]:
		for k in wurzel.get_children():
			if k is CanvasLayer:
				k.reparent(tafel_vp, false)


func kopf_gier() -> float:
	return cam.rotation.y if aktiv else 0.0


var _fps_uhr := 0.0


func _process(delta: float) -> void:
	if not aktiv:
		return
	_fps_uhr += delta
	if _fps_uhr > 10.0:
		_fps_uhr = 0.0
		print("VR: FPS ", Engine.get_frames_per_second())
	_belegung()


# ---------------------------------------------------------------- Belegung (Peter, 21.11.2026)
# LINKS:  Stick gehen, Stick drücken ausruhen, X Befehlsmenü, Y Inventar auf/zu,
#         Abzug Waffe nehmen, Griff Werte + Karte aus/ein, Menütaste Hilfe.
# RECHTS: Stick links/rechts 90° drehen, nach vorne rennen, nach hinten umdrehen (180°),
#         Stick drücken suchen; rechten Griff HALTEN + Stick: hoch zappen, runter lesen,
#         links trinken, rechts essen. A weiter/Treppe/aufheben, B abbrechen,
#         Abzug werfen (Richtung = wohin der Controller zeigt), Menütaste Befehlsmenü.
# In Menüs und Listen: Laserstrahl aus dem rechten Controller, der rechte Abzug wählt.
# Bild der Belegung: Notizen\Steuerung.md / Peters Thread.

const WURF_WARTEN := 20.0   # so lange darf die Gegenstandswahl beim Werfen dauern
const STICK_AN := 0.7       # so weit muss der rechte Stick gedrückt sein
const STICK_AUS := 0.35     # ... und so weit zurück, bevor er wieder zählt

var _wurf_bis := 0.0        # > jetzt: ein Wurf wartet auf Rogues Richtungsfrage
var _stick_r := Vector2i.ZERO   # zuletzt gemeldete Richtung des rechten Sticks
var strahl: MeshInstance3D


func _belegung() -> void:
	var ls := links.get_vector2("primary")
	var rs := rechts.get_vector2("primary")
	var griff_r: bool = rechts.get_float("grip") > 0.6
	# linker Stick: gehen (steuerung.gd liest das wie ein Gamepad); Abzüge zählen dort nicht mehr
	achsen[JOY_AXIS_LEFT_X] = ls.x
	achsen[JOY_AXIS_LEFT_Y] = -ls.y
	achsen[JOY_AXIS_TRIGGER_LEFT] = 0.0
	achsen[JOY_AXIS_TRIGGER_RIGHT] = 0.0
	# rechter Stick links/rechts: drehen (ohne gehaltenen Griff), über das virtuelle Steuerkreuz
	gehalten[JOY_BUTTON_DPAD_LEFT] = not griff_r and rs.x < -0.6
	gehalten[JOY_BUTTON_DPAD_RIGHT] = not griff_r and rs.x > 0.6
	_rechter_stick(rs, griff_r)
	# Knöpfe, die steuerung.gd wie am Xbox-Controller behandelt
	_knopf(rechts, "ax_button", JOY_BUTTON_A)
	_knopf(rechts, "by_button", JOY_BUTTON_B)
	_knopf(links, "by_button", JOY_BUTTON_Y)
	_knopf(links, "ax_button", JOY_BUTTON_START)      # X: Befehlsmenü
	_knopf(rechts, "menu_button", JOY_BUTTON_START)   # rechte Menütaste: Befehlsmenü
	_knopf(links, "menu_button", JOY_BUTTON_BACK)     # linke Menütaste: Hilfe
	# eigene Belegung
	if _neu_gedrueckt("klick_l", links.is_button_pressed("primary_click")):
		_rogue_befehl(".")                            # linken Stick drücken: ausruhen
	if _neu_gedrueckt("klick_r", rechts.is_button_pressed("primary_click")):
		_rogue_befehl("s")                            # rechten Stick drücken: suchen
	if _neu_gedrueckt("abzug_l", links.get_float("trigger") > 0.7):
		_rogue_befehl("w")                            # linker Abzug: Waffe nehmen (Liste kommt)
	if _neu_gedrueckt("griff_l", links.get_float("grip") > 0.6) and not Vorspann.aktiv(self):
		d.hud_umschalten()                            # linker Griff: Werte + Karte aus/ein
	_abzug_rechts()


## Rechter Stick: ohne Griff vorne rennen, hinten umdrehen; mit gehaltenem Griff die vier Aktionen.
func _rechter_stick(rs: Vector2, griff: bool) -> void:
	var richtung := Vector2i.ZERO
	if rs.length() > STICK_AN or (_stick_r != Vector2i.ZERO and rs.length() > STICK_AUS):
		if absf(rs.y) >= absf(rs.x):
			richtung = Vector2i(0, 1 if rs.y > 0 else -1)
		else:
			richtung = Vector2i(1 if rs.x > 0 else -1, 0)
	if richtung == _stick_r:
		return
	_stick_r = richtung
	if richtung == Vector2i.ZERO:
		return
	if griff:
		match richtung:
			Vector2i(0, 1): _rogue_befehl("z")     # hoch: Zauberstab
			Vector2i(0, -1): _rogue_befehl("r")    # runter: lesen
			Vector2i(-1, 0): _rogue_befehl("q")    # links: trinken
			Vector2i(1, 0): _rogue_befehl("e")     # rechts: essen
	elif richtung == Vector2i(0, 1):
		if _spielbereit():
			d.schritt(Vector2i(0, 1), true, false)   # vorne: Rogue rennt geradeaus, bis etwas passiert
	elif richtung == Vector2i(0, -1):
		if _spielbereit():
			d.drehen_um(2)                           # hinten: umdrehen (180°)


## true nur in dem Moment, in dem etwas neu gedrückt wird (nicht beim Halten).
func _neu_gedrueckt(schluessel: String, jetzt: bool) -> bool:
	var neu: bool = jetzt and not _vorher.get(schluessel, false)
	_vorher[schluessel] = jetzt
	return neu


## Wird gerade gespielt (kein Vorspann, kein Spielende, keine Liste, keine Textseite, keine offene Frage)?
func _spielbereit() -> bool:
	return not Vorspann.aktiv(self) and d.ende_meldung == "" and not d.textseite \
			and not d.steuerung.auswahl.visible and not d.texteingabe_aktiv() and not d.fragt_richtung()


## Einen Rogue-Befehl schicken. Steht noch der Vorspann, schließt der Knopf nur ihn.
func _rogue_befehl(taste: String) -> void:
	var vorspann := Vorspann.aktiv(self)
	if vorspann:
		vorspann.schliessen()
		return
	if not _spielbereit():
		return
	d.steuerung.zuletzt_controller = true
	d.taste_senden(ord(taste))


## Meldet einen Knopf an steuerung.gd, wenn er gerade gedrückt wurde (nicht beim Halten).
func _knopf(c: XRController3D, name: String, knopf: int) -> void:
	var schluessel := str(c.tracker) + name
	var jetzt := c.is_button_pressed(name)
	if jetzt and not _vorher.get(schluessel, false):
		d.steuerung.zuletzt_controller = true
		d.steuerung._knopf(knopf)
	_vorher[schluessel] = jetzt


# ---------------------------------------------------------------- Rechter Abzug: werfen / in Menüs wählen

## Rechter Abzug (Stand wie 14:40, Peter 21.11. 16:25: Lang-Drücken wieder raus).
## In Menüs: wählt den Eintrag unter dem Laserstrahl. Grabstein/Textseite/Spielende: weiter wie A.
## Sonst: werfen; Rogue fragt erst die Richtung (kommt vom Controller), dann den Gegenstand (Liste).
func _abzug_rechts() -> void:
	var gedrueckt := _neu_gedrueckt("abzug_r", rechts.get_float("trigger") > 0.7 or rechts.is_button_pressed("trigger_click"))
	var jetzt := Time.get_ticks_msec() / 1000.0
	var vorspann := Vorspann.aktiv(self)
	var liste: Control = d.steuerung.auswahl
	_strahl_zeigen(liste.visible and not vorspann)
	if vorspann:
		if gedrueckt:
			vorspann.schliessen()
		return
	if liste.visible:
		# Laserstrahl auf die Tafel: der Eintrag unter dem Strahl leuchtet, der Abzug nimmt ihn
		var punkt := _tafel_punkt()
		var i: int = liste.eintrag_bei(punkt) if punkt.x >= 0.0 else -1
		if i >= 0 and i != liste.index:
			liste.markieren(i)
		if gedrueckt and i >= 0:
			d.steuerung._gewaehlt()
		return
	if gedrueckt and (d.ende_meldung != "" or d.textseite or "--More--" in d.meldung):
		if d.ende_meldung != "":
			d.neu_starten()            # nach dem Tod: neues Spiel (wie A)
		else:
			d.steuerung._knopf_a()     # Grabstein, Textseite, --More--: weiter (wie A)
		return
	if jetzt < _wurf_bis and d.fragt_richtung():
		_wurf_bis = 0.0
		d.taste_senden(ord(d.RICHTUNG_TASTE[_zeigerichtung()]))   # Wurfrichtung: wohin der Controller zeigt
		return
	if gedrueckt and _spielbereit():
		d.steuerung.zuletzt_controller = true
		_wurf_bis = jetzt + WURF_WARTEN
		d.taste_senden(ord("t"))   # Rogues Befehl "throw"

## Wohin zeigt der rechte Controller? Eine der 8 Rogue-Richtungen (x nach Osten, y nach Süden).
func _zeigerichtung() -> Vector2i:
	var v := -rechts.global_basis.z
	var k := roundi(atan2(v.z, v.x) / (PI / 4.0))
	return Vector2i(roundi(cos(k * PI / 4.0)), roundi(sin(k * PI / 4.0)))


## Wo trifft der Strahl des rechten Controllers die Tafel? Ergebnis in Tafel-Pixeln, sonst (-1, -1).
func _tafel_punkt() -> Vector2:
	var start := rechts.global_position
	var richtung := -rechts.global_basis.z
	var t_inv := tafel.global_transform.affine_inverse()
	var s := t_inv * start
	var r := (t_inv.basis * richtung)
	if absf(r.z) < 0.0001:
		return Vector2(-1, -1)
	var weg := -s.z / r.z
	if weg <= 0.0:
		return Vector2(-1, -1)
	var treffer := s + r * weg
	var groesse := (tafel.mesh as QuadMesh).size
	var u := treffer.x / groesse.x + 0.5
	var v := 0.5 - treffer.y / groesse.y
	if u < 0.0 or u > 1.0 or v < 0.0 or v > 1.0:
		return Vector2(-1, -1)
	_strahl_laenge = start.distance_to(tafel.global_transform * treffer)
	return Vector2(u * tafel_vp.size.x, v * tafel_vp.size.y)


var _strahl_laenge := 1.0


## Dünner Laserstrahl aus dem rechten Controller, nur solange ein Menü offen ist.
func _strahl_zeigen(an: bool) -> void:
	if strahl == null:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.8, 0.4, 0.7)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.no_depth_test = true
		mat.render_priority = 11
		strahl = MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.004, 0.004, 1.0)
		strahl.mesh = b
		strahl.material_override = mat
		add_child(strahl)
	strahl.visible = an
	if an:
		var richtung := -rechts.global_basis.z
		var laenge := clampf(_strahl_laenge, 0.2, 3.0)
		strahl.global_transform = Transform3D(Basis.looking_at(richtung), rechts.global_position + richtung * laenge / 2.0)
		strahl.scale = Vector3(1, 1, laenge)