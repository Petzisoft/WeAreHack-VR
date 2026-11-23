## Entwickler-Werkzeug: stellt mehrere Monster wie auf einer Ebene auf, misst Ladezeit, Bildrate und
## Grafikspeicher, lässt sie aufwachen, angreifen und sterben und macht Fotos (grafik-test/spiel_*.png).
## Aufruf: Godot --path rogue-godot res://werkzeuge/spieltest.tscn -- D T C
extends Node3D

const Grafik = preload("res://grafik.gd")
var g: Node3D
var kuerzel: Array = []


func _ready() -> void:
	kuerzel = Array(OS.get_cmdline_user_args())
	if kuerzel.is_empty():
		kuerzel = ["D", "T", "C"]
	g = Grafik.new()
	g.fuehler.fest = true
	add_child(g)
	var we := WorldEnvironment.new()
	we.environment = Grafik.umgebung()
	add_child(we)
	g.umwelt = we.environment
	var mats: Dictionary = g.materialien(12)
	for x in range(-5, 6):
		for y in range(-6, 3):
			var mi := MeshInstance3D.new()
			var pl := PlaneMesh.new()
			pl.size = Vector2(2, 2)
			mi.mesh = pl
			mi.position = Vector3(x * 2, 0, y * 2)
			mi.material_override = mats["boden"]
			add_child(mi)
	var kamera := Camera3D.new()
	kamera.fov = 65
	add_child(kamera)
	kamera.position = Vector3(0, 1.55, 3.6)
	kamera.look_at(Vector3(0, 1.2, 0))
	kamera.add_child(g.licht_fuer_spieler())
	var start := Time.get_ticks_msec()
	await _melden(Vector2i(0, 9), 2048)
	print("TEST Monster geladen nach ", (Time.get_ticks_msec() - start) / 1000.0, " s")
	_speicher("nach Laden")
	await _warte(1.0)
	await _foto("1_ruhe")
	await _melden(Vector2i(0, 9), 8192)
	await _warte(1.0)
	await _foto("2_lauf")
	await _melden(Vector2i(0, 1), 8192)
	await _warte(1.0)
	await _foto("3_angriff")
	print("TEST neben Spieler: ", _lage())
	for runde in 3:
		g.treffer_pruefen("the " + g.monster.ROGUE_NAMEN[kuerzel[0]] + " hit you")
		await _melden(Vector2i(0, 1), 8192)
		g.treffer_pruefen("")
		await _warte(0.6)
		print("TEST Angriff ", runde, ": ", _lage())
	var bilder := 0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 3000:
		await get_tree().process_frame
		bilder += 1
	print("TEST FPS: ", bilder / 3.0)
	g.monster_beginnen()
	g.monster_fertig(Vector2i(0, 1))
	print("TEST vom Bild, wartet auf Meldung: ", g.monster._verschwunden.size())
	await _warte(0.5)
	for c in kuerzel:
		g.treffer_pruefen("you hit the " + g.monster.ROGUE_NAMEN[c] + ".  Defeated the " + g.monster.ROGUE_NAMEN[c])
	print("TEST Sterbende: ", g.monster._sterbende.size())
	await _warte(1.5)
	await _foto("4_tot")
	_speicher("Ende")
	get_tree().quit()


func _melden(spieler: Vector2i, flags: int) -> void:
	var f := {}
	g.monster_beginnen()
	for i in kuerzel.size():
		var p := Vector2i(i * 2 - kuerzel.size() + 1, 0)
		f[p] = {"c": kuerzel[i], "hp": 10, "max": 10, "flags": flags}
	g.fuehler.aktiv = true
	g.fuehler.monster = f
	for p in f:
		g.monster_melden(f[p].c, p)
	g.monster_fertig(spieler)
	await get_tree().process_frame


func _speicher(t: String) -> void:
	print("TEST ", t, ": Grafikspeicher ", int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0), " MB, Arbeitsspeicher ", int(OS.get_static_memory_usage() / 1048576.0), " MB")


func _warte(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _foto(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://").path_join("../grafik-test/spiel_%s.png" % n).simplify_path())


func _lage() -> Array:
	return g.monster.aktive.map(func(m): return [m.c, m.get("zustand", "?"), m.get("drei_d", false)])
