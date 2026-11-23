## Figuren auf dem Boden mit Namensschild: Gegenstände (als 3D-Modell aus grafik.gd, sonst schlichte Form),
## Treppe, Falle und Monster ohne Bild (farbige Kapsel).
extends RefCounted

const Masse = preload("res://raster_masse.gd")
const ZELLE := Masse.ZELLE
const MONSTER_NAMEN := {
	"A": "Aquator", "B": "Fledermaus", "C": "Zentaur", "D": "Drache", "E": "Emu",
	"F": "Fliegenfalle", "G": "Greif", "H": "Hobgoblin", "I": "Eismonster", "J": "Jabberwock",
	"K": "Falke", "L": "Kobold", "M": "Medusa", "N": "Nymphe", "O": "Ork",
	"P": "Phantom", "Q": "Quagga", "R": "Klapperschlange", "S": "Schlange", "T": "Troll",
	"U": "Einhorn", "V": "Vampir", "W": "Geist", "X": "Xeroc", "Y": "Yeti", "Z": "Zombie",
}

var grafik   # grafik.gd, liefert die echten 3D-Modelle
var _materialien := {}


## Baut die Figur für Rogue-Zeichen c auf Feld p (noch nicht in der Szene).
## name: eigenes Namensschild (NetHack: Monstername oder Brunnen, Altar ...), sonst nach Zeichen.
func bauen(c: String, p: Vector2i, name := "") -> Node3D:
	var k := Node3D.new()
	k.position = Vector3(p.x * ZELLE, 0, p.y * ZELLE)
	var mi := MeshInstance3D.new()
	var text := c
	var schild_hoehe := 0.7
	var schild_farbe := Color(0.95, 0.95, 0.85)
	var code := c.unicode_at(0)
	if code >= 65 and code <= 90:
		var farbe := Color.from_hsv(fmod((code - 65) * 0.381966, 1.0), 0.6, 0.9)
		if name != "":
			farbe = Color.from_hsv(fmod(absi(name.hash() % 1000) * 0.381966, 1.0), 0.6, 0.9)
		var kapsel := CapsuleMesh.new()
		kapsel.radius = 0.35
		kapsel.height = 1.5
		mi.mesh = kapsel
		mi.position.y = 0.75
		mi.material_override = _material(farbe)
		text = name if name != "" else c + "\n" + MONSTER_NAMEN.get(c, "")
		schild_hoehe = 1.95
		schild_farbe = farbe.lightened(0.3)
	else:
		var farbe := Color(0.9, 0.9, 0.9)
		var leuchtet := false
		var mesh: Mesh
		match c:
			"!":
				var m := SphereMesh.new(); m.radius = 0.18; m.height = 0.36
				mesh = m; farbe = Color(0.7, 0.3, 0.9); leuchtet = true; mi.position.y = 0.2; text = "Trank"
			"?":
				var m := BoxMesh.new(); m.size = Vector3(0.4, 0.05, 0.3)
				mesh = m; farbe = Color(0.95, 0.9, 0.75); mi.position.y = 0.03; text = "Schriftrolle"
			")":
				var m := BoxMesh.new(); m.size = Vector3(0.08, 0.08, 0.9)
				mesh = m; farbe = Color(0.75, 0.75, 0.8); mi.position.y = 0.05; mi.rotation.y = PI / 4; text = "Waffe"
			"]":
				var m := BoxMesh.new(); m.size = Vector3(0.5, 0.5, 0.25)
				mesh = m; farbe = Color(0.55, 0.6, 0.7); mi.position.y = 0.25; text = "Rüstung"
			"=":
				var m := TorusMesh.new(); m.inner_radius = 0.08; m.outer_radius = 0.15
				mesh = m; farbe = Color(1.0, 0.8, 0.2); leuchtet = true; mi.position.y = 0.16; mi.rotation.x = PI / 2; text = "Ring"
			"/":
				var m := CylinderMesh.new(); m.top_radius = 0.03; m.bottom_radius = 0.03; m.height = 0.8
				mesh = m; farbe = Color(0.55, 0.35, 0.2); mi.position.y = 0.04; mi.rotation.z = PI / 2; text = "Zauberstab"
			"*":
				var m := CylinderMesh.new(); m.top_radius = 0.2; m.bottom_radius = 0.28; m.height = 0.12
				mesh = m; farbe = Color(1.0, 0.82, 0.25); leuchtet = true; mi.position.y = 0.06; text = "Gold"
			":":
				var m := BoxMesh.new(); m.size = Vector3(0.3, 0.2, 0.3)
				mesh = m; farbe = Color(0.75, 0.45, 0.2); mi.position.y = 0.1; text = "Nahrung"
			",":
				var m := TorusMesh.new(); m.inner_radius = 0.1; m.outer_radius = 0.17
				mesh = m; farbe = Color(0.3, 0.95, 0.95); leuchtet = true; mi.position.y = 0.4; text = "Amulett"
			"%":
				var m := BoxMesh.new(); m.size = Vector3(1.4, 0.04, 1.4)
				mesh = m; farbe = Color(0.25, 0.9, 0.4); leuchtet = true; mi.position.y = 0.03; text = "Treppe ▼"
			"~":   # NetHack: besonderes Gelände (Brunnen, Altar, Thron ...), Text kommt als name
				var m := CylinderMesh.new(); m.top_radius = 0.35; m.bottom_radius = 0.45; m.height = 0.5
				mesh = m; farbe = Color(0.5, 0.7, 1.0); leuchtet = true; mi.position.y = 0.25
			"^":
				var m := BoxMesh.new(); m.size = Vector3(1.2, 0.03, 1.2)
				mesh = m; farbe = Color(0.85, 0.15, 0.1); leuchtet = true; mi.position.y = 0.02; text = "Falle"
			_:
				var m := BoxMesh.new(); m.size = Vector3(0.3, 0.3, 0.3)
				mesh = m; mi.position.y = 0.15
		mi.mesh = mesh
		mi.material_override = _material(farbe, leuchtet)
		schild_farbe = farbe.lightened(0.4)
		if name != "":
			text = name
		var modell: Node3D = grafik.gegenstand(c, p)  # echtes 3D-Modell statt der schlichten Form
		if modell:
			k.add_child(modell)
			mi.mesh = null
	k.add_child(mi)
	var schild := Label3D.new()
	schild.text = text
	# Gegenstände: Namensschild nur, wenn eingeschaltet (Startmenü/Befehlsmenü, Standard aus).
	# Monster ohne Modell, Treppe, Falle und Gelände (Brunnen, Altar ...) behalten ihr Schild.
	if not (code >= 65 and code <= 90) and not c in "%~^":
		schild.add_to_group("gegenstandsname")
		schild.visible = preload("res://spielstand.gd").gegenstandsnamen()
	schild.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	schild.font_size = 64
	schild.outline_size = 14
	schild.pixel_size = 0.004 if name == "" else 0.0022   # NetHack-Namen sind lang: kleiner, wirkt weiter weg (Peter 21.11.)
	schild.modulate = schild_farbe
	schild.position.y = schild_hoehe
	k.add_child(schild)
	return k


func _material(farbe: Color, leuchtet := false) -> StandardMaterial3D:
	var schluessel := str(farbe) + str(leuchtet)
	if not _materialien.has(schluessel):
		var m := StandardMaterial3D.new()
		m.albedo_color = farbe
		m.roughness = 0.6
		if leuchtet:
			m.emission_enabled = true
			m.emission = farbe
			m.emission_energy_multiplier = 0.8
		_materialien[schluessel] = m
	return _materialien[schluessel]
