## Entwickler-Test: Glas-Figur (Glasdurchbohrer) vor einer Wand fotografieren -> ../glas_test.png
extends SceneTree


func _init() -> void:
	var welt := Node3D.new()
	root.add_child(welt)
	var m = load("res://grafik/monster.gd").new()
	welt.add_child(m)
	var fig: Node3D = m._modell3d("nh:p_Glasdurchbohrer")
	welt.add_child(fig)
	var wand := MeshInstance3D.new()
	wand.mesh = BoxMesh.new()
	(wand.mesh as BoxMesh).size = Vector3(4, 3, 0.2)
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.7, 0.4, 0.2)
	wand.material_override = wm
	wand.position = Vector3(0, 1.5, -1.2)
	welt.add_child(wand)
	var licht := OmniLight3D.new()
	licht.position = Vector3(1, 2, 2)
	licht.omni_range = 10
	licht.light_energy = 2
	welt.add_child(licht)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.0, 2.5)
	welt.add_child(cam)
	cam.make_current()
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../glas_test.png"))
	quit()
