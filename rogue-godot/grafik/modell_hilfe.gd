## Hilfen für 3D-Modelle: glTF-Dateien zur Laufzeit laden (ohne Godot-Import) und Hüllquader messen.
extends RefCounted


## Lädt eine .glb/.gltf-Datei als Szene, oder null, wenn das nicht klappt.
static func laden(pfad: String) -> Node3D:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(pfad, st) == OK:
		return doc.generate_scene(st) as Node3D
	return null


## Hüllquader aller Meshes unter `knoten`, umgerechnet mit `t` (Transform des Elternknotens).
static func huelle(knoten: Node, t: Transform3D) -> AABB:
	var box := AABB()
	var erste := true
	var t2 := t * (knoten as Node3D).transform if knoten is Node3D else t
	if knoten is MeshInstance3D and (knoten as MeshInstance3D).mesh:
		box = t2 * (knoten as MeshInstance3D).mesh.get_aabb()
		erste = false
	for kind in knoten.get_children():
		var b := huelle(kind, t2)
		if b.size != Vector3.ZERO:
			box = b if erste else box.merge(b)
			erste = false
	return box


## Wie huelle, aber aus den echten Eckpunkten (genau auch bei gedrehten Modellen, dafür langsamer).
static func huelle_genau(knoten: Node, t: Transform3D) -> AABB:
	var box := AABB()
	var erste := true
	var t2 := t * (knoten as Node3D).transform if knoten is Node3D else t
	if knoten is MeshInstance3D and (knoten as MeshInstance3D).mesh:
		var mesh := (knoten as MeshInstance3D).mesh
		for i in mesh.get_surface_count():
			for v in mesh.surface_get_arrays(i)[Mesh.ARRAY_VERTEX]:
				var q: Vector3 = t2 * v
				if erste:
					box = AABB(q, Vector3.ZERO)
					erste = false
				else:
					box = box.expand(q)
	for kind in knoten.get_children():
		var b := huelle_genau(kind, t2)
		if b.size != Vector3.ZERO:
			box = b if erste else box.merge(b)
			erste = false
	return box


## Mitte (x, z) aller Eckpunkte unterhalb der Höhe `bis_y` (z. B. die Füße), gemessen mit dem Transform
## von `knoten`. Große Meshes werden nur stichprobenartig gelesen (höchstens etwa 40000 Punkte).
## Findet sich nichts, kommt `sonst` zurück.
static func fuss_mitte(knoten: Node, bis_y: float, sonst: Vector2) -> Vector2:
	var summe := Vector3.ZERO   # x, z, Anzahl
	summe = _fuss_summe(knoten, Transform3D.IDENTITY, bis_y, summe)
	return Vector2(summe.x / summe.z, summe.y / summe.z) if summe.z > 0.0 else sonst


static func _fuss_summe(knoten: Node, t: Transform3D, bis_y: float, summe: Vector3) -> Vector3:
	var t2 := t * (knoten as Node3D).transform if knoten is Node3D else t
	if knoten is MeshInstance3D and (knoten as MeshInstance3D).mesh:
		var mesh := (knoten as MeshInstance3D).mesh
		for i in mesh.get_surface_count():
			var punkte: PackedVector3Array = mesh.surface_get_arrays(i)[Mesh.ARRAY_VERTEX]
			var schritt := maxi(1, int(punkte.size() / 40000.0))
			for j in range(0, punkte.size(), schritt):
				var q: Vector3 = t2 * punkte[j]
				if q.y <= bis_y:
					summe += Vector3(q.x, q.z, 1.0)
	for kind in knoten.get_children():
		summe = _fuss_summe(kind, t2, bis_y, summe)
	return summe


## Höhe der Füße vorn (Figur blickt nach -Z): 1-%-Quantil der Eckpunkte in der vorderen Hälfte der untersten 8 %.
## Für Figuren mit Schleppe (die Schleppe hinten liegt tiefer als die Füße). Gemessen mit dem Transform von `knoten`.
static func fuss_hoehe_vorn(knoten: Node, kiste: AABB) -> float:
	var ys := PackedFloat32Array()
	_vorn_sammeln(knoten, Transform3D.IDENTITY, kiste.position.y + kiste.size.y * 0.08, kiste.position.z + kiste.size.z * 0.5, ys)
	if ys.size() < 10:
		return kiste.position.y
	ys.sort()
	return ys[int(ys.size() * 0.01)]


static func _vorn_sammeln(knoten: Node, t: Transform3D, bis_y: float, mitte_z: float, ys: PackedFloat32Array) -> void:
	var t2 := t * (knoten as Node3D).transform if knoten is Node3D else t
	if knoten is MeshInstance3D and (knoten as MeshInstance3D).mesh:
		var mesh := (knoten as MeshInstance3D).mesh
		for i in mesh.get_surface_count():
			for v in mesh.surface_get_arrays(i)[Mesh.ARRAY_VERTEX]:
				var q: Vector3 = t2 * v
				if q.y <= bis_y and q.z < mitte_z:
					ys.append(q.y)
	for kind in knoten.get_children():
		_vorn_sammeln(kind, t2, bis_y, mitte_z, ys)


## Alle Eckpunkte unter `boden` (gemessen mit dem Transform von `knoten`) auf `boden` setzen: die Schleppe legt sich
## flach auf den Boden statt die Figur zu kippen (Peter 22.11.: "Die Schleppe passt sich an, nicht der Körper").
## Normalen, UV und Materialien bleiben.
static func boden_klemmen(knoten: Node, boden: float, t := Transform3D.IDENTITY) -> void:
	var t2 := t * (knoten as Node3D).transform if knoten is Node3D else t
	if knoten is MeshInstance3D and (knoten as MeshInstance3D).mesh:
		var mi := knoten as MeshInstance3D
		var alt := mi.mesh
		var neu := ArrayMesh.new()
		var inv := t2.affine_inverse()
		for i in alt.get_surface_count():
			var arr := alt.surface_get_arrays(i)
			var pts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			for j in pts.size():
				var q: Vector3 = t2 * pts[j]
				if q.y < boden:
					q.y = boden
					pts[j] = inv * q
			arr[Mesh.ARRAY_VERTEX] = pts
			neu.add_surface_from_arrays(alt.surface_get_primitive_type(i), arr)
			neu.surface_set_material(i, alt.surface_get_material(i))
		mi.mesh = neu
	for kind in knoten.get_children():
		boden_klemmen(kind, boden, t2)
