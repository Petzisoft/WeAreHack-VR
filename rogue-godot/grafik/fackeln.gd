## Fackeln an den Raumwänden (mit Licht, Schatten und flackernder Partikelflamme)
## und im Bergwerk Holzrahmen in den Gängen. Beides bleibt pro Ebene bestehen.
extends Node3D

const Masse = preload("res://raster_masse.gd")
const ZELLE := Masse.ZELLE
const WANDHOEHE := Masse.WANDHOEHE
const FACKELN_MAX := 24   # Obergrenze für Lichter mit Schatten

var grafik   # grafik.gd: aktuelles Thema und Steinmaterialien
var _fackeln := {}        # Vector2i (Wandfeld) -> Node3D
var _lichter: Array[OmniLight3D] = []
var _stuetzen := {}       # Vector2i (Gangfeld) -> Node3D
var _mat_cache := {}
var _zeit := 0.0


func ebene_neu() -> void:
	for st in _stuetzen.values():
		st.queue_free()
	_stuetzen.clear()
	for f in _fackeln.values():
		f.queue_free()
	_fackeln.clear()
	_lichter.clear()


## Nach jedem Rogue-Bild: neue Wände bekommen Fackeln, neue Gänge im Bergwerk Holzrahmen.
func aktualisieren(gedaechtnis: Dictionary) -> void:
	_stuetzen_aktualisieren(gedaechtnis)
	if _fackeln.size() >= FACKELN_MAX:
		return
	var abstand: int = grafik.thema.fackel_abstand   # ungefähr jede n-te Wand bekommt eine Fackel
	for p: Vector2i in gedaechtnis:
		var c: String = gedaechtnis[p]
		if c != "-" and c != "|":
			continue
		if _fackeln.has(p) or posmod(p.x * 73 + p.y * 151, abstand) != 0:
			continue
		# an der Seite der Wand, an der Raumboden liegt
		for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			if gedaechtnis.get(p + d, "") == ".":
				_fackel_bauen(p, d)
				break
		if _fackeln.size() >= FACKELN_MAX:
			return


## Bergwerk: Holzrahmen (zwei Pfosten und ein Querbalken) quer zu geraden Gangstücken.
func _stuetzen_aktualisieren(gedaechtnis: Dictionary) -> void:
	if not grafik.thema.stuetzen:
		return
	var holz: Material = null
	var offen := func(q: Vector2i) -> bool: return gedaechtnis.get(q, "") in ["#", "+"]
	for p: Vector2i in gedaechtnis:
		if gedaechtnis[p] != "#" or _stuetzen.has(p) or posmod(p.x * 31 + p.y * 17, 3) != 0:
			continue
		# Nur auf geraden Stücken: an Ecken und Abzweigen stünde der Rahmen sonst im Weg.
		var ost_west: bool = offen.call(p + Vector2i(1, 0)) and offen.call(p + Vector2i(-1, 0))
		var nord_sued: bool = offen.call(p + Vector2i(0, 1)) and offen.call(p + Vector2i(0, -1))
		var seitlich_x: bool = offen.call(p + Vector2i(1, 0)) or offen.call(p + Vector2i(-1, 0))
		var seitlich_y: bool = offen.call(p + Vector2i(0, 1)) or offen.call(p + Vector2i(0, -1))
		if not ((ost_west and not seitlich_y) or (nord_sued and not seitlich_x)):
			continue
		if holz == null:
			holz = grafik.stein("dark_planks", 0.8, Color(0.3, 0.2, 0.12))
		var k := Node3D.new()
		k.position = Vector3(p.x * ZELLE, 0, p.y * ZELLE)
		k.rotation.y = 0.0 if ost_west else PI / 2.0
		add_child(k)
		for seite in [-1.0, 1.0]:
			k.add_child(_balken(Vector3(0.22, WANDHOEHE, 0.22), Vector3(0, WANDHOEHE / 2.0, seite * (ZELLE / 2.0 - 0.12)), holz))
		k.add_child(_balken(Vector3(0.26, 0.24, ZELLE), Vector3(0, WANDHOEHE - 0.14, 0), holz))
		_stuetzen[p] = k


func _balken(groesse: Vector3, ort: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = groesse
	mi.mesh = bm
	mi.position = ort
	mi.material_override = mat
	return mi


func _fackel_bauen(p: Vector2i, d: Vector2i) -> void:
	var k := Node3D.new()
	var mitte := Vector3(p.x * ZELLE, 0, p.y * ZELLE)
	k.position = mitte + Vector3(d.x, 0, d.y) * (ZELLE * 0.5 + 0.02)
	k.look_at_from_position(k.position, k.position + Vector3(d.x, 0, d.y), Vector3.UP)
	add_child(k)
	# Halterung und Stab (selbst gebaut, schlichtes Eisen und Holz)
	k.add_child(_balken(Vector3(0.12, 0.25, 0.06), Vector3(0, 1.65, -0.03), _eisen()))
	var stab := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.045
	sm.bottom_radius = 0.03
	sm.height = 0.55
	stab.mesh = sm
	stab.position = Vector3(0, 1.8, -0.16)
	stab.rotation.x = -0.45
	stab.material_override = holz()
	k.add_child(stab)
	var flamme := _feuer()
	flamme.position = Vector3(0, 2.08, -0.28)
	k.add_child(flamme)
	var licht := OmniLight3D.new()
	licht.position = Vector3(0, 2.15, -0.45)
	licht.omni_range = 8.0
	licht.omni_attenuation = 1.6
	licht.light_energy = 2.4
	licht.light_color = Color(1.0, 0.6, 0.28)
	licht.shadow_enabled = true
	licht.shadow_blur = 2.0
	licht.light_volumetric_fog_energy = 1.4
	licht.distance_fade_enabled = true
	licht.distance_fade_begin = 28.0
	licht.distance_fade_length = 8.0
	licht.set_meta("phase", randf() * 100.0)
	k.add_child(licht)
	_lichter.append(licht)
	_fackeln[p] = k


func _eisen() -> StandardMaterial3D:
	if not _mat_cache.has("eisen"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.12, 0.11, 0.1)
		m.metallic = 0.8
		m.roughness = 0.55
		_mat_cache["eisen"] = m
	return _mat_cache["eisen"]


## Dunkles Holz (Fackelstab; auch Ersatz, wenn noch kein Ebenen-Material da ist).
func holz() -> StandardMaterial3D:
	if not _mat_cache.has("holz"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.25, 0.15, 0.08)
		m.roughness = 0.9
		_mat_cache["holz"] = m
	return _mat_cache["holz"]


## Flamme aus aufsteigenden, leuchtenden Partikeln (selbst gebaut, ohne Bilddatei).
func _feuer() -> GPUParticles3D:
	if not _mat_cache.has("feuer_proz"):
		var pm := ParticleProcessMaterial.new()
		pm.direction = Vector3.UP
		pm.spread = 12.0
		pm.initial_velocity_min = 0.25
		pm.initial_velocity_max = 0.5
		pm.gravity = Vector3(0, 0.6, 0)
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 0.04
		pm.scale_min = 0.6
		pm.scale_max = 1.1
		var kurve := Curve.new()
		kurve.add_point(Vector2(0, 0.6))
		kurve.add_point(Vector2(0.3, 1.0))
		kurve.add_point(Vector2(1, 0.0))
		var kt := CurveTexture.new()
		kt.curve = kurve
		pm.scale_curve = kt
		var farben := Gradient.new()
		farben.set_color(0, Color(1.0, 0.85, 0.45, 1.0))
		farben.set_color(1, Color(0.8, 0.12, 0.02, 0.0))
		farben.add_point(0.4, Color(1.0, 0.45, 0.1, 0.9))
		var gt := GradientTexture1D.new()
		gt.gradient = farben
		pm.color_ramp = gt
		_mat_cache["feuer_proz"] = pm
		# weicher runder Fleck als Partikelbild
		var fleck := GradientTexture2D.new()
		fleck.fill = GradientTexture2D.FILL_RADIAL
		fleck.fill_from = Vector2(0.5, 0.5)
		fleck.fill_to = Vector2(0.5, 0.0)
		var g2 := Gradient.new()
		g2.set_color(0, Color(1, 1, 1, 1))
		g2.set_color(1, Color(1, 1, 1, 0))
		fleck.gradient = g2
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		mat.vertex_color_use_as_albedo = true
		mat.albedo_texture = fleck
		mat.albedo_color = Color(2.5, 2.0, 1.6)
		var quad := QuadMesh.new()
		quad.size = Vector2(0.14, 0.14)
		quad.material = mat
		_mat_cache["feuer_mesh"] = quad
	var p := GPUParticles3D.new()
	p.amount = 40
	p.lifetime = 0.55
	p.process_material = _mat_cache["feuer_proz"]
	p.draw_pass_1 = _mat_cache["feuer_mesh"]
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-0.5, -0.2, -0.5), Vector3(1, 1.2, 1))
	return p


func _process(delta: float) -> void:
	_zeit += delta
	for l in _lichter:
		var ph: float = l.get_meta("phase")
		l.light_energy = 2.4 + sin(_zeit * 9.0 + ph) * 0.18 + sin(_zeit * 23.0 + ph * 1.7) * 0.12
