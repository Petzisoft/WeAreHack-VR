## Entwickler-Test für die 3D-Ansicht: schaut sich um, geht, öffnet das Befehlsmenü, läuft mit W
## und speichert Fotos (selbsttest_3d_*.png im Projektordner). Beendet danach das Programm.
## Aufruf: Godot --path rogue-godot res://dungeon.tscn -- --selbsttest
extends RefCounted


static func laufen(d) -> void:
	var baum: SceneTree = d.get_tree()
	await baum.create_timer(3.0).timeout
	await _foto(d, 1)   # Vorspann mit OK-Knopf
	var vorspann = load("res://vorspann.gd").aktiv(d)
	print("SELBSTTEST vorspann da=", vorspann != null, " musik=", vorspann != null and vorspann._musik.playing)
	if vorspann:
		# wie ein Spieler: Mausklick (gedrückt und losgelassen)
		var klick := InputEventMouseButton.new()
		klick.button_index = MOUSE_BUTTON_LEFT
		klick.position = d.get_viewport().get_visible_rect().size / 2.0
		klick.pressed = true
		Input.parse_input_event(klick)
		klick = klick.duplicate()
		klick.pressed = false
		Input.parse_input_event(klick)
		await baum.create_timer(1.3).timeout
	print("SELBSTTEST vorspann zu=", load("res://vorspann.gd").aktiv(d) == null)
	# Inventar als Textseite (soll mittig stehen)
	d.taste_senden(ord("i"))
	await baum.create_timer(0.8).timeout
	await _foto(d, 8)
	d.taste_senden(ord(" "))
	await baum.create_timer(0.5).timeout
	d.drehen_um(1)
	await baum.create_timer(0.6).timeout
	await _foto(d, 2)
	var feld_vorher: Vector2i = d.feld
	d.schritt(Vector2i(0, 1), false, false)
	await baum.create_timer(0.8).timeout
	print("SELBSTTEST schritt: ", feld_vorher, " -> ", d.feld)
	print("SELBSTTEST maus aktiv=", d.steuerung.maus_aktiv, " fernzugriff=", d.steuerung.fernzugriff)
	var mb := InputEventMouseMotion.new()
	mb.relative = Vector2(-200, 0)
	mb.button_mask = MOUSE_BUTTON_MASK_LEFT
	var g0: float = d.gier
	Input.parse_input_event(mb)
	await baum.process_frame
	print("SELBSTTEST mausbewegung: gier ", g0, " -> ", d.gier)
	d.umsehen(0.5, -0.25)
	await baum.create_timer(0.3).timeout
	await _foto(d, 3)
	print("SELBSTTEST umsehen: karte.blick=", d.anzeigen.karte.blick, " rot=", d.spieler.rotation.y, " gier=", d.gier, " vorwaerts=", d.richtung_fuer(Vector2i(0, 1)))
	# Controller: Essen über das Befehlsmenü -> Gegenstandsliste muss erscheinen
	d.steuerung.zuletzt_controller = true
	d.steuerung.befehlsmenue()
	await baum.create_timer(0.3).timeout
	await _foto(d, 4)
	d.steuerung.auswahl.bewegen(1)  # "Essen"
	d.steuerung._gewaehlt()
	await baum.create_timer(1.5).timeout
	await _foto(d, 5)
	print("SELBSTTEST auswahl sichtbar=", d.steuerung.auswahl.visible, " art=", d.steuerung._wahl_art, " eintraege=", d.steuerung.auswahl.eintraege)
	if d.steuerung.auswahl.visible:
		d.steuerung._gewaehlt()
	await baum.create_timer(1.0).timeout
	await _foto(d, 6)
	# W gedrückt halten -> mehrere Felder am Stück (Dauerlaufen)
	d._blick_waehlen(d.feld)
	d.steuerung.zuletzt_controller = false
	var start: Vector2i = d.feld
	var w := InputEventKey.new()
	w.keycode = KEY_W
	w.physical_keycode = KEY_W
	w.pressed = true
	d.steuerung.wasd_modus = true
	Input.parse_input_event(w)
	await baum.create_timer(1.5).timeout
	await _foto(d, 7)
	w = w.duplicate()
	w.pressed = false
	Input.parse_input_event(w)
	await baum.create_timer(0.4).timeout
	print("SELBSTTEST dauerlaufen: ", start, " -> ", d.feld, " fokus=", d.get_window().has_focus(), " meldung=", d.meldung)
	print("SELBSTTEST feld=", d.feld, " gier=", d.gier, " ebene=", d.ebene, " figuren=", d.figuren.get_child_count())
	for z in d.rogue.raster:
		if z.strip_edges() != "":
			print(z)
	# Spielende mit dem Controller verlassen: aufgeben (Q, y), dann A drücken, bis das Spiel zu Ende ist
	d.taste_senden(27)
	d.taste_senden(ord("Q"))
	await baum.create_timer(0.5).timeout
	d.taste_senden(ord("y"))
	for i in 4:
		await baum.create_timer(1.0).timeout
		var zeilen := Array(d.rogue.raster).filter(func(z): return "Press" in z or "quit" in z.to_lower())
		print("SELBSTTEST ende ", i, ": ", zeilen, " ende_meldung=", d.ende_meldung)
		if d.ende_meldung != "":
			break
		d.steuerung._knopf(JOY_BUTTON_A)
	baum.quit()


static func _foto(d, n: int) -> void:
	await RenderingServer.frame_post_draw
	var pfad := ProjectSettings.globalize_path("res://").path_join("../selbsttest_3d_%d.png" % n).simplify_path()
	d.get_viewport().get_texture().get_image().save_png(pfad)
