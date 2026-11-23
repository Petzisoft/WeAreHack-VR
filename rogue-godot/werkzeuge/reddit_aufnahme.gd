## Aufnahme für Reddit (Peter 23.11.): fährt das Spiel selbst durch und macht Bilder (und mit --write-movie ein Video).
## Startmenü -> Rogue (warten, bis ein Monster kommt, hinsehen, kämpfen) -> NetHack im Zauberer-Modus (-D: Monster
## friedlich erschaffen, Minenstadt, Tal der Toten) -> Galerie mit ausgewählten Figuren (Kamerafahrt).
## Aufruf (Englisch ist Standard):
##   Godot --resolution 1920x1080 [--write-movie roh.avi --fixed-fps 30] --path rogue-godot res://start.tscn -- --reddit=<ordner>
## Bilder: <ordner>/NN_name.png. Zeitmarken für den Videoschnitt: <ordner>/marken.txt (Sekunde im Video, Name).
## USERNAME vorher auf einen eigenen Namen setzen (z. B. wahtest), damit Peters NetHack-Spielstand unberührt bleibt.
extends RefCounted

const Spiel = preload("res://spiel.gd")
const Vorspann = preload("res://vorspann.gd")
const GALERIE := ["nh:D_RoterDrache", "nh:Und_Balrog", "nh:H_Titan", "nh:u_WeissesEinhorn", "nh:O_Ogerkoenig",
		"nh:L_Lich", "nh:T_OlogHai", "nh:V_VladDerPfaehler", "nh:Golem_Eisengolem", "nh:C_Waldzentaur",
		"nh:q_Mumak", "nh:d_Zerberus"]
# Rogue-Richtungstasten: (dx, dy) -> Taste (y wächst nach unten = Süden)
const TASTEN := {Vector2i(-1, 0): "h", Vector2i(1, 0): "l", Vector2i(0, -1): "k", Vector2i(0, 1): "j",
		Vector2i(-1, -1): "y", Vector2i(1, -1): "u", Vector2i(-1, 1): "b", Vector2i(1, 1): "n"}

static var baum: SceneTree
static var ordner := ""
static var marken := ""


static func laufen(m) -> void:
	baum = m.get_tree()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--reddit="):
			ordner = a.substr(9)
	DirAccess.make_dir_recursive_absolute(ordner)
	# ---------------- Startmenü
	await _warten(1.0)
	_marke("menue")
	m._markieren(2)
	await _warten(1.2)
	m._markieren(0)
	await _warten(1.3)
	await _foto("01_start_menu")
	m.waehlen()
	await _warten(1.6)
	# ---------------- Rogue
	var d = baum.current_scene
	if OS.get_environment("WAH_NUR_NETHACK") != "":
		d.anzeigen.hilfe_kasten.visible = false
	else:
		await _rogue_teil(d)
	await _nethack_teil(d)
	if OS.get_environment("WAH_OHNE_GALERIE") == "":
		await _galerie_teil()
	var f := FileAccess.open(ordner.path_join("marken.txt"), FileAccess.WRITE)
	f.store_string(marken)
	f.close()
	print("REDDIT fertig")
	baum.quit()


static func _rogue_teil(d) -> void:
	_marke("rogue_vorspann")
	await _warten(2.5)
	await _foto("02_rogue_title")
	_vorspann_zu(d)
	await _warten(1.5)
	_marke("rogue_suchen")
	var mon = await _rogue_monster_holen(d)
	_marke("rogue_monster")
	d.anzeigen.hilfe_kasten.visible = false
	if mon:
		_hinsehen(d, mon.p)
		await _warten(1.2)
		d.anzeigen.hilfe_kasten.visible = false
		await _foto("03_rogue_monster")
		for i in 6:   # angreifen
			var akt = _naechstes(d)
			if akt == null:
				break
			_hinsehen(d, akt.p)
			var r: Vector2i = (akt.p - d.feld).sign()
			if TASTEN.has(r) and maxi(absi(akt.p.x - d.feld.x), absi(akt.p.y - d.feld.y)) <= 1:
				d.taste_senden(ord(TASTEN[r]))
			else:
				d.taste_senden(ord("s"))
			await _warten(0.9)
			if i == 1:
				await _foto("04_rogue_fight")
	_marke("rogue_ende")


static func _nethack_teil(d) -> void:
	# ---------------- NetHack (Zauberer-Modus: Monster erschaffen, Ebenen wechseln)
	d.rogue.stoppen()
	Spiel.setzen("nethack")
	baum.change_scene_to_file("res://dungeon.tscn")
	await _warten(1.5)
	d = baum.current_scene
	_marke("nethack_vorspann")
	await _warten(2.0)
	await _foto("05_nethack_title")
	_vorspann_zu(d)
	d.rogue.stoppen()
	await _warten(1.0)
	# Sperrdateien des eben gestarteten Spiels weg (nur eigener Testname, nie Peters Spielstand)
	if not OS.get_environment("USERNAME").begins_with("wahtest"):
		print("REDDIT Abbruch: USERNAME muss mit wahtest beginnen (Peters NetHack-Spiel schützen)")
		baum.quit()
		return
	load("res://spielstand.gd").nethack_sperren_weg()
	# Windows-NetHack erlaubt den Zauberer-Modus nur dem Spieler "wizard" (sys/winnt/windmain.c)
	OS.set_environment("NETHACKOPTIONS", "name:wizard,number_pad:0,!hitpointbar,time,showexp,autopickup,pickup_types:$")
	_sperren_weg("wizard")
	d._rogue_starten(["-D"])
	await _warten(2.5)
	await _nethack_start(d)
	# Zauberer-Befehle (Monster erschaffen, Ebenen-Menü) nicht im Bild zeigen: Meldungen, Textseiten, Listen unsichtbar
	d.anzeigen.meldung_kasten.modulate.a = 0.0
	d.anzeigen.volltext.modulate.a = 0.0
	d.steuerung.auswahl.modulate.a = 0.0
	_marke("nethack_spiel")
	print("REDDIT nethack start: meldung=", d.meldung, " textseite=", d.textseite, " status=", d.anzeigen.status_label.text)
	for name in ["peaceful ogre king", "peaceful white unicorn", "peaceful owlbear"]:
		await _erschaffen(d, name)
	await _warten(1.0)
	await _abstand_nehmen(d, 2)
	await _bild_mit(d, "ogre", "06_nethack_ogre_king")
	_marke("nethack_minen")
	if await _teleport(d, "minetn"):
		await _erschaffen(d, "peaceful dwarf king")
		await _erschaffen(d, "peaceful minotaur")
		await _abstand_nehmen(d, 2)
		await _bild_mit(d, "minotaur", "08_nethack_mines")
	_marke("nethack_gehennom")
	if await _teleport(d, "Valley"):
		await _erschaffen(d, "peaceful pit fiend")
		await _erschaffen(d, "peaceful lich")
		await _abstand_nehmen(d, 2)
		await _bild_mit(d, "fiend", "09_nethack_gehennom")
	_marke("nethack_ende")
	d.rogue.stoppen()
	await _warten(0.5)
	_sperren_weg("wizard")
	load("res://spielstand.gd").nethack_sperren_weg()
	await _warten(1.0)


static func _galerie_teil() -> void:
	# ---------------- Galerie
	var gal = load("res://werkzeuge/monster_galerie.tscn").instantiate()
	gal.spiel = "nethack"
	gal.nur = GALERIE
	gal.englisch = true
	var alt = baum.current_scene
	baum.root.add_child(gal)
	baum.current_scene = gal
	alt.queue_free()
	await _warten(0.5)
	for k in gal.get_children():
		if k is CanvasLayer:
			k.visible = false
	gal._arbeitslicht_umschalten()
	for r in baum.get_nodes_in_group("bodenmarke"):
		r.visible = false
	gal._nachladen(true)
	await _warten(1.5)
	_marke("galerie")
	# Überblick schräg in den Saal, dann langsam den Weg entlang
	gal.spieler.position = Vector3(0, 0, 4.0)
	gal.spieler.rotation.y = 0.0
	gal.kamera.rotation.x = -0.02
	await _warten(0.8)
	await _foto("10_gallery_overview")
	var tw = gal.create_tween()
	tw.tween_property(gal.spieler, "position:z", -gal.laenge + 10.0, 14.0)
	var t0 := 0.0
	var foto_nah := false
	while tw.is_running():
		await baum.process_frame
		t0 += baum.root.get_process_delta_time()
		gal.spieler.rotation.y = sin(t0 * 0.45) * 0.55   # sanft nach links und rechts schauen
		if not foto_nah and t0 > 3.0:
			foto_nah = true
	_marke("galerie_ende")
	# Nahaufnahmen
	for i in [0, 1, 2]:
		gal._zu(i)
		await _warten(1.0)
		await _foto("%02d_gallery_%s" % [11 + i, str(gal.eintraege[i].c).substr(3)])


# ---------------------------------------------------------------- Rogue

## Suchen ("s"), bis ein Monster in Sicht ist (höchstens ~150 Züge).
static func _rogue_monster_holen(d):
	for i in 60:   # je 20 Züge suchen (Rogue hört von selbst auf, sobald ein Monster auftaucht)
		var m = _naechstes(d)
		if m and _abstand(d, m.p) <= 6:
			return m
		for c in "20s":
			d.taste_senden(c.unicode_at(0))
		await _warten(0.7)
		if "--More--" in d.meldung:
			d.taste_senden(32)
	return _naechstes(d)


static func _naechstes(d):
	var bester = null
	for m in d.grafik.monster.aktive:
		if bester == null or _abstand(d, m.p) < _abstand(d, bester.p):
			bester = m
	return bester


static func _abstand(d, p: Vector2i) -> int:
	return maxi(absi(p.x - d.feld.x), absi(p.y - d.feld.y))


# ---------------------------------------------------------------- NetHack

static func _nethack_start(d) -> void:
	for i in 12:   # "Shall I pick ...?" y, Einleitung und --More-- wegklicken, bis die Statuszeile da ist
		var m: String = d.meldung
		if "Shall I pick" in m or "[ynaq]" in m or "[ynq]" in m:
			d.taste_senden(ord("y"))
		elif "restore" in m.to_lower() or "Recover" in m:
			d.taste_senden(ord("n"))
		else:
			d.taste_senden(32)
		await _warten(0.8)
		if d.nethack.gueltig and not d.textseite and not "--More--" in d.meldung and i > 3:
			break
	d.steuerung._liste_zu()


## Zauberer-Befehl ^G: Monster erschaffen (friedlich, neben dem Helden).
static func _erschaffen(d, name: String) -> void:
	d.taste_senden(7)
	await _warten(0.6)
	print("REDDIT nach ^G: meldung=", d.meldung, " textseite=", d.textseite)
	for c in name:
		d.taste_senden(c.unicode_at(0))
		await _warten(0.03)
	d.taste_senden(13)
	await _warten(0.9)
	print("REDDIT erschaffen ", name, ": ", d.meldung)
	if "--More--" in d.meldung:
		d.taste_senden(32)
		await _warten(0.5)
	d.steuerung._liste_zu()


## Nach dem Monster mit diesem Namen sehen und ein Bild machen.
static func _bild_mit(d, wort: String, name: String) -> void:
	var p = _monster_feld(d, wort)
	if p != null:
		_hinsehen(d, p)
	d.nick = 0.04
	d.kamera.rotation.x = d.nick
	# Kamera nur fürs Bild 1,7 m hinter den Helden und Licht etwas heller, damit das Monster ganz drauf ist
	d.kamera.position.z = 0.5
	var licht = d.grafik.spieler_licht
	var energie: float = licht.light_energy
	licht.light_energy = energie * 2.2
	await _warten(1.3)
	await _foto(name)
	d.kamera.position.z = 0.0
	licht.light_energy = energie


static func _monster_feld(d, wort: String):
	for p in d.nethack.monster_namen:
		if wort in str(d.nethack.monster_namen[p]):
			return p
	return null


## Vom Monster (Name enthält wort) weg gehen, damit es ganz ins Bild passt: je Schritt das freie Bodenfeld,
## das am weitesten von allen Monstern weg ist.
static func _abstand_nehmen(d, n: int) -> void:
	for i in n:
		var monster: Array = d.nethack.monster_namen.keys()
		var bester := Vector2i.ZERO
		var best_wert := -1.0
		for r in TASTEN:
			var q: Vector2i = d.feld + r
			if not str(d.gedaechtnis.get(q, " ")) in ".#<>{_":
				continue
			if q in monster:
				continue
			var w := 0.0
			for m in monster:
				w += minf(Vector2(q - m).length(), 6.0)
			if w > best_wert:
				best_wert = w
				bester = r
		if bester == Vector2i.ZERO:
			return
		d.taste_senden(ord(TASTEN[bester]))
		await _warten(0.7)
		if "Really attack" in d.meldung or "--More--" in d.meldung:
			d.taste_senden(27)
			await _warten(0.4)


## Zauberer-Befehl ^V mit Menü (?): zur Sonderebene, deren Zeile das Wort enthält.
static func _teleport(d, wort: String) -> bool:
	d.taste_senden(22)
	await _warten(0.8)
	for c in "?":
		d.taste_senden(c.unicode_at(0))
	d.taste_senden(13)
	await _warten(1.2)
	var taste := ""
	for seite in 4:
		for z in d.rogue.raster:
			if wort.to_lower() in z.to_lower():
				var r := RegEx.create_from_string("([a-zA-Z]) - ").search(z)
				if r:
					taste = r.get_string(1)
					break
		if taste != "":
			break
		d.taste_senden(ord(">"))   # nächste Menüseite
		await _warten(0.8)
	d.steuerung._liste_zu()
	if taste == "":
		print("REDDIT kein Menüeintrag für ", wort, ": ", Array(d.rogue.raster).filter(func(z): return z.strip_edges() != "").slice(0, 30))
		d.taste_senden(27)
		await _warten(0.6)
		return false
	d.taste_senden(ord(taste))
	await _warten(0.8)
	if d.textseite:
		d.taste_senden(13)   # Menü bestätigen, falls es offen bleibt
	await _warten(2.0)
	for i in 4:
		if "--More--" in d.meldung or d.textseite:
			d.taste_senden(32)
			await _warten(0.6)
	d.steuerung._liste_zu()
	print("REDDIT teleport ", wort, " ebene=", d.ebene, " meldung=", d.meldung)
	return true


# ---------------------------------------------------------------- Hilfen

## Sperrdateien eines NetHack-Spielernamens entfernen (nur Testnamen wie "wizard").
static func _sperren_weg(name: String) -> void:
	var dir := OS.get_environment("LOCALAPPDATA").path_join("NetHack/3.6")
	for f in DirAccess.get_files_at(dir):
		var t := f.split(".")
		if t.size() == 2 and t[0] == name and t[1].is_valid_int():
			DirAccess.remove_absolute(dir.path_join(f))


static func _vorspann_zu(d) -> void:
	var v = Vorspann.aktiv(d)
	if v:
		v._seit = 10.0
		v.schliessen()


## Kamera zum Feld p drehen (gier 0 = Norden, -PI/2 = Osten), leicht nach unten.
static func _hinsehen(d, p: Vector2i) -> void:
	var r := Vector2(p - d.feld)
	if r == Vector2.ZERO:
		return
	if d._drehen:
		d._drehen.kill()
	d.gier = atan2(-r.x, -r.y)
	d.spieler.rotation.y = d.gier
	d.nick = -0.06
	d.kamera.rotation.x = d.nick


static func _warten(s: float) -> void:
	await baum.create_timer(s).timeout


static func _marke(name: String) -> void:
	var t := Engine.get_frames_drawn() / 30.0
	marken += "%.2f %s\n" % [t, name]
	print("REDDIT marke ", name, " ", t)


static func _foto(name: String) -> void:
	await RenderingServer.frame_post_draw
	baum.root.get_viewport().get_texture().get_image().save_png(ordner.path_join(name + ".png"))
	print("REDDIT foto ", name)
