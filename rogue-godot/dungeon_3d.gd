## Baut aus Rogues Zeichenraster einen 3D-Dungeon in Ego-Perspektive.
## Rogue selbst bleibt unverändert - hier wird nur gezeichnet und es werden Tasten weitergereicht.
##   - |  Wand        .  Boden      #  Gang       +  Tür
##   @    Kamera      A-Z Monster   ! ? ) ] = / * : ,  Gegenstände   % Treppe   ^ Falle
## Mitspieler: anzeigen.gd (2D-Anzeigen), platzhalter.gd (Figuren), grafik.gd (Aussehen),
## steuerung.gd (Maus, Controller, Tasten halten), vr.gd (VR).
extends Node3D

const RogueVerbindung = preload("res://rogue_verbindung.gd")
const Anzeigen = preload("res://anzeigen.gd")
const Platzhalter = preload("res://platzhalter.gd")
const Vorspann = preload("res://vorspann.gd")
const Protokoll = preload("res://protokoll.gd")
const Spiel = preload("res://spiel.gd")
const Sprache = preload("res://sprache.gd")
const Spielstand = preload("res://spielstand.gd")
const NethackUebersetzer = preload("res://nethack_uebersetzer.gd")
const Steuerung = preload("res://steuerung.gd")
const Grafik = preload("res://grafik.gd")
const Masse = preload("res://raster_masse.gd")

# Spielname, Jahr und Autoren stehen in spiel.gd (Rogue oder NetHack, je nach Startbefehl)
const ZELLE := Masse.ZELLE
const WANDHOEHE := Masse.WANDHOEHE
const AUGENHOEHE := 1.55
const GLEITZEIT := 0.14     # Sekunden für einen Schritt
const DREHZEIT := 0.18      # Sekunden für eine 90°-Drehung

# Blickrichtungen: 0 = Nord, 1 = Ost, 2 = Süd, 3 = West (Rasterzeile wächst nach Süden)
const RICHTUNGEN := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const RICHTUNG_TASTE := {
	Vector2i(0, -1): "k", Vector2i(1, 0): "l", Vector2i(0, 1): "j", Vector2i(-1, 0): "h",
	Vector2i(-1, -1): "y", Vector2i(1, -1): "u", Vector2i(-1, 1): "b", Vector2i(1, 1): "n",
}
const GELAENDE := "-|.#+%^wli"   # w l i: Wasser, Lava, Eis (nur NetHack, nethack_uebersetzer.gd)

var rogue := RogueVerbindung.new()
var nethack: NethackUebersetzer = NethackUebersetzer.new() if Spiel.ist_nethack() else null
var spieler := Node3D.new()
var kamera := Camera3D.new()
var figuren := Node3D.new()
var anzeigen: Anzeigen
var platzhalter := Platzhalter.new()
var grafik: Node3D       # grafik.gd: Texturen, Licht, Fackeln, Gegenstände, Monster
var steuerung: Node
var vr: Node3D = null    # VR-Modus (vr.gd), sonst null
var schichten := {}      # Name -> MultiMeshInstance3D (Wände, Böden ... je eine Schicht)
var gedaechtnis := {}    # Vector2i -> zuletzt gesehenes Geländezeichen (für Felder unter Monstern)
var ebene := ""
var feld := Vector2i(-9999, -9999)
var gier := 0.0          # Blickwinkel links/rechts (Bogenmaß, 0 = Nord, -PI/2 = Ost)
var nick := 0.0          # Blick hoch/runter
var meldung := ""        # oberste Zeile von Rogue
var textseite := false   # gerade wird eine Textseite (Inventar, Hilfe ...) gezeigt
var text_manuell := false   # F3: Original-Textbild von Hand eingeschaltet
var karte_an := true
var hud_aus := false     # F6: Werte und Karte ausgeblendet
var ende_meldung := ""
var monster_anzahl := 0
var gleit_linear_bis := 0.0
var ziel_marker: MeshInstance3D
var _gang_besucht := {}  # Gangfelder, auf denen der Spieler schon stand
var _gang_voraus := {}   # Gangfelder aus dem Fühler, die Rogue noch nicht zeigt -> Tiefe
var _gleiten: Tween
var _drehen: Tween
var _more_uhr := 0.1


func _ready() -> void:
	Sprache.einrichten()
	grafik = Grafik.new()
	add_child(grafik)
	platzhalter.grafik = grafik
	_umgebung_bauen()
	_schichten_bauen()
	add_child(figuren)
	kamera.position.y = AUGENHOEHE
	kamera.fov = 75.0
	kamera.near = 0.05
	spieler.add_child(kamera)
	spieler.add_child(grafik.licht_fuer_spieler())
	add_child(spieler)
	kamera.make_current()
	anzeigen = Anzeigen.new()
	add_child(anzeigen)
	rogue.bild_geaendert.connect(_bild_neu)
	rogue.beendet.connect(_rogue_beendet)
	steuerung = Steuerung.new()
	steuerung.d = self
	add_child(steuerung)
	_ziel_marker_bauen()
	vr = preload("res://vr.gd").new()
	add_child(vr)
	if not vr.starten(self):
		vr.queue_free()
		vr = null
	Vorspann.zeigen(anzeigen, Spiel.wert("name_vr" if vr else "name"), Spiel.wert("original"),
			Spiel.wert("autoren"), Spiel.wert("musik"))
	_rogue_starten()
	if "--selbsttest" in OS.get_cmdline_user_args():
		load("res://werkzeuge/selbsttest.gd").laufen(self)
	if "--nethacktest" in OS.get_cmdline_user_args():
		load("res://werkzeuge/nethack_test.gd").laufen(self)
	if "--spielstandtest" in OS.get_cmdline_user_args():
		load("res://werkzeuge/spielstand_test.gd").laufen(self)


# ---------------------------------------------------------------- Aufbau der Szene

func _umgebung_bauen() -> void:
	var env := Grafik.umgebung()
	grafik.umwelt = env
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _schichten_bauen() -> void:
	var wand := BoxMesh.new()
	wand.size = Vector3(ZELLE, WANDHOEHE, ZELLE)
	var platte := PlaneMesh.new()
	platte.size = Vector2(ZELLE, ZELLE)
	var sturz := BoxMesh.new()
	sturz.size = Vector3(ZELLE, 0.45, ZELLE)
	var mats: Dictionary = grafik.materialien(1)
	_schicht("wand", wand, mats["wand"])
	_schicht("fels", wand, mats["fels"])
	_schicht("boden", platte, mats["boden"])
	_schicht("gang", platte, mats["gang"])
	_schicht("decke", platte, mats["decke"])
	_schicht("tuer", sturz, mats["tuer"])
	var fluessig: Dictionary = preload("res://grafik/fluessig.gd").materialien()
	for name in fluessig:
		_schicht(name, platte, fluessig[name])


func _schicht(name: String, mesh: Mesh, mat: Material) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	add_child(mmi)
	schichten[name] = mmi


## Neue Ebene: andere Wände und Böden, Fackeln neu verteilen.
func _grafik_ebene(nr: int) -> void:
	grafik.ebene_neu()
	grafik.zwischenspeicher_leeren()
	var mats: Dictionary = grafik.materialien(nr)
	for name in mats:
		schichten[name].material_override = mats[name]


# Leuchtendes Feld auf dem Boden: zeigt, wohin "vorwärts" gerade führt.
func _ziel_marker_bauen() -> void:
	var platte := PlaneMesh.new()
	platte.size = Vector2(ZELLE * 0.8, ZELLE * 0.8)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.85, 0.3, 0.16)
	ziel_marker = MeshInstance3D.new()
	ziel_marker.mesh = platte
	ziel_marker.material_override = m
	ziel_marker.visible = false
	add_child(ziel_marker)


# ---------------------------------------------------------------- Rogue starten und beenden

func _rogue_starten(argumente: Array = []) -> void:
	ende_meldung = ""
	anzeigen.ende_kasten.visible = false
	ebene = ""
	gedaechtnis.clear()
	_gang_besucht.clear()
	_gang_voraus.clear()
	grafik.neues_spiel()
	if nethack:
		nethack.zuruecksetzen()
		# Wie bei Rogue ("Hello admin"): Windows-Benutzername als Spielername, sonst fragt NetHack "Who are you?"
		if OS.get_environment("NETHACKOPTIONS") == "":
			# number_pad:0 = Laufen mit h j k l y u b n wie bei Rogue (die Windows-Vorlage stellt sonst den Ziffernblock ein,
			# dann heißt l "Loot", Protokoll 21.11.); ohne Lebensbalken im Namen; Gold automatisch aufheben
			OS.set_environment("NETHACKOPTIONS", "name:" + OS.get_environment("USERNAME")
					+ ",number_pad:0,!hitpointbar,time,showexp,autopickup,pickup_types:$")
	var pfad := ProjectSettings.globalize_path("res://").path_join("../bruecke/rogue-bruecke.exe").simplify_path()
	var programm := Spiel.programm_pfad()
	if programm == "" and not argumente.is_empty():
		programm = ProjectSettings.globalize_path("res://").path_join("../build/rogue.exe").simplify_path()
	rogue.starten(pfad, programm, argumente)


func _rogue_beendet(m: String) -> void:
	if _speichern_platz > 0:
		# Das Spiel hat sich zum Speichern beendet: Datei in den Platz legen und gleich weiterspielen
		var platz := _speichern_platz
		_speichern_platz = 0
		var ok := Spielstand.in_platz_legen(platz, _speichern_ebene)
		Protokoll.notiz("Speichern in Platz %d: %s" % [platz, "ok" if ok else "FEHLER, keine Spielstand-Datei"])
		if ok:
			_rogue_starten(Spielstand.lade_argumente())
			steuerung.kurz_zeigen(tr("Gespeichert in Platz %d - weiter geht's") % platz)
			return
	ende_meldung = m
	Protokoll.notiz("Spielende: " + m)
	steuerung.maus_loslassen(false)
	anzeigen.ende_zeigen(m + tr("\n\nEnter / A = neues Spiel     Esc / B = Programm beenden"))


var _speichern_platz := 0   # > 0: das Spiel speichert gerade für diesen Platz (spielstand.gd)
var _speichern_ebene := ""


## Speichern in Platz 1-3: der eigene Speicherbefehl des Spiels (S, dann y), danach geht es sofort weiter.
func speichern(platz: int) -> void:
	if ende_meldung != "" or not rogue.laeuft:
		return
	_speichern_platz = platz
	_speichern_ebene = ebene.get_slice("/", 0)
	rogue.taste(ord("S"))
	await get_tree().create_timer(0.4).timeout
	if nethack:
		rogue.taste(ord("y"))   # NetHack: "Really save? [yn]"
	else:
		# Rogue: "save file (Dokumente/rogue.save)?" -> n, dann eigenen Dateinamen tippen (spielstand.gd)
		var datei := Spielstand.spieldatei()
		DirAccess.make_dir_recursive_absolute(datei.get_base_dir())
		if FileAccess.file_exists(datei):
			DirAccess.remove_absolute(datei)
		rogue.taste(ord("n"))
		await get_tree().create_timer(0.3).timeout
		for c in Spielstand.ROGUE_DATEI:   # nur der Name: Rogue speichert in seinem eigenen Ordner
			rogue.taste(c.unicode_at(0))
		rogue.taste(13)
	await get_tree().create_timer(4.0).timeout
	if _speichern_platz == platz and rogue.laeuft:
		_speichern_platz = 0   # das Spiel hat nicht gespeichert (z. B. eine andere Frage stand offen)
		steuerung.kurz_zeigen("Speichern ging gerade nicht - bitte nochmal versuchen")


## Laden aus Platz 1-3: laufendes Spiel ohne Speichern beenden, Stand zurücklegen, neu starten.
func laden(platz: int) -> void:
	if not Spielstand.belegt(platz):
		steuerung.kurz_zeigen(tr("Platz %d ist leer") % platz)
		return
	rogue.stoppen()
	await get_tree().create_timer(0.8).timeout   # bis das Spiel wirklich beendet ist
	if nethack and not Spielstand.nethack_sperren_weg():
		steuerung.kurz_zeigen("Laden ging nicht: ein anderes NetHack läuft noch")
		_rogue_starten()
		return
	if not Spielstand.aus_platz_holen(platz):
		steuerung.kurz_zeigen(tr("Laden ging nicht (Platz %d)") % platz)
		return
	Protokoll.notiz("Laden aus Platz %d" % platz)
	_rogue_starten(Spielstand.lade_argumente())
	steuerung.kurz_zeigen(tr("Platz %d geladen") % platz)


func neu_starten() -> void:
	_rogue_starten()
	steuerung.maus_fangen()


func _exit_tree() -> void:
	rogue.stoppen()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		rogue.stoppen()


# ---------------------------------------------------------------- Rogue-Bild auswerten

## NetHack: Menü, Inventar oder Textseite liegt über der Karte? ("(end)" oder "(1 of 2)")
func _nethack_textseite(r: PackedStringArray) -> bool:
	var seite := RegEx.create_from_string("\\(\\d+ of \\d+\\)")
	for z in r:
		if "(end)" in z or seite.search(z):
			return true
	return false


func _bild_neu() -> void:
	var r := rogue.raster
	var roh := r   # NetHack: unübersetztes Bild für Textseiten
	if r.size() < 3:
		return
	var a := anzeigen
	# Statuszeile ("Level: 1  Gold: 0 ..." bzw. bei NetHack "Dlvl:1 $:0 ...") von unten her suchen
	var status_zeile := r.size() - 1
	var status_wort := Spiel.wert("status")
	for i in range(r.size() - 1, 0, -1):
		if status_wort in r[i]:
			status_zeile = i
			break
	meldung = r[0].strip_edges()
	a.meldung_merken(meldung)
	a.status_label.text = r[status_zeile].strip_edges()
	var karte_bis := status_zeile   # Kartenzeilen: 1 .. karte_bis-1
	if nethack:
		# NetHack hat zwei Statuszeilen (Name und Werte, darunter Ebene und Gold)
		karte_bis = status_zeile - 1
		a.status_label.text = (r[status_zeile - 1].strip_edges() + "\n" + r[status_zeile].strip_edges()).strip_edges()
		r = nethack.uebersetzen(r, karte_bis)
	a.status_kasten.visible = a.status_label.text != ""
	Protokoll.bild(meldung, a.status_label.text.replace("\n", "  "))

	var at := Vector2i(-1, -1)
	for y in range(1, karte_bis):
		var x := r[y].find("@")
		if x >= 0:
			at = Vector2i(x, y)
			break
	# Inventar, Hilfe, Grabstein usw. sind Textseiten -> Originalbild zeigen
	var menue := at.x < 0
	for z in r:
		if "Press space" in z:
			menue = true
	if nethack and (not nethack.gueltig or _nethack_textseite(roh)):
		menue = true
	textseite = menue
	a.volltext.visible = (menue or text_manuell) and not steuerung.auswahl.visible   # Auswahlliste statt Textseite (Peter 22.11.)
	# Über der Textseite stören Karte und Zeilen-Einblendungen nur
	a.karte.visible = karte_an and not a.volltext.visible and not hud_aus
	a.meldung_kasten.visible = a.meldung_kasten.visible and not a.volltext.visible
	a.status_kasten.visible = a.status_kasten.visible and not a.volltext.visible and not hud_aus
	a.volltext.zeigen(roh if menue else r, rogue.spalten, 0, -1, at, gier)
	a.karte.zeigen(r, rogue.spalten, 1, karte_bis - 1, at, spieler.rotation.y)
	if menue:
		return

	var neue_ebene := false
	var treffer := RegEx.create_from_string(Spiel.wert("ebene")).search(r[status_zeile])
	var e := treffer.get_string(1) if treffer else ""
	if nethack:
		e += "/" + str(nethack.zweig)   # gleiche Tiefe, anderer Zweig (Minen, Sokoban ...) = neue Ebene
		grafik.zweig = nethack.zweig
	if e != ebene:
		ebene = e
		gedaechtnis.clear()
		_gang_besucht.clear()
		_gang_voraus.clear()
		neue_ebene = true
		_grafik_ebene(e.get_slice("/", 0).to_int())
	grafik.meldung_auswerten(meldung, at)
	grafik.treffer_pruefen(meldung)
	_gang_besucht[at] = true
	_dungeon_bauen(r, karte_bis)
	grafik.monster_fertig(at)
	grafik.fackeln_aktualisieren(gedaechtnis)
	_spieler_setzen(at, neue_ebene)


## Füllt die Schichten (Wände, Böden ...) neu und stellt Figuren und Monster auf.
func _dungeon_bauen(r: PackedStringArray, status_zeile: int) -> void:
	var teile := {"wand": [], "fels": [], "boden": [], "gang": [], "decke": [], "tuer": [], "wasser": [], "lava": [], "eis": []}
	var belegt := {}
	var gaenge := []
	monster_anzahl = 0
	for k in figuren.get_children():
		k.free()
	grafik.monster_beginnen()
	for y in range(1, status_zeile):
		var zeile := r[y]
		for x in zeile.length():
			var c := zeile[x]
			if c == " ":
				continue
			var p := Vector2i(x, y)
			belegt[p] = true
			var grund := c
			if c in GELAENDE:
				gedaechtnis[p] = c
			else:
				grund = gedaechtnis.get(p, ".")
			match grund:
				"-", "|":
					teile["wand"].append(_t(p, WANDHOEHE / 2.0))
				"#":
					teile["gang"].append(_t(p, 0.0))
					teile["decke"].append(_decke(p))
					gaenge.append(p)
				"%":
					teile["decke"].append(_decke(p))  # kein Boden: hier führt die Treppe hinab (grafik/gegenstaende.gd)
				"+":
					teile["boden"].append(_t(p, 0.0))
					teile["decke"].append(_decke(p))
					teile["tuer"].append(_t(p, WANDHOEHE - 0.225))
				"w", "l", "i":
					teile[{"w": "wasser", "l": "lava", "i": "eis"}[grund]].append(_t(p, -0.04 if grund != "i" else 0.0))
					teile["decke"].append(_decke(p))
				_:
					teile["boden"].append(_t(p, 0.0))
					teile["decke"].append(_decke(p))
			if grund == "%" or grund == "^":
				figuren.add_child(platzhalter.bauen(grund, p))
			if not (c in GELAENDE) and c != "@":
				var ist_monster := c >= "A" and c <= "Z"
				if nethack:
					# NetHack: Monster ("M") mit echtem Namen -> 3D-Figur oder Bild (grafik/monster.gd), sonst Platzhalter
					var nh_name: String = nethack.monster_namen.get(p, "")
					if not (ist_monster and nh_name != "" and grafik.monster_melden("", p, nh_name)):
						figuren.add_child(platzhalter.bauen(c, p, nh_name))
				elif not (ist_monster and grafik.monster_melden(c, p)):  # Monster mit Bild zeichnet grafik.gd
					figuren.add_child(platzhalter.bauen(c, p))
				if ist_monster:
					monster_anzahl += 1
			if nethack and nethack.besonders.has(p) and c in GELAENDE:
				figuren.add_child(platzhalter.bauen("~", p, nethack.besonders[p]))
	# Gang voraus, den Rogue noch nicht zeigt: Boden und Decke, das Ende verliert sich im Schwarzen
	grafik.gang_voraus_lesen(_gang_voraus)
	for p: Vector2i in _gang_voraus:
		if not belegt.has(p):
			belegt[p] = true
			teile["gang"].append(_t(p, 0.0))
			teile["decke"].append(_decke(p))
	# Gänge bekommen Felswände ringsum, damit sie wie Tunnel aussehen
	var fels := {}
	for p in gaenge:
		if _gang_besucht.has(p):   # noch nicht dort gewesen: dahinter bleibt es schwarz statt Sackgasse
			_fels_ringsum(p, belegt, fels, teile)
	for p: Vector2i in _gang_voraus:
		if _gang_voraus[p] < 4:    # letztes Stück bleibt offen, damit es nicht wie eine Sackgasse aussieht
			_fels_ringsum(p, belegt, fels, teile)
	for name in teile:
		var mm: MultiMesh = schichten[name].multimesh
		var liste: Array = teile[name]
		mm.instance_count = liste.size()
		for i in liste.size():
			mm.set_instance_transform(i, liste[i])


func _fels_ringsum(p: Vector2i, belegt: Dictionary, fels: Dictionary, teile: Dictionary) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var q: Vector2i = p + Vector2i(dx, dy)
			if not belegt.has(q) and not fels.has(q):
				fels[q] = true
				teile["fels"].append(_t(q, WANDHOEHE / 2.0))


func _t(p: Vector2i, hoehe: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(p.x * ZELLE, hoehe, p.y * ZELLE))


func _decke(p: Vector2i) -> Transform3D:
	return Transform3D(Basis(Vector3.RIGHT, PI), Vector3(p.x * ZELLE, WANDHOEHE, p.y * ZELLE))


# ---------------------------------------------------------------- Kamera

func _spieler_setzen(at: Vector2i, neue_ebene: bool) -> void:
	var ziel := Vector3(at.x * ZELLE, 0, at.y * ZELLE)
	var weit := maxi(absi(at.x - feld.x), absi(at.y - feld.y)) > 2
	feld = at
	if _gleiten:
		_gleiten.kill()
	if neue_ebene:
		_blick_waehlen(at)
	if neue_ebene or weit:
		spieler.position = ziel  # Teleport / neue Ebene: springen statt gleiten
	else:
		_gleiten = create_tween()
		if Time.get_ticks_msec() / 1000.0 < gleit_linear_bis:
			# Dauerlaufen: gleichmäßig gleiten, damit die Schritte ineinander übergehen
			_gleiten.tween_property(spieler, "position", ziel, Steuerung.TAKT)
		else:
			_gleiten.tween_property(spieler, "position", ziel, GLEITZEIT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Auf einer neuen Ebene in die Richtung schauen, in der am meisten Platz ist.
func _blick_waehlen(at: Vector2i) -> void:
	var bester := 0
	var weiteste := -1
	for i in 4:
		var d: Vector2i = RICHTUNGEN[i]
		var n := 0
		var q := at + d
		while gedaechtnis.get(q, "-") in ".#+%^" and n < 40:
			n += 1
			q += d
		if n > weiteste:
			weiteste = n
			bester = i
	gier = -bester * PI / 2.0
	nick = 0.0
	kamera.rotation.x = 0.0
	if _drehen:
		_drehen.kill()
	spieler.rotation.y = gier


## Dreht um 90°-Schritte (rastet dabei auf die nächste Himmelsrichtung ein).
func drehen_um(schritte: int) -> void:
	gier = snappedf(gier, PI / 2.0) - schritte * PI / 2.0
	if vr:
		spieler.rotation.y = gier   # in VR ohne Schwenk drehen, sonst wird einem schlecht
		return
	if _drehen:
		_drehen.kill()
	_drehen = create_tween()
	_drehen.tween_property(spieler, "rotation:y", gier, DREHZEIT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Freies Umsehen mit Maus oder rechtem Stick (Winkel in Bogenmaß).
func umsehen(d_gier: float, d_nick: float) -> void:
	if _drehen and _drehen.is_running():
		_drehen.kill()
		gier = spieler.rotation.y
	gier = wrapf(gier + d_gier, -PI, PI)
	nick = clampf(nick + d_nick, -1.2, 1.2)
	spieler.rotation.y = gier
	kamera.rotation.x = nick


func blick_geradeaus() -> void:
	nick = 0.0
	kamera.rotation.x = 0.0
	drehen_um(0)


## Welches Nachbarfeld ist gemeint? rel = (rechts, vorwärts) relativ zum Blick.
## Ergebnis ist eine der 8 Rogue-Richtungen.
func richtung_fuer(rel: Vector2i) -> Vector2i:
	var g: float = gier + (vr.kopf_gier() if vr else 0.0)   # in VR zählt, wohin der Kopf schaut
	var vor := Vector2(-sin(g), -cos(g))
	var rechts := Vector2(cos(g), -sin(g))
	var w := vor * rel.y + rechts * rel.x
	var k := roundi(atan2(w.y, w.x) / (PI / 4.0))
	return Vector2i(roundi(cos(k * PI / 4.0)), roundi(sin(k * PI / 4.0)))


# ---------------------------------------------------------------- Befehle an Rogue

## Ein Schritt (oder mit laufen = Rogue rennt). fluessig = Teil des Dauerlaufens.
func schritt(rel: Vector2i, laufen: bool, fluessig: bool) -> void:
	if fluessig:
		gleit_linear_bis = Time.get_ticks_msec() / 1000.0 + Steuerung.TAKT * 2.0
	var t: String = RICHTUNG_TASTE[richtung_fuer(rel)]
	rogue.taste(ord(t.to_upper() if laufen else t))


## Antwort auf "which direction?" (z. B. beim Werfen oder Zaubern).
func richtung_senden(rel: Vector2i) -> void:
	rogue.taste(ord(RICHTUNG_TASTE[richtung_fuer(rel)]))


func taste_senden(code: int) -> void:
	anzeigen.hilfe_kasten.visible = false
	if _speichern_gesperrt(code):
		return
	rogue.taste(code)


## In VR kam mehrmals ungewollt Rogues Speichern-Frage (Taste S, beendet das Spiel nach dem Speichern).
func _speichern_gesperrt(code: int) -> bool:
	if vr and code == ord("S"):
		print("VR: Taste S (Speichern) blockiert, Herkunft: ", get_stack())
		return true
	# Enter ist für Rogue kein Befehl ("Illegal command '^M'"), nur bei Fragen und Textseiten erlaubt
	if vr and (code == 13 or code == 10) and not (textseite or "?" in meldung or ":" in meldung or "--More--" in meldung):
		print("VR: Enter blockiert, Herkunft: ", get_stack())
		return true
	return false


func fragt_richtung() -> bool:
	return "direction" in meldung.to_lower()


## Erwartet Rogue gerade getippte Buchstaben (Gegenstand wählen, Namen eingeben ...)?
## Dann sind W/A/S/D Buchstaben und keine Laufrichtungen.
func texteingabe_aktiv() -> bool:
	return textseite or Steuerung.liste_frage(meldung) or "call it" in meldung or "--More--" in meldung \
			or (nethack != null and ("[yn" in meldung or "What do you want to" in meldung)) \
			or "really quit" in meldung


## Wartet das Spiel auf Text oder eine Antwort (--More--, Liste, Frage, #-Befehl)?
func _frage_offen() -> bool:
	var m := meldung.strip_edges()
	return texteingabe_aktiv() or m.begins_with("#") or m.ends_with("?") or m.ends_with(":") or m.ends_with("]")


func auf_treppe() -> bool:
	return gedaechtnis.get(feld, "") == "%"


func karte_umschalten() -> void:
	karte_an = not karte_an
	anzeigen.karte.visible = karte_an and not anzeigen.volltext.visible and not hud_aus


## Werte und Karte aus/ein (F6, in VR linker Stick drücken). Die Leertaste bleibt fürs Wegklicken der Infofenster.
func hud_umschalten() -> void:
	hud_aus = not hud_aus
	anzeigen.status_kasten.visible = not hud_aus and anzeigen.status_label.text != ""
	anzeigen.karte.visible = karte_an and not anzeigen.volltext.visible and not hud_aus


func textbild_umschalten() -> void:
	text_manuell = not text_manuell
	_bild_neu()


# ---------------------------------------------------------------- jedes Bild

func _process(delta: float) -> void:
	anzeigen.meldungen_altern(delta, meldung.ends_with("?") or "direction" in meldung.to_lower() or "(*" in meldung)
	# --More-- wird automatisch bestätigt, die Texte bleiben ja ein paar Sekunden stehen
	# (NetHack: "Restoring save file...--More--" nach dem Laden ebenfalls, das Bild davor gilt als Textseite)
	if "--More--" in meldung and (not textseite or "Restoring save file" in meldung) and ende_meldung == "":
		_more_uhr -= delta
		if _more_uhr <= 0.0:
			_more_uhr = 0.3
			taste_senden(32)
	else:
		_more_uhr = 0.1
	# Kartenpfeil folgt dem Blick
	var karte := anzeigen.karte
	if karte.visible and absf(karte.blick - spieler.rotation.y) > 0.01:
		karte.blick = spieler.rotation.y
		karte.queue_redraw()


# ---------------------------------------------------------------- Tastatur

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	get_viewport().set_input_as_handled()
	if event.is_echo():
		return   # gehaltene Taste: Windows wiederholt sie, für Rogue wäre jede Wiederholung ein Zug (Peter 21.11.)
	var k := event as InputEventKey
	_taste(k.keycode, k.shift_pressed, k.ctrl_pressed, k.unicode, k.physical_keycode)


func _taste(keycode: int, _umschalt: bool, strg: bool, unicode: int, physisch := KEY_NONE) -> void:
	if ende_meldung != "":
		if keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
			neu_starten()
		elif keycode == KEY_ESCAPE or keycode == KEY_B:
			rogue.stoppen()
			get_tree().quit()
		return
	match keycode:
		KEY_F1:
			anzeigen.hilfe_kasten.visible = not anzeigen.hilfe_kasten.visible
			return
		KEY_F2:
			karte_umschalten()
			return
		KEY_F3:
			textbild_umschalten()
			return
		KEY_F5:
			steuerung.wasd_umschalten()
			return
		KEY_F6:
			hud_umschalten()
			return
		KEY_KP_5:
			rogue.taste(ord("."))  # Ziffernblock-Mitte: eine Runde ausruhen
			return
		KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_6, KEY_KP_7, KEY_KP_8, KEY_KP_9:
			return  # Ziffernblock-Bewegung macht steuerung.gd
		KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_HOME, KEY_END, KEY_PAGEUP, KEY_PAGEDOWN, KEY_SHIFT, KEY_CTRL, KEY_ALT:
			return  # Bewegung macht steuerung.gd (mit Gedrückthalten)
	anzeigen.hilfe_kasten.visible = false

	# W/A/S/D: Laufen - außer Rogue erwartet gerade Buchstaben. Strg+W/A/S/D = Rogues eigene Befehle.
	if steuerung.wasd_modus and physisch in [KEY_W, KEY_A, KEY_S, KEY_D]:
		if strg:
			rogue.taste(ord(char(keycode).to_lower()))
			return
		if not texteingabe_aktiv():
			return

	var code := 0
	match keycode:
		KEY_ESCAPE: code = 27
		KEY_ENTER, KEY_KP_ENTER: code = 13
		KEY_BACKSPACE: code = 8
	if code == 0 and strg and keycode >= KEY_A and keycode <= KEY_Z:
		code = keycode - KEY_A + 1  # Strg+A..Z
	if code == 0 and unicode > 0 and unicode < 128:
		code = unicode
	if code == ord("i") and textseite:
		code = 32   # i öffnet das Inventar und schließt es auch wieder (Peter 21.11.)
	elif code == 32 and not _frage_offen():
		code = ord(",")   # Leertaste auf der Karte: aufheben (Peter 22.11.); bei --More--/Fragen bleibt sie Leertaste
	if code != 0 and not _speichern_gesperrt(code):
		rogue.taste(code)
