## Test für das Aufstell-Werkzeug der Galerie (Tasten halten). Aufruf:
## Godot --path rogue-godot --script res://werkzeuge/aufstell_test.gd -- --spiel=hack
## Achtung: schreibt grafik/aufstellung.txt um; vorher sichern, danach zurückkopieren.
extends SceneTree


func _halten(k: Key, sekunden: float) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.physical_keycode = k
	e.pressed = true
	Input.parse_input_event(e)
	await create_timer(sekunden).timeout
	var e2 := e.duplicate() as InputEventKey
	e2.pressed = false
	Input.parse_input_event(e2)
	for i in 3:
		await process_frame


func _initialize() -> void:
	var szene: Node = (load("res://werkzeuge/monster_galerie.tscn") as PackedScene).instantiate()
	root.add_child(szene)
	await create_timer(1.0).timeout
	szene._zu(4)
	await create_timer(0.5).timeout
	await _halten(KEY_T, 0.05)
	var c: String = szene.eintraege[szene.aufstellen].c
	print("TEST aufstellen ", szene.aufstellen, " ", c)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../grafik-test/aufstell_test_1.png"))
	var t0 := Time.get_ticks_msec()
	await _halten(KEY_UP, 0.5)
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../grafik-test/aufstell_test_2.png"))
	print("TEST nach 0,5 s Pfeil hoch: ", szene.g.monster.aufstellung.get(c), "  (", Time.get_ticks_msec() - t0, " ms)")
	await _halten(KEY_R, 0.5)
	print("TEST nach 0,5 s R: Höhe ", szene.g.monster.hoehe_wert(c))
	await _halten(KEY_I, 0.5)
	print("TEST nach 0,5 s I: verschoben ", szene.g.monster.versatz_wert(c))
	print("TEST Datei ", FileAccess.get_file_as_string("res://grafik/aufstellung.txt").strip_edges().replace("\n", " / "))
	await _halten(KEY_Z, 0.05)
	print("TEST nach Z ", szene.g.monster.aufstellung.has(c))
	await _halten(KEY_T, 0.05)
	await _halten(KEY_N, 0.05)
	print("TEST N springt: ", szene._aktuell())
	quit()
