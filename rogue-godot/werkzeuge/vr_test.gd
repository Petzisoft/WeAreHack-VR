## Entwickler-Werkzeug: prüft ohne Brille die Rechnungen von vr.gd (Laserstrahl auf die Tafel, Wurfrichtung).
## Aufruf: Godot --headless --path rogue-godot --script res://werkzeuge/vr_test.gd
extends SceneTree


func _initialize() -> void:
	_laufen.call_deferred()


func _laufen() -> void:
	var vr = load("res://vr.gd").new()
	root.add_child(vr)
	vr.cam = XRCamera3D.new()
	vr.add_child(vr.cam)
	vr.tafel_vp = SubViewport.new()
	vr.tafel_vp.size = Vector2i(1280, 800)
	vr.add_child(vr.tafel_vp)
	vr.tafel = MeshInstance3D.new()
	vr.tafel.mesh = QuadMesh.new()
	(vr.tafel.mesh as QuadMesh).size = Vector2(1.28, 0.8)
	vr.tafel.position = Vector3(0, 0, -1.0)
	vr.cam.add_child(vr.tafel)
	vr.rechts = XRController3D.new()
	vr.add_child(vr.rechts)
	await process_frame
	print("TEST Mitte: ", vr._tafel_punkt(), " (erwartet 640,400)")
	vr.rechts.position = Vector3(0.32, 0.2, 0)
	print("TEST oben rechts: ", vr._tafel_punkt(), " (erwartet 960,200)")
	vr.rechts.position = Vector3.ZERO
	vr.rechts.rotation = Vector3(0, PI, 0)
	print("TEST nach hinten: ", vr._tafel_punkt(), " (erwartet -1,-1)")
	vr.rechts.rotation = Vector3.ZERO
	print("TEST Wurf geradeaus (Blick -Z = Norden): ", vr._zeigerichtung(), " (erwartet 0,-1)")
	vr.rechts.rotation = Vector3(0, -PI / 2.0, 0)
	print("TEST Wurf nach Osten: ", vr._zeigerichtung(), " (erwartet 1,0)")
	vr.rechts.rotation = Vector3(0, -PI / 4.0, 0)
	print("TEST Wurf nach Nordosten: ", vr._zeigerichtung(), " (erwartet 1,-1)")
	quit()
