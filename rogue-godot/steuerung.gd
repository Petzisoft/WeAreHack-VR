## Schritt 4: Steuerung mit Controller (Gamepad), Maus, Pfeiltasten/Ziffernblock (WASD wahlweise).
## Alles wird in normale Rogue-Tasten übersetzt. Rogue bleibt rundenbasiert:
## jeder Schritt ist ein Zug, beim Gedrückthalten werden einfach Schritte nacheinander geschickt.
extends Node

const Auswahl = preload("res://auswahl_menue.gd")
const Vorspann = preload("res://vorspann.gd")
const Spiel = preload("res://spiel.gd")
const Sprache = preload("res://sprache.gd")
const Spielstand = preload("res://spielstand.gd")

const TOTZONE_AN := 0.55     # Stick so weit drücken, damit er zählt
const TOTZONE_AUS := 0.35    # ... und so weit loslassen, damit er wieder frei ist
const ERSTE_PAUSE := 0.30    # so lange halten, bis das Dauerlaufen beginnt
const TAKT := 0.20           # Sekunden pro Feld beim Dauerlaufen (= Gleitzeit)
const DREH_TAKT := 0.40
const MENUE_TAKT := 0.16
const MAUS_EMPFINDLICH := 0.0025
const STICK_DREHEN := 2.6    # Bogenmaß pro Sekunde bei voll gedrücktem rechten Stick
const STICK_NICKEN := 1.6

const ZIFFERNBLOCK := {
	KEY_KP_8: Vector2i(0, 1), KEY_KP_2: Vector2i(0, -1), KEY_KP_4: Vector2i(-1, 0), KEY_KP_6: Vector2i(1, 0),
	KEY_KP_7: Vector2i(-1, 1), KEY_KP_9: Vector2i(1, 1), KEY_KP_1: Vector2i(-1, -1), KEY_KP_3: Vector2i(1, -1),
}

const VERBEN := {
	"eat": "essen", "quaff": "trinken", "read": "lesen", "wield": "in die Hand nehmen",
	"wear": "anziehen", "put on": "anstecken", "remove": "abnehmen", "throw": "werfen",
	"zap with": "benutzen", "drop": "ablegen", "call": "benennen", "identify": "bestimmen",
}

var d   # die Dungeon-Szene (dungeon_3d.gd)
var dauerlaufen := true
## WASD zum Laufen (F5). Aus = alle Buchstaben gehen wie im Original an Rogue.
var wasd_modus := false
var _kurz_text := ""
var _kurz_bis := 0.0
var zuletzt_controller := false
var auswahl: Auswahl
var hinweis: Label

var _halte := Vector2i.ZERO
var _naechster := 0.0
var _gesperrt := false
var _feld_vorher := Vector2i(-9999, -9999)
var _meldung_start := ""
var _monster_start := 0
var _dreh_halte := 0
var _dreh_naechster := 0.0
var _nav_halte := 0
var _nav_naechster := 0.0
var _stick_aktiv := false
var _lt_vorher := false
var maus_frei := false   # Esc/F4: Mauszeiger freigeben statt umsehen
var maus_aktiv := false  # Maus dreht gerade den Blick
## Über Remotedesktop lässt sich die Maus nicht einfangen: dann "Maustaste halten und ziehen".
var fernzugriff := false
var _maus_log := {"bewegungen": 0, "summe": Vector2.ZERO, "fangen": 0, "fokus": 0}

# Auswahlliste: "befehl", "gegenstand" oder "janein"
var _wahl_art := ""
var _inventar_wahl := ""   # im Inventar gewählter Buchstabe (für den Befehl danach)
# Gegenstandsfrage: "" (nichts), "liste" (Liste angefordert), "wahl" (Liste offen), "sperre" (kurz warten)
var _wahl_zustand := ""
var _wahl_seit := 0.0
var _wahl_frage := ""
var _maus_zurueck := false   # Maus war vor der Auswahlliste eingefangen
var _liste_zu_seit := -10.0  # wann die letzte Auswahlliste geschlossen wurde
var letzte_wahl := ""        # zuletzt gewählter Gegenstand (Buchstabe), für "Wurf wiederholen" in VR
var liste_aus_bis := 0.0     # bis dahin keine automatische Gegenstandsliste (VR wiederholt den Wurf selbst)


func _ready() -> void:
	fernzugriff = _ist_fernzugriff()
	var ebene := CanvasLayer.new()
	ebene.layer = 5
	add_child(ebene)
	hinweis = Label.new()
	var stil := LabelSettings.new()
	var schrift := SystemFont.new()
	schrift.font_names = PackedStringArray(["Segoe UI", "Arial"])
	stil.font = schrift
	stil.font_size = 17
	stil.font_color = Color(0.8, 0.85, 0.95)
	stil.outline_size = 4
	stil.outline_color = Color.BLACK
	hinweis.label_settings = stil
	hinweis.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hinweis.offset_top = -78
	hinweis.offset_bottom = -52
	hinweis.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hinweis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ebene.add_child(hinweis)
	auswahl = Auswahl.new()
	ebene.add_child(auswahl)
	d.rogue.bild_geaendert.connect(_bild)
	maus_fangen.call_deferred()


## Maus "einfangen": der Zeiger verschwindet und jede Mausbewegung dreht den Blick.
## Am PC Godots "captured"-Modus (liefert reine Bewegung, nichts springt zurück; 21.11.2026:
## das frühere eigene Zurücksetzen in die Mitte ließ bei Peter den Blick zurückspringen).
## Über Remotedesktop geht das nicht, dort wird mit gedrückter Maustaste gezogen (fernzugriff).
func maus_fangen() -> void:
	if fernzugriff or maus_frei or d.ende_meldung != "" or not get_window().has_focus():
		return
	if "--selbsttest" in OS.get_cmdline_user_args():
		maus_aktiv = true   # im Test den echten Mauszeiger nicht anfassen
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	maus_aktiv = true
	_maus_log["fangen"] += 1


func maus_loslassen(auf_wunsch := true) -> void:
	if auf_wunsch:
		maus_frei = true
	maus_aktiv = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_maus_log["fokus"] += 1
		maus_fangen()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		maus_loslassen(false)


func _exit_tree() -> void:
	# Kleines Protokoll, falls die Maus auf einem PC nicht geht
	var f := FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../maus-protokoll.txt").simplify_path(), FileAccess.WRITE)
	if f:
		f.store_line(str(_maus_log))


## Läuft das Spiel in einer Remotedesktop-Sitzung?
static func _ist_fernzugriff() -> bool:
	if OS.get_environment("SESSIONNAME").to_upper().begins_with("RDP"):
		return true
	var ausgabe := []
	OS.execute("query", ["session"], ausgabe)
	for zeile in "".join(ausgabe).split("\n"):
		if zeile.begins_with(">") and "rdp" in zeile.to_lower():
			return true
	return false


func _jetzt() -> float:
	return Time.get_ticks_msec() / 1000.0


func _pad() -> int:
	if d.vr and d.vr.aktiv:
		return d.vr.PAD
	var p := Input.get_connected_joypads()
	return p[0] if p.size() > 0 else -1


## Gamepad oder VR-Controller (vr.gd übersetzt dessen Knöpfe auf die Gamepad-Belegung)
func _achse(pad: int, achse: int) -> float:
	if d.vr and pad == d.vr.PAD:
		return d.vr.achsen.get(achse, 0.0)
	return Input.get_joy_axis(pad, achse)


func _gehalten(pad: int, knopf: int) -> bool:
	if d.vr and pad == d.vr.PAD:
		return d.vr.gehalten.get(knopf, false)
	return Input.is_joy_button_pressed(pad, knopf)


# ---------------------------------------------------------------- Maus

func _input(event: InputEvent) -> void:
	if Vorspann.aktiv(self):
		return   # Tasten und Klicks schließen erst den Vorspann (vorspann.gd)
	if event is InputEventMouseMotion and maus_aktiv:
		var m := event as InputEventMouseMotion
		_maus_log["bewegungen"] += 1
		_maus_log["summe"] += m.relative.abs()
		d.umsehen(-m.relative.x * MAUS_EMPFINDLICH, -m.relative.y * MAUS_EMPFINDLICH)
	elif event is InputEventMouseMotion and fernzugriff:
		var m := event as InputEventMouseMotion
		if m.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT):
			_maus_log["bewegungen"] += 1
			_maus_log["summe"] += m.relative.abs()
			d.umsehen(-m.relative.x * MAUS_EMPFINDLICH * 1.5, -m.relative.y * MAUS_EMPFINDLICH * 1.5)
	elif event is InputEventMouseButton and event.pressed:
		if auswahl.visible and event.button_index == MOUSE_BUTTON_LEFT:
			# Klick auf einen Eintrag der Auswahlliste nimmt ihn, Klick daneben bricht ab
			var i: int = auswahl.eintrag_bei(event.position)
			if i >= 0:
				auswahl.index = i
				_gewaehlt()
			else:
				_abbrechen()
			get_viewport().set_input_as_handled()
		elif not maus_aktiv and not fernzugriff and event.button_index == MOUSE_BUTTON_LEFT:
			maus_frei = false
			maus_fangen()
		elif auswahl.visible and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			auswahl.bewegen(-1)
		elif auswahl.visible and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			auswahl.bewegen(1)
	elif event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		zuletzt_controller = false
		if k.keycode == KEY_F4:
			if maus_aktiv:
				maus_loslassen()
			else:
				maus_frei = false
				maus_fangen()
			get_viewport().set_input_as_handled()
		elif k.keycode == KEY_ESCAPE and maus_aktiv and not auswahl.visible:
			maus_loslassen()   # Esc gibt die Maus frei (und geht trotzdem an Rogue)
		elif auswahl.visible:
			# Tastatur in der Auswahlliste: Pfeile/W/S blättern (in _process), Enter nimmt, Esc bricht ab
			if k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER or k.keycode == KEY_SPACE:
				_gewaehlt()
			elif k.keycode == KEY_ESCAPE or k.keycode == KEY_TAB:
				_abbrechen()
			elif _wahl_art in ["gegenstand", "befehl", "menue", "inventar", "aktion", "janein"] and k.unicode > 32 and k.unicode < 127:
				# Buchstabe des Gegenstands bzw. Taste des Befehls drücken nimmt ihn sofort (Groß/klein zählt: w/W)
				var i := auswahl.index_von(char(k.unicode))
				if i >= 0:
					auswahl.index = i
					_gewaehlt()
			get_viewport().set_input_as_handled()
		elif k.keycode == KEY_TAB and d.ende_meldung == "":
			befehlsmenue()
			get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		zuletzt_controller = true
		_knopf((event as InputEventJoypadButton).button_index)
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- Controller-Knöpfe

func _knopf(b: int) -> void:
	var vorspann := Vorspann.aktiv(self)
	if vorspann:
		vorspann.schliessen()   # erster Knopf (auch VR) schließt den Vorspann, geht nicht ans Spiel
		return
	if d.ende_meldung != "":
		if b == JOY_BUTTON_A or b == JOY_BUTTON_START:
			d.neu_starten()
		elif b == JOY_BUTTON_B:
			get_tree().quit()
		return
	if d.anzeigen.hilfe_kasten.visible and b != JOY_BUTTON_BACK:
		d.anzeigen.hilfe_kasten.visible = false
		return
	if auswahl.visible:
		match b:
			JOY_BUTTON_A: _gewaehlt()
			JOY_BUTTON_B, JOY_BUTTON_START: _abbrechen()
		return
	match b:
		JOY_BUTTON_A: _knopf_a()
		JOY_BUTTON_B: d.taste_senden(27)
		JOY_BUTTON_X: d.taste_senden(ord("s"))
		JOY_BUTTON_Y:
			# Y öffnet und schließt das Inventar; fragt Rogue gerade nach einem Gegenstand, zeigt Y die Liste
			if d.textseite:
				d.taste_senden(ord(" "))
			elif liste_frage(d.meldung):
				d.taste_senden(_liste_taste())
			else:
				d.taste_senden(ord("i"))
		JOY_BUTTON_LEFT_SHOULDER: d.drehen_um(-1)
		JOY_BUTTON_RIGHT_SHOULDER: d.drehen_um(1)
		JOY_BUTTON_START: befehlsmenue()
		JOY_BUTTON_BACK: d.anzeigen.hilfe_kasten.visible = not d.anzeigen.hilfe_kasten.visible
		JOY_BUTTON_LEFT_STICK: d.karte_umschalten()
		JOY_BUTTON_RIGHT_STICK: d.blick_geradeaus()


## A macht "das Naheliegende": weiterblättern, Treppe benutzen oder aufheben.
func _knopf_a() -> void:
	var m: String = d.meldung
	if _wartet_auf_return():
		d.taste_senden(13)   # Grabstein (RIP): Rogue wartet auf Enter
	elif "--More--" in m or d.textseite:
		d.taste_senden(ord(" "))
	elif "call it" in m:
		d.taste_senden(13)
	elif d.auf_treppe():
		d.taste_senden(ord(">"))
	else:
		d.taste_senden(ord(","))


## Steht "[Press return to continue]" auf dem Bild (Grabstein nach dem Tod)?
func _wartet_auf_return() -> bool:
	for z in d.rogue.raster:
		if "Press return" in z:
			return true
	return false


## War eben eine Auswahlliste offen oder ist eine unterwegs? Dann soll in VR nichts geworfen werden.
func liste_kuerzlich() -> bool:
	return auswahl.visible or _wahl_zustand != "" or _jetzt() - _liste_zu_seit < 0.6


# ---------------------------------------------------------------- Bewegung und Wiederholung

func _process(delta: float) -> void:
	if Vorspann.aktiv(self):
		return   # solange der Vorspann steht, weder laufen noch umsehen
	var jetzt := _jetzt()
	var pad := _pad()
	# Rechter Stick: frei umsehen
	if pad >= 0:
		var rs := Vector2(_achse(pad, JOY_AXIS_RIGHT_X), _achse(pad, JOY_AXIS_RIGHT_Y))
		if rs.length() > 0.2:
			zuletzt_controller = true
			d.umsehen(-rs.x * absf(rs.x) * STICK_DREHEN * delta, -rs.y * absf(rs.y) * STICK_NICKEN * delta)
		# Linker Trigger: eine Runde ausruhen
		var lt := _achse(pad, JOY_AXIS_TRIGGER_LEFT) > 0.6
		if lt and not _lt_vorher and not auswahl.visible and d.ende_meldung == "":
			zuletzt_controller = true
			d.taste_senden(ord("."))
		_lt_vorher = lt

	if _wahl_zustand == "sperre" and jetzt - _wahl_seit > 0.6:
		_wahl_zustand = ""
	elif _wahl_zustand == "liste" and jetzt - _wahl_seit > 2.0:
		_wahl_zustand = ""
	elif _wahl_zustand == "wahl" and not auswahl.visible:
		_wahl_zustand = ""   # Liste wurde anders geschlossen oder ersetzt (z. B. durch das Befehlsmenü)

	var e := _eingabe(pad)
	var rel: Vector2i = e[0]
	var dreh: int = e[1]

	if auswahl.visible:
		_halte = rel
		_dreh_halte = dreh
		var nav := -rel.y
		if nav != _nav_halte:
			_nav_halte = nav
			if nav != 0:
				auswahl.bewegen(nav)
				_nav_naechster = jetzt + ERSTE_PAUSE
		elif nav != 0 and jetzt >= _nav_naechster:
			auswahl.bewegen(nav)
			_nav_naechster = jetzt + MENUE_TAKT
		_hinweis_setzen(pad)
		return
	_nav_halte = 0

	if d.ende_meldung != "":
		rel = Vector2i.ZERO
		dreh = 0
	# Fragt Rogue nach einer Richtung, sind links/rechts Richtungen statt Drehungen
	if d.fragt_richtung() and rel == Vector2i.ZERO and dreh != 0:
		rel = Vector2i(dreh, 0)
		dreh = 0
	var laufen := Input.is_key_pressed(KEY_SHIFT) or (pad >= 0 and _achse(pad, JOY_AXIS_TRIGGER_RIGHT) > 0.5)

	# Schritte
	if rel != _halte:
		var vorher := _halte
		_halte = rel
		if rel == Vector2i.ZERO:
			_gesperrt = false
		elif vorher == Vector2i.ZERO:
			_gesperrt = false
			_schritt(rel, laufen, true)
			_naechster = jetzt + ERSTE_PAUSE
	elif rel != Vector2i.ZERO and not _gesperrt and dauerlaufen and jetzt >= _naechster:
		_schritt(rel, laufen, false)
		_naechster = jetzt + TAKT

	# 90°-Drehungen (Pfeil links/rechts, Steuerkreuz links/rechts)
	if dreh != _dreh_halte:
		_dreh_halte = dreh
		if dreh != 0:
			d.drehen_um(dreh)
			_dreh_naechster = jetzt + DREH_TAKT
	elif dreh != 0 and jetzt >= _dreh_naechster:
		d.drehen_um(dreh)
		_dreh_naechster = jetzt + DREH_TAKT

	_hinweis_setzen(pad)


## Liest die Richtung: Ergebnis [rel, drehen], rel = (rechts, vorwärts) relativ zur Blickrichtung.
func _eingabe(pad: int) -> Array:
	var rel := Vector2i.ZERO
	var dreh := 0
	if get_window().has_focus():
		if Input.is_key_pressed(KEY_UP): rel.y += 1
		if Input.is_key_pressed(KEY_DOWN): rel.y -= 1
		if Input.is_key_pressed(KEY_HOME): rel = Vector2i(-1, 1)
		if Input.is_key_pressed(KEY_PAGEUP): rel = Vector2i(1, 1)
		if Input.is_key_pressed(KEY_END): rel = Vector2i(-1, -1)
		if Input.is_key_pressed(KEY_PAGEDOWN): rel = Vector2i(1, -1)
		if Input.is_key_pressed(KEY_LEFT): dreh -= 1
		if Input.is_key_pressed(KEY_RIGHT): dreh += 1
		# Ziffernblock (NumLock an): 8 Richtungen relativ zum Blick, 4/6 = seitwärts
		for t in ZIFFERNBLOCK:
			if Input.is_key_pressed(t):
				rel = ZIFFERNBLOCK[t]
		# WASD nur im WASD-Modus und wenn Rogue gerade keine Buchstaben erwartet
		var wasd_frei: bool = auswahl.visible or (wasd_modus and not d.texteingabe_aktiv())
		if wasd_frei and not Input.is_key_pressed(KEY_CTRL):
			if Input.is_physical_key_pressed(KEY_W): rel.y += 1
			if Input.is_physical_key_pressed(KEY_S): rel.y -= 1
			if not auswahl.visible:
				if Input.is_physical_key_pressed(KEY_A): rel.x -= 1
				if Input.is_physical_key_pressed(KEY_D): rel.x += 1
	if pad >= 0:
		if _gehalten(pad, JOY_BUTTON_DPAD_UP): rel.y = 1
		if _gehalten(pad, JOY_BUTTON_DPAD_DOWN): rel.y = -1
		if _gehalten(pad, JOY_BUTTON_DPAD_LEFT): dreh = -1
		if _gehalten(pad, JOY_BUTTON_DPAD_RIGHT): dreh = 1
		var s := Vector2(_achse(pad, JOY_AXIS_LEFT_X), _achse(pad, JOY_AXIS_LEFT_Y))
		if s.length() > (TOTZONE_AUS if _stick_aktiv else TOTZONE_AN):
			_stick_aktiv = true
			zuletzt_controller = true
			rel = _stick_richtung(s)
		else:
			_stick_aktiv = false
			_stick_rel = Vector2i.ZERO
	rel = rel.clamp(Vector2i(-1, -1), Vector2i(1, 1))
	return [rel, dreh]


## Stick in eine der 8 Rogue-Richtungen. Vor/zurück/links/rechts bekommen breite Bereiche (je 70°),
## schräg nur schmale (20°), damit "geradeaus" nicht ungewollt zum Schrägschritt gegen die Wand wird
## (Peter 21.11.). Eine gewählte Richtung bleibt, bis der Stick deutlich weiter dreht (kein Flackern).
const STICK_GERADE := 35.0   # Grad Abweichung, bis zu der eine Hauptrichtung gilt
const STICK_HALTEN := 42.0   # ... und bis zu der eine schon gewählte Hauptrichtung bleibt
var _stick_rel := Vector2i.ZERO

func _stick_richtung(s: Vector2) -> Vector2i:
	var winkel := rad_to_deg(atan2(-s.y, s.x))   # 0 = rechts, 90 = vorwärts
	var haupt := roundi(winkel / 90.0)           # nächste Hauptrichtung (0..3, -1, -2)
	var abweichung := absf(winkel - haupt * 90.0)
	var gerade_rel := Vector2i(roundi(cos(deg_to_rad(haupt * 90.0))), roundi(sin(deg_to_rad(haupt * 90.0))))
	var grenze := STICK_HALTEN if gerade_rel == _stick_rel else STICK_GERADE
	if abweichung <= grenze:
		_stick_rel = gerade_rel
	else:
		var k := roundi(winkel / 45.0)
		_stick_rel = Vector2i(roundi(cos(deg_to_rad(k * 45.0))), roundi(sin(deg_to_rad(k * 45.0))))
	return _stick_rel


func _schritt(rel: Vector2i, laufen: bool, erst: bool) -> void:
	if d.fragt_richtung():
		if erst:
			d.richtung_senden(rel)
		_gesperrt = true
		return
	if d.textseite or "--More--" in d.meldung or d.texteingabe_aktiv():
		_gesperrt = true   # erst die Meldung/Seite wegklicken
		return
	if not erst:
		# Dauerlaufen stoppt, sobald etwas passiert
		if d.feld == _feld_vorher:
			_gesperrt = true   # nicht weitergekommen (Wand, Kampf ...)
			return
		if d.meldung != "" and d.meldung != _meldung_start:
			_gesperrt = true
			return
		if d.monster_anzahl > _monster_start:
			_gesperrt = true
			return
	else:
		_meldung_start = d.meldung
	_monster_start = d.monster_anzahl
	_feld_vorher = d.feld
	d.schritt(rel, laufen, not erst)
	if laufen:
		_gesperrt = true   # Rogue rennt selbst, bis etwas passiert


# ---------------------------------------------------------------- Auswahllisten

func befehlsmenue() -> void:
	d.anzeigen.hilfe_kasten.visible = false
	_wahl_art = "befehl"
	_wahl_zustand = ""
	var befehle := [
		["Inventar ansehen", "i"],
		["Essen", "e"],
		["Trank trinken", "q"],
		["Schriftrolle lesen", "r"],
		["Waffe in die Hand nehmen", "w"],
		["Rüstung anziehen", "W"],
		["Rüstung ausziehen", "T"],
		["Ring anstecken", "P"],
		["Ring abnehmen", "R"],
		["Zauberstab benutzen", "z"],
		["Etwas werfen", "t"],
		["Etwas ablegen", "d"],
		["Aufheben", ","],
		["Treppe hinab", ">"],
		["Treppe hinauf", "<"],
		["Suchen (Geheimtüren, Fallen)", "s"],
		["Eine Runde ausruhen", "."],
		["Kämpfen bis zum Ende", "F"],
		["Letzten Befehl wiederholen", "a"],
		["Letzte Meldung nochmal", char(16)],
		["Was habe ich entdeckt?", "D"],
		["Gegenstand benennen", "c"],
		["Falle untersuchen (dann Richtung)", "^"],
		["Gehen ohne aufzuheben (dann Richtung)", "m"],
		[tr("Dauerlaufen beim Halten: ") + tr("AN" if dauerlaufen else "AUS"), "#dauer"],
		[tr("WASD zum Laufen (F5): ") + tr("AN" if wasd_modus else "AUS"), "#wasd"],
		["Karte oben rechts ein/aus", "#karte"],
		["Original-Textbild ein/aus", "#text"],
		["Hilfe anzeigen", "#hilfe"],
		["Spiel beenden", "Q"],
	]
	# Speicherplätze (Peter 22.11.): 3 je Spiel, abschaltbar mit dem Original-Modus
	var plaetze := []
	if not Spielstand.original_modus():
		for n in range(1, Spielstand.PLAETZE + 1):
			plaetze.append([tr("Speichern  -> ") + Spielstand.beschreibung(n), "#speichern%d" % n])
		for n in range(1, Spielstand.PLAETZE + 1):
			if Spielstand.belegt(n):
				plaetze.append([tr("Laden     <- ") + Spielstand.beschreibung(n), "#laden%d" % n])
	plaetze.append([tr("Original-Modus (keine Speicherplätze): ") + tr("AN" if Spielstand.original_modus() else "AUS"), "#original"])
	befehle = befehle.slice(0, befehle.size() - 1) + plaetze + befehle.slice(befehle.size() - 1)   # vor "Spiel beenden"
	# Rogue-Taste bzw. Funktionstaste neben jeden Befehl schreiben (Peter 21.11.)
	const F_TASTEN := {"#karte": "F2", "#text": "F3", "#hilfe": "F1"}
	for b in befehle:
		var w: String = b[1]
		var taste: String = F_TASTEN.get(w, "") if w.begins_with("#") else ("Strg+P" if w == char(16) else w)
		b[0] = tr(b[0])
		if taste != "":
			b[0] = "%-32s %s" % [b[0], tr(taste)]
	_liste_zeigen("Befehle", befehle)


func _gewaehlt() -> void:
	var w = auswahl.wert()
	_liste_zu()
	match _wahl_art:
		"befehl":
			match str(w):
				"#dauer": dauerlaufen = not dauerlaufen
				"#wasd": wasd_umschalten()
				"#karte": d.karte_umschalten()
				"#text": d.textbild_umschalten()
				"#hilfe": d.anzeigen.hilfe_kasten.visible = true
				"#original": Spielstand.original_umschalten()
				"#speichern1", "#speichern2", "#speichern3": d.speichern(int(str(w).right(1)))
				"#laden1", "#laden2", "#laden3": d.laden(int(str(w).right(1)))
				_:
					for c in str(w):
						d.taste_senden(c.unicode_at(0))
		"gegenstand", "menue":
			if not Spiel.ist_nethack() and not _frage_sichtbar():
				d.taste_senden(ord(" "))   # Rogues Liste steht noch: erst schließen ...
			d.taste_senden(ord(str(w)))   # ... dann den Buchstaben schicken (NetHack-Menü: Buchstabe wählt direkt)
			if Spiel.ist_nethack() and _wahl_art == "menue":
				for z in d.rogue.raster:
					if "Pick up what?" in z:
						d.taste_senden(13)   # Mehrfachauswahl: mit Enter bestätigen
						break
			letzte_wahl = str(w)
			_wahl_zustand = "sperre"
			_wahl_seit = _jetzt()
		"janein":
			d.taste_senden(ord(str(w)))
			_wahl_zustand = "sperre"
			_wahl_seit = _jetzt()
		"inventar":
			# Gegenstand gewählt: Liste der Befehle dafür (essen, trinken, anziehen ...)
			_inventar_wahl = str(w)
			var name := ""
			for e in auswahl.eintraege:
				if e[1] == w:
					name = str(e[0]).substr(3).strip_edges()
			_wahl_art = "aktion"
			_liste_zeigen(name if name != "" else tr("Gegenstand %s") % str(w), _aktionen_fuer(name))
			auswahl.visible = true
		"aktion":
			_textseite_schliessen()
			for c in str(w):
				d.taste_senden(c.unicode_at(0))   # Befehl ...
			d.taste_senden(ord(_inventar_wahl))   # ... und gleich der Gegenstand (das Spiel liest der Reihe nach)
			_wahl_zustand = "sperre"
			_wahl_seit = _jetzt()


## Inventar oder Liste des Spiels schließen (Rogue: Leertaste, NetHack: Esc).
func _textseite_schliessen() -> void:
	if d.textseite:
		d.taste_senden(27 if Spiel.ist_nethack() else 32)


## Befehle, die zu einem Gegenstand passen (nach Wörtern im Namen), die übrigen dahinter.
func _aktionen_fuer(name: String) -> Array:
	var n := name.to_lower()
	var alle := [["Essen", "e"], ["Trinken", "q"], ["Lesen", "r"], ["In die Hand nehmen (Waffe)", "w"],
			["Anziehen (Rüstung)", "W"], ["Ausziehen", "T"], ["Anstecken (Ring, Amulett)", "P"], ["Abnehmen", "R"],
			["Werfen", "t"], ["Zappen (Zauberstab)", "z"], ["Ablegen", "d"]]
	if Spiel.ist_nethack():
		alle.insert(3, ["Anwenden (Werkzeug)", "a"])
	var passt := []
	var wort := {"e": ["food", "ration", "apple", "egg", "corpse", "melon", "orange", "banana", "carrot", "pear", "cookie", "pancake", "tin", "meat", "slime mold", "lembas", "cram", "candy", "garlic", "jelly", "kelp", "pie"],
			"q": ["potion"], "r": ["scroll", "spellbook"], "w": ["sword", "dagger", "mace", "axe", "spear", "bow", "club", "hammer", "knife", "whip", "flail", "lance", "trident", "pick-axe", "scimitar", "katana"],
			"W": ["armor", "mail", "helmet", "cloak", "shield", "gloves", "gauntlets", "boots", "shoes", "hat", "robe", "shirt", "helm"],
			"P": ["ring", "amulet", "blindfold", "towel", "lenses"], "z": ["wand", "staff"], "t": ["dart", "arrow", "shuriken", "dagger", "boomerang", "javelin", "bolt"],
			"a": ["lamp", "lantern", "candle", "key", "pick", "horn", "whistle", "flute", "harp", "drum", "bell", "mirror", "camera", "box", "chest", "bag", "sack", "stethoscope", "leash", "saddle", "marker", "unicorn horn", "grease", "tinning", "figurine", "crystal ball"]}
	for a in alle:
		for w in wort.get(a[1], []):
			if w in n:
				passt.append(a)
				break
	var rest := alle.filter(func(a): return not passt.has(a))
	return (passt + rest).map(func(a): return ["%-30s %s" % [tr(a[0]), a[1]], a[1]])   # Taste daneben, wie im Befehlsmenü


## Steht Rogues Frage ("... (* for list):") schon wieder da? Dann ist Rogues eigene Liste zu
## (bei nur einem Gegenstand zeigt Rogue sie als Meldung mit --More--, die das Spiel selbst wegklickt).
func _frage_sichtbar() -> bool:
	return liste_frage(d.meldung) and not d.textseite


## Fragt das Spiel nach einem Gegenstand? Rogue: "... (* for list):", NetHack: "... [abc or ?*]".
static func liste_frage(m: String) -> bool:
	if Spiel.ist_nethack():
		return "?*]" in m
	return "(* for list)" in m


## Taste, mit der das Spiel die passenden Gegenstände auflistet (Rogue *, NetHack ?).
static func _liste_taste() -> int:
	return ord("?") if Spiel.ist_nethack() else ord("*")


## NetHack: Auswahlmenü auf dem Bild (Figur wählen, Aufheben ...), aber nicht das Inventar (i).
func _nh_menue() -> bool:
	if d.rogue.letzte_taste == ord("i"):
		return false
	for z in d.rogue.raster:
		if "Pick " in z or "Pick up what?" in z or "What would you like to" in z:
			return true
	return false


func _abbrechen() -> void:
	_liste_zu()
	match _wahl_art:
		"inventar", "aktion":
			_textseite_schliessen()
		"gegenstand", "menue":
			if not Spiel.ist_nethack() and not _frage_sichtbar():
				d.taste_senden(ord(" "))
			d.taste_senden(27)
		"janein":
			d.taste_senden(ord("n"))
	if _wahl_art != "befehl":
		_wahl_zustand = "sperre"
		_wahl_seit = _jetzt()


func wasd_umschalten() -> void:
	wasd_modus = not wasd_modus
	kurz_zeigen("WASD-Laufen AN  (Rogue-Befehle w a s d: Strg + Buchstabe)" if wasd_modus
			else "WASD-Laufen AUS  (alle Buchstaben gehen wie im Original an Rogue)")


func kurz_zeigen(t: String) -> void:
	_kurz_text = t
	_kurz_bis = _jetzt() + 4.0


## Wird bei jedem neuen Rogue-Bild aufgerufen: fragt Rogue nach einem Gegenstand, erscheint sofort
## eine Auswahlliste (Peter 21.11.: auch mit Tastatur und Maus, nicht erst Liste ansehen und Buchstaben merken).
## Ja/Nein-Fragen bekommen nur mit dem Controller eine Liste (auf der Tastatur tippt man y oder n).
func _bild() -> void:
	if auswahl.visible:
		if _wahl_art == "inventar" and not d.textseite:
			_liste_zu()   # das Spiel hat sein Inventar schon selbst geschlossen
			_wahl_zustand = ""
		return
	var m: String = d.meldung
	match _wahl_zustand:
		"":
			# Nach Leertaste oder Esc ist die Frage nur eine alte, stehengebliebene Meldungszeile
			# (z. B. nach dem Schließen des Inventars) – dann keine Liste anfordern (Protokoll 21.11.).
			var alt: bool = d.rogue.letzte_taste in [32, 27]
			if liste_frage(m) and not alt and _jetzt() >= liste_aus_bis:
				_wahl_frage = m
				_wahl_zustand = "liste"
				_wahl_seit = _jetzt()
				d.taste_senden(_liste_taste())   # das Spiel soll die passenden Gegenstände auflisten
			elif d.textseite and d.rogue.letzte_taste == ord("i") and not _eintraege_lesen().is_empty():
				# Inventar (Peter 22.11.): nie als bloßer Text, sondern als Auswahlliste mit Zeilenwahl und Mauszeiger
				_wahl_art = "inventar"
				_wahl_zustand = "wahl"
				_liste_zeigen("Inventar  (wählen = was damit tun?)", _eintraege_lesen())
				d.anzeigen.volltext.visible = false
			elif Spiel.ist_nethack() and d.textseite and _nh_menue():
				# NetHack-Menü (z. B. Figur wählen): gleich als Auswahlliste zeigen
				var liste := _eintraege_lesen()
				if not liste.is_empty():
					_wahl_frage = "Auswahl"
					for z in d.rogue.raster:
						if "Pick" in z:
							_wahl_frage = z.substr(z.find("Pick")).strip_edges()
							break
					_wahl_art = "menue"
					_wahl_zustand = "wahl"
					_liste_zeigen(_wahl_frage, liste)
			elif Spiel.ist_nethack() and zuletzt_controller and RegEx.create_from_string("\\[yn[aq]*\\]").search(m):
				_wahl_art = "janein"
				_wahl_zustand = "wahl"
				auswahl.zeigen(m.get_slice("[", 0).strip_edges(), [["Ja (y)", "y"], ["Nein (n)", "n"]])
			elif "really quit?" in m and zuletzt_controller:
				_wahl_art = "janein"
				_wahl_zustand = "wahl"
				auswahl.zeigen("Wirklich aufhören?", [["Nein, weiterspielen", "n"], ["Ja, Spiel beenden", "y"]])
		"liste":
			var liste := _eintraege_lesen()
			if not liste.is_empty():
				_wahl_art = "gegenstand"
				_wahl_zustand = "wahl"
				_liste_zeigen(_titel_aus_frage(_wahl_frage), liste)


## Auswahlliste zeigen; ist die Maus eingefangen, wird der Zeiger zum Anklicken frei.
func _liste_zeigen(titel: String, liste: Array) -> void:
	_maus_zurueck = maus_aktiv
	if maus_aktiv:
		maus_loslassen(false)
	auswahl.zeigen(titel, liste)


## Nach der Auswahl: Maus wieder einfangen, wenn sie vorher eingefangen war.
func _liste_zu() -> void:
	auswahl.visible = false
	_liste_zu_seit = _jetzt()
	if _maus_zurueck:
		_maus_zurueck = false
		maus_fangen()


func _eintraege_lesen() -> Array:
	var liste := []
	var re := RegEx.create_from_string("([a-z])\\) (.+)")
	if Spiel.ist_nethack():
		re = RegEx.create_from_string("(?:^|\\s)([a-zA-Z]) - (.+)")   # NetHack-Menüs: "a - Archeologist"
	for z in d.rogue.raster:
		var t: String = z.replace("--More--", "").replace("--Press space to continue--", "")
		var r := re.search(t)
		if r:
			liste.append([r.get_string(1) + ")  " + r.get_string(2).strip_edges(), r.get_string(1)])
	return liste


func _titel_aus_frage(f: String) -> String:
	for v in VERBEN:
		if ("to " + v + "?") in f or (v + " what") in f:
			return Sprache.frage_verb(v)
	return "Welchen Gegenstand?"


# ---------------------------------------------------------------- Hinweiszeile

func _hinweis_setzen(pad: int) -> void:
	var t := ""
	if _jetzt() < _kurz_bis:
		t = _kurz_text
	elif pad < 0:
		if fernzugriff and _jetzt() < 20.0:
			t = "Remotedesktop erkannt: zum Umsehen Maustaste gedrückt halten und ziehen"
	elif d.ende_meldung != "":
		t = ""
	elif auswahl.visible:
		t = "Hoch/Runter: auswählen     A: nehmen     B: abbrechen"
	elif d.fragt_richtung():
		t = "Linker Stick: Richtung wählen     B: abbrechen"
	elif "--More--" in d.meldung or d.textseite:
		t = "A: weiter     B: schließen"
	elif "call it" in d.meldung:
		t = "A: ohne Namen weiter     B: überspringen"
	elif not d.vr:
		t = tr("A: %s     X: suchen     Y: Inventar     Start: Befehle     Back: Hilfe") % tr("Treppe hinab" if d.auf_treppe() else "aufheben")
	# (in VR beim Laufen keine Tastenzeile: die Belegung ist dort anders, Peter 21.11.)
	if hinweis.text != t:
		hinweis.text = t
