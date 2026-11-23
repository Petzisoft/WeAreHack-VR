## Monster-Galerie (Peter 22.11.2026): ein langer Saal, in dem die 3D-Monster in einer Reihe stehen,
## damit Peter Größe, Licht und Stand auf dem Boden am Monitor und in VR abnehmen kann.
## Drei Säle (Start-Argument --spiel=...):
##   rogue   (Standard) die 26 Rogue-Monster, eine Reihe rechts vom Weg
##   hack    alle Figuren aus hack-monster/3d, zwei Reihen (links und rechts)
##   nethack alle Figuren aus nethack-monster/3d, zwei Reihen (sehr langer Saal, Figuren laden beim Näherkommen)
## Die Monster kommen aus demselben Code wie im Spiel (grafik/monster.gd): gleiche Größe, gleiches Material
## (auch Glas/Geist), gleiches Atmen; alle schauen fest zum Weg, nicht dir nach. Größe der Hack-/NetHack-Figuren
## aus nethack-monster/monster_namen.txt wie im Spiel (höchstens 3 m).
## Licht: wie im Spiel nur die Fackel in deiner Hand. Mit L (VR: rechter Abzug) Arbeitslicht an/aus.
##
## Monitor: WASD oder Pfeiltasten gehen, Maus schauen, Umschalt rennen, Bild auf/ab = zum nächsten Monster springen,
##          (auch N/V), Pos1/Ende = Anfang/Ende des Saals, L Arbeitslicht, Esc Maus frei, B beenden.
## VR:      linker Stick gehen (Blickrichtung), rechter Stick links/rechts 90° drehen, rechter Griff rennen,
##          rechter Abzug Arbeitslicht, A/B nächstes/voriges Monster.
## Aufstellen (Peter 22.11.: "ein Werkzeug, um die Figuren richtig hinzustellen"): T schaltet es für die Figur ein,
##          die du ansiehst. Tasten halten: Pfeil hoch/runter nach vorn/hinten kippen, links/rechts zur Seite kippen
##          (12°/s), Q/E drehen (30°/s), R/F heben/senken (5 cm/s, auch +/-), I/K/J/L verschieben (in deiner Blickrichtung,
##          25 cm/s); Umschalt dreifach, Strg fein (1/5). Z zurück auf den Ausgangswert, T fertig.
##          VR: linker Griff ein/aus, rechter Stick kippen, linker Stick drehen und heben, mit rechtem Griff verschieben.
##          Jede Änderung steht sofort in grafik/aufstellung.txt und gilt auch im Spiel (monster.gd liest die Datei).
## Start:   monster-galerie-*.bat, hack-galerie-*.bat, nethack-galerie-*.bat
## Test:    ... res://werkzeuge/monster_galerie.tscn -- --spiel=hack --fotos  (Fotos grafik-test/galerie_*.png, dann Ende)
##          ... -- --spiel=hack --portraits [--nur=s_Skorpion,n_Krankenschwester] [--tief|--weit]  je Figur allein ein Foto frontal und eins
##          genau von der Seite (Kamera 1,6 m hoch, 4 m Abstand, Arbeitslicht) nach grafik-test/portraits/, dann Ende
extends Node3D

const Grafik = preload("res://grafik.gd")
const Monster = preload("res://grafik/monster.gd")
const ModellHilfe = preload("res://grafik/modell_hilfe.gd")

const ABSTAND := 4.0        # Meter zwischen zwei Plätzen einer Reihe
const REIHE_X := 1.6        # eine Reihe: die Monster stehen rechts vom Weg
const WEG_X1 := -1.4        # eine Reihe: hier gehst du
const REIHE_X2 := 2.2       # zwei Reihen: links und rechts, du gehst in der Mitte
const BREITE1 := 7.0
const BREITE2 := 8.0
const WANDHOEHE := 4.5      # höher als im Spiel, damit Drache (3 m) und Jabberwock Platz haben
const AUGENHOEHE := 1.55    # wie im Spiel (dungeon_3d.gd)
const GEHEN := 3.1          # m/s (Peter 22.11.: "etwas schneller", vorher 2,2)
const RENNEN := 8.4         # vorher 6,0 (Peter: etwas schneller, nicht übertreiben)
const MAUS := 0.0025
const NAH := 26.0           # Figuren näher als das sind geladen (lange Säle)

const DEUTSCH := {
	"A": "Aquator", "B": "Fledermaus", "C": "Zentaur", "D": "Drache", "E": "Emu", "F": "Venusfliegenfalle",
	"G": "Greif", "H": "Hobgoblin", "I": "Eismonster", "J": "Jabberwock", "K": "Turmfalke",
	"L": "Kobold", "M": "Medusa", "N": "Nymphe", "O": "Ork", "P": "Phantom", "Q": "Quagga",
	"R": "Klapperschlange", "S": "Schlange", "T": "Troll", "U": "Schwarzes Einhorn", "V": "Vampir",
	"W": "Wraith", "X": "Xeroc", "Y": "Yeti", "Z": "Zombie",
}

var spiel := "rogue"
var g: Node3D
var spieler := Node3D.new()
var kamera: Camera3D
var arbeitslicht: Node3D
var gier := 0.0
var nick := 0.0
var vr := false
var origin: XROrigin3D
var xr_cam: XRCamera3D
var links: XRController3D
var rechts: XRController3D
var _vorher := {}
var eintraege: Array = []   # {c (Kennung), titel, unter, meter, ort}
var geladen := {}           # Index -> Monster-Eintrag aus monster.gd
var zwei_reihen := false
var plaetze := 0            # Plätze pro Reihe
var laenge := 0.0
var breite := BREITE1
var weg_x := WEG_X1
var aufstellen := -1        # Index der Figur, die gerade aufgestellt wird (-1 = aus)
var _aufst_label: Label
var _aufst_marke: MeshInstance3D
var _aufst_hilfe: PanelContainer   # großes Tastenfeld unten links, solange T an ist
var _aufst_klein: Label            # "T = Figur aufstellen", solange T aus ist
var _maus_l := false
var _maus_r := false
var _rad_zeit := 0.0               # nach dem Mausrad kurz warten, dann speichern   # leuchtend grüner Ring unter der Figur, die gerade aufgestellt wird
var _aufst_d := {}          # laufende Änderung, noch nicht gespeichert: kipp (Vector3 Grad), hoch (cm), schieb (Vector2 m Welt)
var _portraits := false     # Porträt-Fotos laufen: nichts nachladen
# Für Aufnahmen (werkzeuge/reddit_aufnahme.gd): vor dem Einhängen setzen
var nur: Array = []         # nur diese Kennungen ("nh:D_RoterDrache" ...), in dieser Reihenfolge
var englisch := false       # Schilder nur mit dem englischen Originalnamen


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--spiel="):
			spiel = a.substr(8)
	_eintraege_lesen()
	if not nur.is_empty():
		var nach := {}
		for e in eintraege:
			nach[e.c] = e
		eintraege = nur.filter(func(c): return nach.has(c)).map(func(c): return nach[c])
	zwei_reihen = eintraege.size() > 30 or not nur.is_empty()
	breite = BREITE2 if zwei_reihen else BREITE1
	weg_x = 0.0 if zwei_reihen else WEG_X1
	plaetze = ceili(eintraege.size() / 2.0) if zwei_reihen else eintraege.size()
	laenge = plaetze * ABSTAND + 6.0
	for i in eintraege.size():
		eintraege[i].ort = _ort(i)
	print("Galerie ", spiel, ": ", eintraege.size(), " Figuren")
	g = Grafik.new()
	g.fuehler.fest = true
	g.monster.roh_merken = true   # Aufstellen: Datei nicht bei jedem Neuaufbau neu laden
	g.fuehler.aktiv = true
	add_child(g)
	var we := WorldEnvironment.new()
	we.environment = Grafik.umgebung()
	add_child(we)
	g.umwelt = we.environment
	g.zweig = 1 if spiel == "nethack" else -1           # NetHack: Gehennom-Optik, Hack: Gruft, Rogue: Verlies
	_saal_bauen(g.materialien(12 if spiel == "rogue" else 20))
	_schilder()
	add_child(spieler)
	spieler.position = Vector3(weg_x, 0, 2.0)
	spieler.add_child(g.licht_fuer_spieler())
	g.spieler_licht.light_color = g.thema.licht
	g.spieler_licht.omni_range = g.thema.reichweite
	_arbeitslicht_bauen()
	if not _vr_starten():
		kamera = Camera3D.new()
		kamera.position.y = AUGENHOEHE
		kamera.fov = 75.0
		kamera.near = 0.05
		spieler.add_child(kamera)
		kamera.make_current()
		gier = 0.0 if zwei_reihen else -0.35
		spieler.rotation.y = gier
		if not "--fotos" in OS.get_cmdline_user_args() and nur.is_empty():
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_hinweis()
	if "--fotos" in OS.get_cmdline_user_args():
		_fotos_machen()
	elif "--portraits" in OS.get_cmdline_user_args():
		_portraits_machen()


# ---------------------------------------------------------------- Welche Figuren?

func _eintraege_lesen() -> void:
	if spiel == "rogue":
		var bs: Array = Monster.MONSTER_GROESSE.keys()
		bs.sort()
		for c in bs:
			eintraege.append({"c": c, "titel": "%s  %s" % [c, DEUTSCH.get(c, "")], "unter": Monster.ROGUE_NAMEN[c],
					"meter": float(Monster.MONSTER_GROESSE[c])})
		return
	var ordner := "hack-monster" if spiel == "hack" else "nethack-monster"
	var vorsilbe := "hk:" if spiel == "hack" else "nh:"
	# englischer Name und Größe wie im Spiel (monster_namen.txt), deutscher Name aus den Bildtexten
	var info := {}
	for z in FileAccess.get_file_as_string(_wah("nethack-monster/monster_namen.txt")).split("\n", false):
		var t := z.strip_edges().split("|")
		if not z.begins_with("#") and t.size() >= 4:
			info[t[2]] = [t[0], minf(float(t[3]), 3.0)]
	var deutsch := {}
	for z in FileAccess.get_file_as_string(_wah("nethack-monster/nethack_texte.txt")).split("\n", false):
		var t := z.strip_edges().split("|")
		if not z.begins_with("#") and t.size() >= 4:
			deutsch[t[1]] = t[3]
	var dateien: Array = Array(DirAccess.get_files_at(_wah(ordner + "/3d"))).filter(func(f): return f.ends_with(".glb"))
	dateien.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
	for f in dateien:
		var key: String = f.get_basename()
		var e: Array = info.get(key, [])
		var name_de: String = deutsch.get(key, _aus_schluessel(key))
		var meter: float = Monster.GROESSE_PETER.get(vorsilbe + key, maxf(e[1] if e else 1.8, Monster.MINDESTGROESSE))
		eintraege.append({"c": vorsilbe + key, "titel": name_de, "unter": (e[0] if e else "(nicht im Spiel zugeordnet)"),
				"meter": meter, "geschaetzt": e.is_empty()})


## "d_Hoellenhund" -> "Hoellenhund", "a_SoldatenAmeise" -> "Soldaten Ameise"
func _aus_schluessel(key: String) -> String:
	var teil := key.substr(key.find("_") + 1)
	var aus := ""
	for i in teil.length():
		var ch := teil[i]
		if i > 0 and ch == ch.to_upper() and ch != ch.to_lower():
			aus += " "
		aus += ch
	return aus


func _wah(teil: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("..").path_join(teil).simplify_path()


# ---------------------------------------------------------------- Aufbau

func _box(groesse: Vector3, ort: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = groesse
	mi.mesh = b
	mi.position = ort
	mi.material_override = mat
	add_child(mi)


func _saal_bauen(mats: Dictionary) -> void:
	var mitte_z := 4.0 - laenge / 2.0
	_box(Vector3(breite, 0.2, laenge), Vector3(0, -0.1, mitte_z), mats["boden"])
	_box(Vector3(0.4, WANDHOEHE, laenge), Vector3(-breite / 2.0 - 0.2, WANDHOEHE / 2.0, mitte_z), mats["wand"])
	_box(Vector3(0.4, WANDHOEHE, laenge), Vector3(breite / 2.0 + 0.2, WANDHOEHE / 2.0, mitte_z), mats["wand"])
	_box(Vector3(breite, WANDHOEHE, 0.4), Vector3(0, WANDHOEHE / 2.0, 4.2), mats["wand"])
	_box(Vector3(breite, WANDHOEHE, 0.4), Vector3(0, WANDHOEHE / 2.0, 4.0 - laenge - 0.2), mats["wand"])
	_box(Vector3(breite + 0.8, 0.3, laenge + 0.8), Vector3(0, WANDHOEHE + 0.15, mitte_z), mats["decke"])


## Platz einer Figur: eine Reihe rechts, oder abwechselnd rechts/links.
func _ort(i: int) -> Vector3:
	if not zwei_reihen:
		return Vector3(REIHE_X, 0, -i * ABSTAND)
	var seite := 1.0 if i % 2 == 0 else -1.0
	return Vector3(REIHE_X2 * seite, 0, -(i / 2) * ABSTAND - (ABSTAND / 2.0 if i % 2 == 1 else 0.0))


func _schilder() -> void:
	for i in eintraege.size():
		var e: Dictionary = eintraege[i]
		var rechts_seite: bool = e.ort.x > 0
		var l := Label3D.new()
		l.text = "%s\n%s · %s m%s" % [e.titel, e.unter, str(snappedf(e.meter, 0.01)).replace(".", ","), " (geschätzt)" if e.get("geschaetzt", false) else ""]
		if englisch:
			l.text = str(e.unter).capitalize() if spiel != "rogue" else str(e.unter).capitalize()
		elif zwei_reihen:
			l.text = "%d  %s" % [i + 1, l.text]
		l.font_size = 64
		l.pixel_size = 0.004
		l.outline_size = 12
		l.modulate = Color(1.0, 0.92, 0.75)
		l.shaded = false
		# an der Wand hinter der Figur, etwas seitlich versetzt, damit große Figuren ihr Schild nicht verdecken
		var hoehe: float = minf(maxf(e.meter + 0.6, 1.8), WANDHOEHE - 0.4)
		var wand_x := (breite / 2.0 - 0.02) * (1.0 if rechts_seite else -1.0)
		l.position = Vector3(wand_x, hoehe, e.ort.z + 1.2)
		l.rotation.y = -PI / 2.0 if rechts_seite else PI / 2.0
		add_child(l)
		# Bodenmarke unter der Figur: zeigt, wo "Boden" ist (schwebt sie oder versinkt sie?)
		var ring := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = 0.55
		t.outer_radius = 0.6
		ring.mesh = t
		ring.scale = Vector3(1, 0.05, 1)
		ring.position = e.ort + Vector3(0, 0.005, 0)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.9, 0.75, 0.4)
		m.emission_enabled = true
		m.emission = Color(0.6, 0.45, 0.2)
		ring.material_override = m
		ring.visible = false
		ring.add_to_group("bodenmarke")
		add_child(ring)


## Helles Arbeitslicht: wandert mit dir mit (auch im 600-m-Saal nur zwei Lampen).
func _arbeitslicht_bauen() -> void:
	arbeitslicht = Node3D.new()
	arbeitslicht.visible = false
	spieler.add_child(arbeitslicht)
	for z in [-3.0, -9.0]:
		var o := OmniLight3D.new()
		o.position = Vector3(0, WANDHOEHE - 0.5, z)
		o.omni_range = 11.0
		o.light_energy = 2.6
		o.light_color = Color(1.0, 0.95, 0.88)
		o.shadow_enabled = true
		arbeitslicht.add_child(o)


func _arbeitslicht_umschalten() -> void:
	arbeitslicht.visible = not arbeitslicht.visible
	for r in get_tree().get_nodes_in_group("bodenmarke"):
		r.visible = arbeitslicht.visible
	print("Arbeitslicht ", "an" if arbeitslicht.visible else "aus")


func _hinweis() -> void:
	if vr:
		return
	var ebene := CanvasLayer.new()
	add_child(ebene)
	var l := Label.new()
	l.text = "%s-Galerie (%d Figuren)   WASD/Pfeile gehen · Maus schauen · Umschalt rennen · N/V nächstes/voriges Monster · Pos1/Ende Anfang/Ende · L Arbeitslicht · T Aufstellen · Esc Maus frei · B Ende" % [spiel.capitalize(), eintraege.size()]
	l.position = Vector2(12, 8)
	l.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7, 0.8))
	ebene.add_child(l)
	_aufst_label = Label.new()
	_aufst_label.position = Vector2(12, 40)
	_aufst_label.add_theme_font_size_override("font_size", 22)
	_aufst_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.5))
	_aufst_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_aufst_label.add_theme_constant_override("outline_size", 6)
	ebene.add_child(_aufst_label)
	# großes Tastenfeld (Peter 22.11.: "ich sehe die Tasten nicht")
	_aufst_hilfe = PanelContainer.new()
	var stil := StyleBoxFlat.new()
	stil.bg_color = Color(0, 0, 0, 0.78)
	stil.set_corner_radius_all(10)
	stil.set_content_margin_all(18)
	_aufst_hilfe.add_theme_stylebox_override("panel", stil)
	_aufst_hilfe.anchor_top = 1.0
	_aufst_hilfe.anchor_bottom = 1.0
	_aufst_hilfe.offset_left = 20
	_aufst_hilfe.offset_top = -430
	var hl := Label.new()
	hl.text = "FIGUR AUFSTELLEN\n" \
			+ "Linke Maustaste halten + ziehen:  kippen\n" \
			+ "      hoch/runter = nach vorn/hinten, links/rechts = zur Seite\n" \
			+ "Rechte Maustaste halten + ziehen:  verschieben\n" \
			+ "Mausrad:  heben / senken\n" \
			+ "Q / E:  drehen\n" \
			+ "Strg dazu:  ganz fein\n" \
			+ "Z:  zurück auf Anfang\n" \
			+ "T:  fertig (wird gespeichert)\n" \
			+ "(auch: Pfeile kippen, R/F heben, I/K/J/L verschieben)"
	hl.add_theme_font_size_override("font_size", 26)
	hl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.75))
	_aufst_hilfe.add_child(hl)
	_aufst_hilfe.visible = false
	ebene.add_child(_aufst_hilfe)
	_aufst_klein = Label.new()
	_aufst_klein.text = "T = Figur aufstellen"
	_aufst_klein.anchor_top = 1.0
	_aufst_klein.anchor_bottom = 1.0
	_aufst_klein.offset_left = 20
	_aufst_klein.offset_top = -60
	_aufst_klein.add_theme_font_size_override("font_size", 28)
	_aufst_klein.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
	_aufst_klein.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_aufst_klein.add_theme_constant_override("outline_size", 8)
	ebene.add_child(_aufst_klein)


# ---------------------------------------------------------------- Figuren laden, wenn du näher kommst

## Lädt Figuren in deiner Nähe (höchstens eine pro Bild, damit es nicht ruckelt) und gibt ferne frei.
func _nachladen(alle := false) -> void:
	var z := spieler.position.z
	var neu := 0
	for i in eintraege.size():
		var nah: bool = absf(eintraege[i].ort.z - z) < NAH
		if nah and not geladen.has(i):
			if neu >= 1 and not alle:
				continue
			_figur_bauen(i)
			neu += 1
		elif not nah and geladen.has(i):
			var m: Dictionary = geladen[i]
			g.monster.aktive.erase(m)
			m.knoten.queue_free()
			geladen.erase(i)
			g.monster._modelle3d.erase(m.c)   # Vorlage freigeben, sonst wächst der Speicher im langen Saal


## Wie im Spiel über monster.gd bauen.
func _figur_bauen(i: int) -> void:
	var e: Dictionary = eintraege[i]
	if String(e.c).contains(":"):
		g.monster._nh_meter[e.c] = e.meter
	var m: Dictionary = g.monster._bauen(e.c, Vector2i(10000, i))
	m.knoten.position = e.ort
	# alle schauen fest zum Weg (Peter 22.11.: "eine Richtung, nicht meine"); Modelle blicken nach -Z
	m.eigene_blick = PI / 2.0 if e.ort.x > 0 else -PI / 2.0
	m.knoten.rotation.y = m.eigene_blick
	m.zustand = "ruhe"
	m.lp = 1.0
	g.monster.aktive.append(m)
	geladen[i] = m


# ---------------------------------------------------------------- VR

func _vr_starten() -> bool:
	var xr := XRServer.find_interface("OpenXR")
	if xr == null or not xr.is_initialized():
		return false
	get_viewport().use_xr = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	origin = XROrigin3D.new()
	spieler.add_child(origin)
	xr_cam = XRCamera3D.new()
	xr_cam.near = 0.05
	origin.add_child(xr_cam)
	xr_cam.make_current()
	links = XRController3D.new()
	links.tracker = "left_hand"
	origin.add_child(links)
	rechts = XRController3D.new()
	rechts.tracker = "right_hand"
	origin.add_child(rechts)
	vr = true
	print("VR: Galerie aktiv")
	return true


func _neu(name: String, jetzt: bool) -> bool:
	var vorher: bool = _vorher.get(name, false)
	_vorher[name] = jetzt
	return jetzt and not vorher


# ---------------------------------------------------------------- Steuerung

func _unhandled_input(e: InputEvent) -> void:
	if vr:
		return
	if aufstellen >= 0 and _maus_werkzeug(e):
		return
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		gier = wrapf(gier - e.relative.x * MAUS, -PI, PI)
		nick = clampf(nick - e.relative.y * MAUS, -1.3, 1.3)
		spieler.rotation.y = gier
		kamera.rotation.x = nick
	elif e is InputEventMouseButton and e.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif e is InputEventKey and e.pressed and e.keycode == KEY_T and not e.echo:
		_aufstellen_umschalten()
	elif e is InputEventKey and e.pressed and aufstellen >= 0 and _aufstell_taste(e):
		pass
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_B:
				get_tree().quit()
			KEY_L:
				_arbeitslicht_umschalten()
			KEY_PAGEDOWN, KEY_N:
				_springen(1)
			KEY_PAGEUP, KEY_V:
				_springen(-1)
			KEY_HOME:
				_zu(0)
			KEY_END:
				_zu(eintraege.size() - 1)


## Welche Figur ist gerade "dran"? (die nächste vor dir auf dem Weg)
func _aktuell() -> int:
	var bester := 0
	var dist := INF
	for i in eintraege.size():
		var d := absf(eintraege[i].ort.z + 2.0 - spieler.position.z)
		if d < dist:
			dist = d
			bester = i
	return bester


func _springen(richtung: int) -> void:
	_zu(clampi(_aktuell() + richtung, 0, eintraege.size() - 1))


## Vor Figur i auf dem Weg stehen und sie ansehen.
func _zu(i: int) -> void:
	var ort: Vector3 = eintraege[i].ort
	spieler.position = Vector3(weg_x, 0, ort.z + 2.0)
	_nachladen(true)
	if not vr:
		var ziel := ort + Vector3(0, minf(eintraege[i].meter * 0.6, 1.6), 0) - (spieler.position + Vector3(0, AUGENHOEHE, 0))
		gier = atan2(-ziel.x, -ziel.z)
		spieler.rotation.y = gier
		nick = clampf(atan2(ziel.y, Vector2(ziel.x, ziel.z).length()), -0.6, 0.4)
		kamera.rotation.x = nick


func _process(delta: float) -> void:
	if _portraits:
		return
	_nachladen()
	var weg := Vector2.ZERO    # x = rechts, y = vorwärts
	var schnell := false
	var blick := gier
	if vr:
		var ls := links.get_vector2("primary")
		var rs := rechts.get_vector2("primary")
		if _neu("griff_l", links.get_float("grip") > 0.6):
			_aufstellen_umschalten()
		if aufstellen >= 0:
			# rechter Stick kippen; linker Stick drehen/heben, mit rechtem Griff verschieben
			var ein := {"vor": _tot(rs.y), "seite": _tot(rs.x), "dreh": 0.0, "hoch": 0.0, "schieb": Vector2.ZERO}
			if rechts.get_float("grip") > 0.6:
				ein.schieb = Vector2(_tot(ls.x), _tot(ls.y))
			else:
				ein.dreh = -_tot(ls.x)
				ein.hoch = _tot(ls.y)
			_aufstellen_laufen(delta, ein, 1.0)
			rs = Vector2.ZERO
			ls = Vector2.ZERO
		if ls.length() > 0.2:
			weg = Vector2(ls.x, ls.y)
		schnell = rechts.get_float("grip") > 0.6
		if aufstellen < 0 and _neu("dreh_l", rs.x < -0.7):
			spieler.rotation.y += PI / 2.0
		if aufstellen < 0 and _neu("dreh_r", rs.x > 0.7):
			spieler.rotation.y -= PI / 2.0
		if _neu("abzug_r", rechts.get_float("trigger") > 0.7):
			_arbeitslicht_umschalten()
		if _neu("knopf_a", rechts.is_button_pressed("ax_button")):
			_springen(1)
		if _neu("knopf_b", rechts.is_button_pressed("by_button")):
			_springen(-1)
		blick = spieler.rotation.y + xr_cam.rotation.y
	else:
		var pfeile := aufstellen < 0   # beim Aufstellen kippen die Pfeile die Figur
		if Input.is_key_pressed(KEY_W) or (pfeile and Input.is_key_pressed(KEY_UP)):
			weg.y += 1
		if Input.is_key_pressed(KEY_S) or (pfeile and Input.is_key_pressed(KEY_DOWN)):
			weg.y -= 1
		if Input.is_key_pressed(KEY_D) or (pfeile and Input.is_key_pressed(KEY_RIGHT)):
			weg.x += 1
		if Input.is_key_pressed(KEY_A) or (pfeile and Input.is_key_pressed(KEY_LEFT)):
			weg.x -= 1
		schnell = Input.is_key_pressed(KEY_SHIFT)
		if aufstellen >= 0:
			var k := func(a: Key, b: Key) -> float: return float(Input.is_key_pressed(a)) - float(Input.is_key_pressed(b))
			var ein := {"vor": k.call(KEY_UP, KEY_DOWN), "seite": k.call(KEY_RIGHT, KEY_LEFT), "dreh": k.call(KEY_Q, KEY_E),
					"hoch": clampf(k.call(KEY_R, KEY_F) + k.call(KEY_PLUS, KEY_MINUS) + k.call(KEY_KP_ADD, KEY_KP_SUBTRACT) + k.call(KEY_PAGEUP, KEY_PAGEDOWN), -1.0, 1.0),
					"schieb": Vector2(k.call(KEY_L, KEY_J), k.call(KEY_I, KEY_K))}
			var tempo := 3.0 if schnell else (0.2 if Input.is_key_pressed(KEY_CTRL) else 1.0)
			_aufstellen_laufen(delta, ein, tempo)
			schnell = false
	if weg == Vector2.ZERO:
		return
	weg = weg.limit_length(1.0)
	var vor := Vector3(-sin(blick), 0, -cos(blick))
	var re := Vector3(cos(blick), 0, -sin(blick))
	var p := spieler.position + (vor * weg.y + re * weg.x) * (RENNEN if schnell else GEHEN) * delta
	p.x = clampf(p.x, -breite / 2.0 + 0.4, breite / 2.0 - 0.4)
	p.z = clampf(p.z, 4.0 - laenge + 0.4, 3.6)
	spieler.position = p


# ---------------------------------------------------------------- Selbsttest (Fotos)

func _fotos_machen() -> void:
	_nachladen(true)
	await get_tree().create_timer(1.5).timeout
	var ordner := ProjectSettings.globalize_path("res://").path_join("../grafik-test").simplify_path()
	var auswahl: Array = range(eintraege.size())
	if eintraege.size() > 40:   # NetHack: nur eine Stichprobe fotografieren
		auswahl = range(0, eintraege.size(), int(eintraege.size() / 20.0))
	for licht in [false, true]:
		if licht:
			_arbeitslicht_umschalten()
		for i in auswahl:
			_zu(i)
			await get_tree().create_timer(0.35).timeout
			await RenderingServer.frame_post_draw
			var n := "galerie_%s_%03d_%s.png" % [spiel, i + 1, "hell" if licht else "fackel"]
			get_viewport().get_texture().get_image().save_png(ordner.path_join(n))
	# Überblick den Saal entlang
	_zu(0)
	spieler.position = Vector3(weg_x - 0.8, 0, 3.4)
	gier = -0.1 if not zwei_reihen else 0.0
	spieler.rotation.y = gier
	kamera.rotation.x = -0.05
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ordner.path_join("galerie_%s_ueberblick.png" % spiel))
	var drei_d := 0
	var ohne := []
	for i in eintraege.size():   # alle einmal laden: welche Figur hat kein Modell?
		if not geladen.has(i):
			_figur_bauen(i)
		if geladen[i].get("drei_d", false):
			drei_d += 1
		else:
			ohne.append(eintraege[i].c)
		if eintraege.size() > 40:
			var m: Dictionary = geladen[i]
			g.monster.aktive.erase(m)
			m.knoten.queue_free()
			geladen.erase(i)
			g.monster._modelle3d.erase(m.c)
			await get_tree().process_frame
	print("TEST Galerie ", spiel, ": ", eintraege.size(), " Figuren, davon 3D: ", drei_d, ", ohne Modell: ", ohne)
	for i in geladen.keys():
		geladen[i].knoten.queue_free()
	geladen.clear()
	g.monster.aktive.clear()
	await get_tree().process_frame
	get_tree().quit()


## Je Figur allein: Foto frontal und genau von der Seite (Kamera 1,6 m hoch, 4 m Abstand), Arbeitslicht an.
func _portraits_machen() -> void:
	_portraits = true
	var nur := []
	var tief := "--tief" in OS.get_cmdline_user_args()
	var weit := "--weit" in OS.get_cmdline_user_args()
	var varianten := []   # --varianten=x:z:h,x:z:h  (Grad vorn/Seite wie beim Aufstellen, Höhe cm)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--nur="):
			nur = a.substr(6).split(",")
		elif a.begins_with("--varianten="):
			for s in a.substr(12).split(","):
				var w := s.split(":")
				varianten.append(Vector4(float(w[0]), 0, float(w[1]) if w.size() > 1 else 0.0, float(w[2]) if w.size() > 2 else 0.0))
	var ordner := ProjectSettings.globalize_path("res://").path_join("../grafik-test/portraits").simplify_path()
	DirAccess.make_dir_recursive_absolute(ordner)
	for i in geladen.keys():
		g.monster.aktive.erase(geladen[i])
		geladen[i].knoten.queue_free()
	geladen.clear()
	_arbeitslicht_umschalten()
	var cam := Camera3D.new()
	cam.fov = 50.0
	cam.near = 0.05
	add_child(cam)
	cam.make_current()
	for i in eintraege.size():
		var e: Dictionary = eintraege[i]
		var key := String(e.c).get_slice(":", 1) if String(e.c).contains(":") else String(e.c)
		if nur.size() > 0 and not key in nur:
			continue
		var c: String = e.c
		var hatte: bool = g.monster.aufstellung.has(c)
		var alt: Vector4 = g.monster.aufstellung.get(c, Vector4.ZERO)
		var basis_k: Vector3 = g.monster.kippen_wert(c)
		var basis_h: float = g.monster.hoehe_wert(c) * 100.0
		if varianten.is_empty():
			await _portrait_figur(i, key, "", cam, ordner, tief, weit)
		for vi in varianten.size():   # nur im Speicher, nichts wird gespeichert
			var v: Vector4 = varianten[vi]
			var bb := Basis.from_euler(Vector3(deg_to_rad(basis_k.x), deg_to_rad(basis_k.y), deg_to_rad(basis_k.z)))
			var tt := Basis(Vector3.RIGHT, deg_to_rad(v.x)) * Basis(Vector3.BACK, deg_to_rad(v.z))
			var eu := (tt * bb).get_euler()
			g.monster.aufstellung[c] = Vector4(rad_to_deg(eu.x), rad_to_deg(eu.y), rad_to_deg(eu.z), basis_h + v.w)
			g.monster._modelle3d.erase(c)
			await _portrait_figur(i, key, "__v%d" % vi, cam, ordner, tief, weit)
		if varianten.size() > 0:
			if hatte:
				g.monster.aufstellung[c] = alt
			else:
				g.monster.aufstellung.erase(c)
	print("PORTRAITS FERTIG")
	get_tree().quit()

func _portrait_figur(i: int, key: String, endung: String, cam: Camera3D, ordner: String, tief: bool, weit: bool) -> void:
	var e: Dictionary = eintraege[i]
	_figur_bauen(i)
	var m: Dictionary = geladen[i]
	spieler.position = Vector3(weg_x, 0, e.ort.z)     # Fackel/Arbeitslicht mitnehmen
	var b: float = m.eigene_blick
	var vor := Vector3(-sin(b), 0, -cos(b))          # Blickrichtung der Figur
	var rechts := Vector3(cos(b), 0, -sin(b))
	var ziel: Vector3 = e.ort + Vector3(0, minf(e.meter * 0.5, 1.6), 0)
	var hoehe := 1.6
	var abstand := 4.0
	if weit:   # Kamera 0,5 m hoch, so weit weg, dass Figur und Boden ganz im Bild sind
		hoehe = 0.5
		abstand = maxf(3.0, e.meter * 2.0 + 1.0)
		ziel = e.ort + Vector3(0, e.meter * 0.45, 0)
	elif tief:   # Kamera knapp über dem Boden: Spalt unter den Füßen sichtbar
		hoehe = 0.3
		ziel = e.ort + Vector3(0, 0.25, 0)
	for ansicht in [["vorn", vor], ["seite", rechts]]:
		var ab := abstand
		if weit and ansicht[0] == "vorn":
			ab = minf(ab, 5.6)   # sonst steht die Kamera hinter der gegenüberliegenden Wand
		elif weit:
			ab = minf(ab, 3.6)   # seitlich steht nach 4 m schon die Nachbarfigur
		cam.fov = 65.0 if weit else 50.0
		cam.global_position = e.ort + ansicht[1] * ab + Vector3(0, hoehe, 0)
		cam.look_at(ziel, Vector3.UP)
		await get_tree().create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(ordner.path_join("%s%s__%s.png" % [key, endung, ansicht[0]]))
	var welt := ModellHilfe.huelle_genau(m.knoten, (m.knoten.get_parent() as Node3D).global_transform) if m.get("drei_d", false) else AABB()
	var fuss := Vector2.ZERO
	if m.get("drei_d", false):   # Mitte der untersten 3 cm (Füße) gegenüber dem Feld, in Metern
		var fm := ModellHilfe.fuss_mitte(m.knoten, welt.position.y + 0.03, Vector2(e.ort.x, e.ort.z))
		fuss = fm - Vector2(e.ort.x, e.ort.z)
	print("PORTRAIT ", key + endung, " meter ", e.meter, " blick ", snappedf(b, 0.01), " unten ", snappedf(welt.position.y, 0.001), " hoehe ", snappedf(welt.size.y, 0.001), " fuss ", snappedf(fuss.length(), 0.01))
	g.monster.aktive.erase(m)
	m.knoten.queue_free()
	geladen.erase(i)
	g.monster._modelle3d.erase(m.c)
	await get_tree().process_frame



# ---------------------------------------------------------------- Aufstellen (Taste T)

## Die Figur, die du ansiehst: unter den nahen die mit dem kleinsten Winkel zur Blickrichtung.
func _anvisiert() -> int:
	var blick := -spieler.global_transform.basis.z
	if vr:
		blick = -xr_cam.global_transform.basis.z
	blick.y = 0.0
	blick = blick.normalized()
	var bester := _aktuell()
	var bestwert := INF
	for i in eintraege.size():
		var d: Vector3 = eintraege[i].ort - spieler.global_position
		d.y = 0.0
		if d.length() > 8.0 or d.length() < 0.1:
			continue
		var w := blick.angle_to(d.normalized()) + d.length() * 0.05
		if w < bestwert:
			bestwert = w
			bester = i
	return bester


func _aufstellen_umschalten() -> void:
	if not _aufst_d.is_empty():
		_aufstellen_uebernehmen()
	aufstellen = -1 if aufstellen >= 0 else _anvisiert()
	_maus_l = false
	_maus_r = false
	if aufstellen >= 0 and not arbeitslicht.visible:
		_arbeitslicht_umschalten()   # beim Aufstellen soll man die Figur deutlich sehen
	_marke_setzen()
	_aufstellen_anzeigen()


## Grüner Leuchtring unter der ausgewählten Figur (auch ohne Arbeitslicht sichtbar).
func _marke_setzen() -> void:
	if _aufst_marke == null:
		_aufst_marke = MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = 0.62
		t.outer_radius = 0.72
		_aufst_marke.mesh = t
		_aufst_marke.scale = Vector3(1, 0.06, 1)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(0.2, 1.0, 0.3)
		_aufst_marke.material_override = m
		_aufst_marke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_aufst_marke)
	_aufst_marke.visible = aufstellen >= 0
	if aufstellen >= 0:
		_aufst_marke.position = eintraege[aufstellen].ort + Vector3(0, 0.012, 0)


## Taste beim Aufstellen; true, wenn sie verbraucht wurde (die Bewegungstasten laufen in _process).
func _aufstell_taste(e: InputEventKey) -> bool:
	match e.keycode:
		KEY_Z, KEY_Y:
			_aufst_d.clear()
			g.monster.aufstellung_entfernen(eintraege[aufstellen].c)
			_aufstellen_neu_bauen()
		KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_Q, KEY_E, KEY_R, KEY_F, KEY_PAGEUP, KEY_PAGEDOWN, KEY_PLUS, KEY_MINUS, \
				KEY_KP_ADD, KEY_KP_SUBTRACT, KEY_I, KEY_J, KEY_K, KEY_L:
			pass
		_:
			return false
	return true


func _tot(v: float) -> float:   # Stick-Totzone
	return 0.0 if absf(v) < 0.25 else v


## Gehaltene Eingabe: Figur sofort am Knoten bewegen (ohne Neuaufbau); beim Loslassen speichern und neu aufbauen.
func _aufstellen_laufen(delta: float, ein: Dictionary, tempo: float) -> void:
	var aktiv: bool = ein.vor != 0.0 or ein.seite != 0.0 or ein.dreh != 0.0 or ein.hoch != 0.0 or ein.schieb != Vector2.ZERO
	if _rad_zeit > 0.0:
		_rad_zeit -= delta
	if not aktiv:
		if not _aufst_d.is_empty() and not _maus_l and not _maus_r and _rad_zeit <= 0.0:
			_aufstellen_uebernehmen()
		return
	if not geladen.has(aufstellen):
		return
	if _aufst_d.is_empty():
		_aufst_d = {"kipp": Vector3.ZERO, "hoch": 0.0, "schieb": Vector2.ZERO}
	_aufst_d.kipp += Vector3(ein.vor * 12.0, ein.dreh * 30.0, ein.seite * 12.0) * tempo * delta
	_aufst_d.hoch += ein.hoch * 5.0 * tempo * delta
	# verschieben in deiner Blickrichtung (Welt)
	var blick := spieler.global_transform.basis
	if vr:
		blick = xr_cam.global_transform.basis
	var vor := -blick.z
	vor.y = 0.0
	vor = vor.normalized()
	var re := Vector3(-vor.z, 0, vor.x)
	var s: Vector2 = ein.schieb * 0.25 * tempo * delta
	var w := re * s.x + vor * s.y
	_aufst_d.schieb += Vector2(w.x, w.z)
	_aufstellen_vorschau()


## Vorschau der laufenden Änderung am Versatz-Knoten der Figur (Figur blickt dort nach -Z, rechts = +X).
func _aufstellen_vorschau() -> void:
	if not geladen.has(aufstellen) or _aufst_d.is_empty():
		return
	var m: Dictionary = geladen[aufstellen]
	var k: Vector3 = _aufst_d.kipp
	var b := Basis(Vector3.UP, deg_to_rad(k.y)) * Basis(Vector3.RIGHT, deg_to_rad(-k.x)) * Basis(Vector3.BACK, deg_to_rad(-k.z))
	var lokal: Vector3 = m.knoten.global_transform.basis.inverse() * Vector3(_aufst_d.schieb.x, 0, _aufst_d.schieb.y)
	m.versatz.transform = Transform3D(b, Vector3(lokal.x, _aufst_d.hoch / 100.0, lokal.z))
	_aufstellen_anzeigen()


## Maus beim Aufstellen: links ziehen = kippen, rechts ziehen = verschieben, Rad = heben/senken. Die Kamera bleibt
## dabei stehen. true, wenn das Ereignis verbraucht wurde.
func _maus_werkzeug(e: InputEvent) -> bool:
	var fein := 0.2 if Input.is_key_pressed(KEY_CTRL) else 1.0
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_maus_l = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_maus_r = mb.pressed
		elif mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			_aufst_start()
			_aufst_d.hoch += (1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0) * fein
			_rad_zeit = 0.6
			_aufstellen_vorschau()
			_aufstellen_anzeigen()
		else:
			return false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return true
	if e is InputEventMouseMotion and (_maus_l or _maus_r):
		var r: Vector2 = (e as InputEventMouseMotion).relative * fein
		_aufst_start()
		if _maus_l:   # hoch/runter = nach vorn/hinten, links/rechts = zur Seite (0,08° je Pixel)
			_aufst_d.kipp += Vector3(-r.y * 0.08, 0, r.x * 0.08)
		else:         # verschieben in deiner Blickrichtung (2 mm je Pixel)
			var vor := -spieler.global_transform.basis.z
			vor.y = 0.0
			vor = vor.normalized()
			var re := Vector3(-vor.z, 0, vor.x)
			var w := re * (r.x * 0.002) + vor * (-r.y * 0.002)
			_aufst_d.schieb += Vector2(w.x, w.z)
		_aufstellen_vorschau()
		_aufstellen_anzeigen()
		return true
	return false


func _aufst_start() -> void:
	if _aufst_d.is_empty():
		_aufst_d = {"kipp": Vector3.ZERO, "hoch": 0.0, "schieb": Vector2.ZERO}


func _aufstellen_uebernehmen() -> void:
	var d := _aufst_d.duplicate()
	_aufst_d.clear()
	var m: Dictionary = geladen.get(aufstellen, {})
	var lokal := Vector3.ZERO
	if not m.is_empty():
		lokal = m.knoten.global_transform.basis.inverse() * Vector3(d.schieb.x, 0, d.schieb.y)
	_aufstellen_aendern(d.kipp, d.hoch, Vector2(lokal.x, lokal.z) * 100.0)


## kippen: x = nach vorn (+) / hinten, z = zur Seite (+ rechts), y = drehen, jeweils in Grad, wie die Figur jetzt
## dasteht (nicht in den Achsen der Datei); hoch: Zentimeter.
func _aufstellen_aendern(kippen: Vector3, hoch: float, schieb_cm := Vector2.ZERO) -> void:
	if aufstellen < 0:
		return
	var c: String = eintraege[aufstellen].c
	var k: Vector3 = g.monster.kippen_wert(c)
	var b := Basis.from_euler(Vector3(deg_to_rad(k.x), deg_to_rad(k.y), deg_to_rad(k.z)))
	# Hack-/NetHack-Dateien blicken nach +Z: dort ist "vorn" +Z, rechts (von der Figur aus) -X
	var t := Basis(Vector3.UP, deg_to_rad(kippen.y)) * Basis(Vector3.RIGHT, deg_to_rad(kippen.x)) \
			* Basis(Vector3.BACK, deg_to_rad(kippen.z))
	var neu := (t * b).get_euler()
	var h: float = g.monster.hoehe_wert(c) * 100.0 + hoch
	var v: Vector2 = g.monster.versatz_wert(c) * 100.0 + schieb_cm
	g.monster.aufstellung_setzen(c, Vector4(rad_to_deg(neu.x), rad_to_deg(neu.y), rad_to_deg(neu.z), h), v)
	_aufstellen_neu_bauen()


func _aufstellen_neu_bauen() -> void:
	var i := aufstellen
	if geladen.has(i):
		var m: Dictionary = geladen[i]
		g.monster.aktive.erase(m)
		m.knoten.queue_free()
		geladen.erase(i)
	g.monster._modelle3d.erase(eintraege[i].c)
	_figur_bauen(i)
	_aufstellen_anzeigen()


func _aufstellen_anzeigen() -> void:
	var text := ""
	if aufstellen >= 0:
		var c: String = eintraege[aufstellen].c
		var k: Vector3 = g.monster.kippen_wert(c)
		var v: Vector2 = g.monster.versatz_wert(c) * 100.0
		var laeuft := "  …" if not _aufst_d.is_empty() else ("  (gespeichert)" if g.monster.aufstellung.has(c) else "")
		text = "AUFSTELLEN: %s   x %+.1f°  y %+.1f°  z %+.1f°  Höhe %+.0f cm  verschoben %+.0f/%+.0f cm%s\n" % [
				eintraege[aufstellen].titel, k.x, k.y, k.z, g.monster.hoehe_wert(c) * 100.0, v.x, v.y, laeuft] \
				+ "Halten: Pfeile kippen · Q/E drehen · R/F heben/senken · I/K/J/L verschieben · Umschalt schnell, Strg fein · Z zurück · T fertig"
	if _aufst_label:
		_aufst_label.text = text.get_slice("\n", 0)
	if _aufst_hilfe:
		_aufst_hilfe.visible = aufstellen >= 0
		_aufst_klein.visible = aufstellen < 0
	print(text.get_slice("\n", 0) if text != "" else "Aufstellen aus")
