## Gegenstände als 3D-Modelle (CC0, modelle/gegenstaende/), dazu selbst gebaute Treppe und Ring.
## Fehlt ein Modell, bleibt der Platzhalter aus platzhalter.gd stehen.
extends RefCounted

const Masse = preload("res://raster_masse.gd")
const ModellHilfe = preload("res://grafik/modell_hilfe.gd")
const ZELLE := Masse.ZELLE

# Rogue-Zeichen -> mögliche Modelle [Datei, größte Kante in Metern, flach hinlegen]
const GEGENSTAENDE := {
	"*": [["k_coin_stack_small.glb", 0.45, false], ["k_coin_stack_medium.glb", 0.55, false],
			["k_coin_stack_large.glb", 0.7, false], ["q_CoinPouch.glb", 0.35, false]],
	"!": [["k_bottle_A_green.glb", 0.32, false], ["k_bottle_B_green.glb", 0.3, false],
			["k_bottle_C_brown.glb", 0.3, false], ["k_bottle_A_labeled_green.glb", 0.32, false],
			["k_bottle_A_brown.glb", 0.32, false]],
	"?": [["q_Scroll.glb", 0.45, false], ["q_Parchment.glb", 0.4, true]],
	"]": [["q_ArmorLeather.glb", 0.65, false], ["q_ArmorMetal.glb", 0.7, false], ["q_ArmorGolden.glb", 0.7, false]],
	"/": [["wand.gltf", 0.45, true], ["staff.gltf", 1.2, true]],
	":": [["k_plate_food_A.glb", 0.45, false], ["k_plate_food_B.glb", 0.45, false]],
	",": [["q_Necklace.glb", 0.4, true], ["q_Necklace2.glb", 0.4, true]],
	"^": [["k_floor_tile_big_spikes.glb", 1.6, false]],
}
# Bekannte Gegenstände: Rogue nennt den Namen, wenn man etwas ablegt ("dropped ...")
# oder darauf tritt ("moved onto ..."). Dann zeigen wir genau dieses Modell statt des Haufens.
const BEKANNT := [
	["two handed sword", "q_Claymore.glb", 1.3], ["long sword", "q_Sword.glb", 1.0],
	["short bow", "q_WoodenBow.glb", 1.0], ["arrow", "arrow_bundle.gltf", 0.75],
	["dagger", "dagger.gltf", 0.5], ["mace", "q_DoublesidedHammer.glb", 0.9],
	["dart", "q_Knife.glb", 0.4], ["shuriken", "q_Knife.glb", 0.4], ["spear", "q_Spear.glb", 1.6],
	["leather armor", "q_ArmorLeather.glb", 0.65], ["ring mail", "q_ArmorMetal.glb", 0.7],
	["scale mail", "q_ArmorMetal.glb", 0.7], ["chain mail", "q_ArmorMetal.glb", 0.7],
	["splint mail", "q_ArmorMetal.glb", 0.7], ["banded mail", "q_ArmorMetal.glb", 0.7],
	["plate mail", "q_ArmorGolden.glb", 0.7],
]
# Rogue zeigt jede Waffe als ")". Unbekannt -> ein Haufen aus mehreren dieser Waffen.
const WAFFEN := [["q_Sword.glb", 1.0], ["q_Sword2.glb", 0.95], ["q_Dagger.glb", 0.5], ["q_Knife.glb", 0.55],
		["q_AxeSmall.glb", 0.7], ["q_AxeDouble.glb", 0.9], ["q_Spear.glb", 1.6], ["q_Claymore.glb", 1.3],
		["q_DoublesidedHammer.glb", 0.9], ["q_WoodenBow.glb", 1.0], ["axe_1handed.gltf", 0.7],
		["sword_1handed.gltf", 0.95], ["dagger.gltf", 0.5], ["crossbow_1handed.gltf", 0.7]]

var grafik   # grafik.gd: Materialien der Ebene für den Treppenschacht
var _bekannt := {}    # Vector2i -> [Datei, Größe]
var _vorlagen := {}   # Datei -> Node3D (geladen, nicht in der Szene, zum Kopieren)


func ebene_neu() -> void:
	_bekannt.clear()


## Meldungszeile auswerten: liegt unter dem Spieler ein benannter Gegenstand?
func meldung_auswerten(meldung: String, feld: Vector2i) -> void:
	var m := meldung.to_lower()
	if not ("dropped " in m or "moved onto " in m):
		return
	for b in BEKANNT:
		if b[0] in m:
			_bekannt[feld] = [b[1], b[2]]
			return


## 3D-Modell für einen Rogue-Gegenstand, oder null (dann bleibt der Platzhalter).
## Die Auswahl hängt vom Feld ab, damit derselbe Gegenstand jedes Mal gleich aussieht.
func gegenstand(c: String, p: Vector2i) -> Node3D:
	var zufall := RandomNumberGenerator.new()
	zufall.seed = hash(p) + hash(c)
	if (c == ")" or c == "]") and _bekannt.has(p):
		var b: Array = _bekannt[p]
		var bm := _modell(b[0], b[1], c == ")")
		if bm:
			bm.rotation.y = zufall.randf() * TAU
			return bm
	if c == ")":
		return _waffenhaufen(zufall)
	if c == "=":
		return _ring()
	if c == "%":
		return _treppe()
	if not GEGENSTAENDE.has(c):
		return null
	var liste: Array = GEGENSTAENDE[c]
	var w: Array = liste[zufall.randi() % liste.size()]
	var m := _modell(w[0], w[1], w[2])
	if m:
		m.rotation.y = zufall.randf() * TAU
	return m


func _vorlage(datei: String) -> Node3D:
	if not _vorlagen.has(datei):
		var pfad := ProjectSettings.globalize_path("res://modelle/gegenstaende/" + datei)
		var szene := ModellHilfe.laden(pfad)
		if szene == null:
			push_warning("Modell fehlt: " + pfad)
		else:
			_metall_machen(szene, datei.begins_with("k_coin"))
		_vorlagen[datei] = szene
	return _vorlagen[datei]


## Die Modelle haben flache Farben. Gold- und Silbertöne bekommen echten Metallglanz,
## alles andere wird etwas matter und dunkler, damit es zum düsteren Dungeon passt.
func _metall_machen(knoten: Node, alles_gold := false) -> void:
	if knoten is MeshInstance3D:
		var mi := knoten as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var m := mi.get_active_material(i) as StandardMaterial3D
			if m == null:
				continue
			m = m.duplicate() as StandardMaterial3D
			var f := m.albedo_color
			if m.albedo_texture == null:
				var gold := f.h > 0.08 and f.h < 0.17 and f.s > 0.45 and f.v > 0.5
				var silber := f.s < 0.15 and f.v > 0.45
				if gold or silber:
					m.metallic = 0.7
					m.roughness = 0.35
				else:
					m.roughness = maxf(m.roughness, 0.75)
					m.albedo_color = f.darkened(0.15)
			elif alles_gold:
				m.metallic = 0.75
				m.roughness = 0.3
			else:
				m.roughness = maxf(m.roughness, 0.6)
			mi.set_surface_override_material(i, m)
	for k in knoten.get_children():
		_metall_machen(k, alles_gold)


## Kopie eines Modells, auf Größe gebracht, mit der Unterseite auf y = 0.
func _modell(datei: String, groesse: float, flach: bool) -> Node3D:
	var v := _vorlage(datei)
	if v == null:
		return null
	var kopie := v.duplicate() as Node3D
	var halter := Node3D.new()
	var dreh := Node3D.new()
	halter.add_child(dreh)
	dreh.add_child(kopie)
	if flach:
		dreh.rotation.x = -PI / 2.0
	var box := ModellHilfe.huelle(dreh, Transform3D.IDENTITY)
	var kante: float = maxf(box.size.x, maxf(box.size.y, box.size.z))
	if kante <= 0.0:
		return halter
	dreh.scale = Vector3.ONE * (groesse / kante)
	box = ModellHilfe.huelle(dreh, Transform3D.IDENTITY)
	dreh.position = Vector3(-box.get_center().x, -box.position.y, -box.get_center().z)
	return halter


func _waffenhaufen(zufall: RandomNumberGenerator) -> Node3D:
	var haufen := Node3D.new()
	var anzahl := zufall.randi_range(3, 5)
	for i in anzahl:
		var w: Array = WAFFEN[zufall.randi() % WAFFEN.size()]
		var m := _modell(w[0], w[1], true)
		if m == null:
			continue
		m.rotation.y = zufall.randf() * TAU
		m.position = Vector3(zufall.randf_range(-0.25, 0.25), i * 0.025, zufall.randf_range(-0.25, 0.25))
		m.rotation.z = zufall.randf_range(-0.08, 0.08)
		haufen.add_child(m)
	return haufen


## Treppe nach unten: Steinstufen in einem Schacht, unten schimmert Licht.
## (Der Boden über diesem Feld wird in dungeon_3d.gd weggelassen.)
func _treppe() -> Node3D:
	var t := Node3D.new()
	var stein: Material = grafik.aktuell.get("boden", grafik.fackeln.holz())
	var wand: Material = grafik.aktuell.get("fels", grafik.fackeln.holz())
	var stufen := 8
	var tiefe := ZELLE / stufen
	for i in stufen:
		var s := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(ZELLE * 0.9, 0.3, tiefe)
		s.mesh = b
		s.position = Vector3(0, -0.15 - (i + 1) * 0.3, -ZELLE / 2.0 + tiefe * (i + 0.5))
		s.material_override = stein
		t.add_child(s)
	# Schachtwände links, rechts, hinten und vorne
	for seite in [Vector3(-1, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 0, 1)]:
		var w := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.1 if seite.x != 0 else ZELLE, 3.0, ZELLE if seite.x != 0 else 0.1)
		w.mesh = b
		w.position = seite * (ZELLE / 2.0 - 0.05) + Vector3(0, -1.5, 0)
		w.material_override = wand
		t.add_child(w)
	var licht := OmniLight3D.new()
	licht.position = Vector3(0, -2.2, ZELLE * 0.3)
	licht.omni_range = 3.0
	licht.light_energy = 1.5
	licht.light_color = Color(0.4, 0.75, 1.0)
	t.add_child(licht)
	return t


## Ring: selbst gebaut (Goldreif mit leuchtendem Stein), es gibt kein freies Modell.
func _ring() -> Node3D:
	var r := Node3D.new()
	var reif := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.045
	tm.outer_radius = 0.065
	reif.mesh = tm
	reif.rotation.x = PI / 2.0
	reif.position.y = 0.068
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(1.0, 0.78, 0.34)
	gold.metallic = 1.0
	gold.roughness = 0.25
	reif.material_override = gold
	r.add_child(reif)
	var stein := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.022
	sm.height = 0.04
	stein.mesh = sm
	stein.position = Vector3(0, 0.14, 0)
	var rot := StandardMaterial3D.new()
	rot.albedo_color = Color(0.8, 0.05, 0.1)
	rot.emission_enabled = true
	rot.emission = Color(1.0, 0.1, 0.15)
	rot.emission_energy_multiplier = 2.5
	stein.material_override = rot
	r.add_child(stein)
	return r
