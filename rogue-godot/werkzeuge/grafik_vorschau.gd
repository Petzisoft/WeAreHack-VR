## Entwickler-Werkzeug: zeigt alle Gegenstände nebeneinander in einem Testraum und macht Fotos.
## Aufruf: Godot --path rogue-godot res://werkzeuge/grafik_vorschau.tscn
extends Node3D

const Grafik = preload("res://grafik.gd")


func _ready() -> void:
	var g: Node3D = Grafik.new()
	add_child(g)
	var we := WorldEnvironment.new()
	we.environment = Grafik.umgebung()
	if "--ohnenebel" in OS.get_cmdline_user_args(): we.environment.volumetric_fog_enabled = false
	if "--ohnessao" in OS.get_cmdline_user_args():
		we.environment.ssao_enabled = false
		we.environment.ssil_enabled = false
		we.environment.ssr_enabled = false
	add_child(we)
	g.umwelt = we.environment
	var ebene_nr := 1
	for a in OS.get_cmdline_user_args():
		if a.is_valid_int():
			ebene_nr = a.to_int()
	var mats: Dictionary = g.materialien(ebene_nr)
	var gedaechtnis := {}
	for x in range(-1, 11):
		for y in range(-1, 6):
			var wand := x == -1 or x == 10 or y == -1 or y == 5
			gedaechtnis[Vector2i(x, y)] = "-" if wand else "."
			var mi := MeshInstance3D.new()
			if wand:
				var b := BoxMesh.new()
				b.size = Vector3(2, 2.6, 2)
				mi.mesh = b
				mi.position = Vector3(x * 2, 1.3, y * 2)
				mi.material_override = mats["wand"]
			elif Vector2i(x, y) != Vector2i(8, 2):
				var pl := PlaneMesh.new()
				pl.size = Vector2(2, 2)
				mi.mesh = pl
				mi.position = Vector3(x * 2, 0, y * 2)
				mi.material_override = mats["boden"]
			add_child(mi)
	g.fackeln_aktualisieren(gedaechtnis)
	g.meldung_auswerten("dropped a short bow", Vector2i(7, 1))
	g.meldung_auswerten("moved onto plate mail", Vector2i(8, 1))
	var zeichen := ["*", "*", "!", "!", "?", ")", ")", "]", "/", "=", ":", ",", "^", "*", ")", "]"]
	for i in zeichen.size():
		var p := Vector2i(1 + (i % 8), 1 + 2 * (i / 8))
		var m: Node3D = g.gegenstand(zeichen[i], p)
		if m:
			m.position = Vector3(p.x * 2, 0, p.y * 2)
			add_child(m)
	var tr: Node3D = g.gegenstand("%", Vector2i(8, 2))
	tr.position = Vector3(16, 0, 4)
	add_child(tr)
	g.monster_beginnen()
	g.monster_melden("A", Vector2i(2, 3))
	g.monster_melden("B", Vector2i(4, 3))
	g.monster_melden("C", Vector2i(6, 3))
	g.treffer_pruefen("the bat bit you")
	g.monster_fertig(Vector2i(4, 4))
	var licht: OmniLight3D = g.licht_fuer_spieler()
	var kamera := Camera3D.new()
	kamera.fov = 60
	add_child(kamera)
	kamera.add_child(licht)
	licht.position = Vector3(0, 0.2, 0)
	var ziele := [[Vector3(9, 2.2, 7.5), Vector3(9, 0, 2)], [Vector3(3, 1.4, 4.2), Vector3(4, 0, 2)],
			[Vector3(11, 1.4, 4.2), Vector3(12, 0, 2)], [Vector3(5, 1.4, 8.2), Vector3(6, 0, 6)],
			[Vector3(16, 2.0, 7.5), Vector3(16, -1, 4)], [Vector3(8, 1.55, 9.8), Vector3(8, 1.3, 4)]]
	for i in ziele.size():
		kamera.position = ziele[i][0]
		kamera.look_at(ziele[i][1])
		for f in 20:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var pfad := ProjectSettings.globalize_path("res://").path_join("../grafik-test/vorschau_e%d_%d.png" % [ebene_nr, i + 1]).simplify_path()
		get_viewport().get_texture().get_image().save_png(pfad)
	get_tree().quit()
