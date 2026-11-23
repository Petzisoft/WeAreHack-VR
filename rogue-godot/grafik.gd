## Grafik-Paket: das Aussehen des Dungeons. Die Spiellogik steht in dungeon_3d.gd, hier nur Optik.
## Selbst erledigt: Umgebung (Licht, Nebel), Spielerfackel und Wand-/Bodenmaterialien nach Tiefe.
## Die Teile in grafik/: fackeln.gd, gegenstaende.gd, monster.gd, waffentoene.gd, fuehler.gd.
## Texturen liegen als JPG in res://texturen (<name>_diff/_nor_gl/_arm.jpg, Poly Haven, CC0) und werden
## zur Laufzeit geladen (kein Godot-Import nötig, damit das Paket ohne Editor-Schritt läuft).
extends Node3D

const Fackeln = preload("res://grafik/fackeln.gd")
const Gegenstaende = preload("res://grafik/gegenstaende.gd")
const Monster = preload("res://grafik/monster.gd")
const Waffentoene = preload("res://grafik/waffentoene.gd")
const Fuehler = preload("res://grafik/fuehler.gd")

# Die Optik hängt von der Tiefe ab: oben Holz-Bergwerk, dann Felsstollen, dann gemauertes Verlies,
# ganz unten dunkle Gruft (Peters Wunsch). Innerhalb eines Themas wechselt es von Ebene zu Ebene.
const THEMEN := [
	{"bis": 4, "name": "bergwerk", "stuetzen": true, "nebel": 0.02, "licht": Color(1.0, 0.72, 0.42), "reichweite": 11.0, "fackel_abstand": 5,
		"waende": ["raw_plank_wall", "weathered_planks", "old_planks_02", "wood_planks_dirt"],
		"boeden": ["dirt", "brown_mud_02", "stony_dirt_path", "rock_ground_02"],
		"gang": ["rocky_trail", "dirt"], "fels": ["excavated_soil_wall", "rock_ground_02"], "decke": ["dark_planks", "excavated_soil_wall"]},
	{"bis": 9, "name": "stollen", "stuetzen": false, "nebel": 0.025, "licht": Color(1.0, 0.72, 0.45), "reichweite": 11.0, "fackel_abstand": 7,
		"waende": ["rustic_stone_wall", "stacked_stone_wall", "stone_wall", "old_stone_wall", "medieval_wall_01"],
		"boeden": ["rock_tile_floor", "stone_floor", "cobblestone_floor_08"],
		"gang": ["rock_ground", "rocky_trail"], "fels": ["quarry_wall", "rock_wall"], "decke": ["rock_face", "quarry_wall"]},
	{"bis": 17, "name": "verlies", "stuetzen": false, "nebel": 0.032, "licht": Color(1.0, 0.68, 0.42), "reichweite": 10.0, "fackel_abstand": 8,
		"waende": ["castle_brick_07", "medieval_blocks_02", "castle_brick_01", "medieval_blocks_03", "stone_wall_04", "stone_block_wall", "large_sandstone_blocks"],
		"boeden": ["monastery_stone_floor", "stone_tiles_02", "medieval_blocks_05", "cobblestone_floor_04", "worn_tile_floor"],
		"gang": ["stony_dirt_path", "rock_ground"], "fels": ["rock_wall", "rock_face"], "decke": ["rock_wall", "rock_face"]},
	{"bis": 99, "name": "gruft", "stuetzen": false, "nebel": 0.045, "licht": Color(0.85, 0.72, 0.62), "reichweite": 8.5, "fackel_abstand": 11,
		"waende": ["defense_wall", "castle_wall_slates", "dark_brick_wall", "mossy_stone_wall"],
		"boeden": ["patterned_cobblestone", "worn_tile_floor", "rock_tile_floor"],
		"gang": ["rock_ground"], "fels": ["dark_rock"], "decke": ["dark_rock"]},
]
const HOLZ := "wooden_gate"   # Türsturz

var thema: Dictionary = THEMEN[0]
var umwelt: Environment        # wird von dungeon_3d.gd gesetzt, damit der Nebel zur Tiefe passt
var aktuell := {}              # Materialsatz der aktuellen Ebene ("wand", "boden" ...)
var spieler_licht: OmniLight3D
var fuehler := Fuehler.new()
var fackeln := Fackeln.new()
var gegenstaende := Gegenstaende.new()
var monster := Monster.new()
var waffentoene := Waffentoene.new()
var _bilder := {}              # Dateiname -> ImageTexture (Zwischenspeicher)
var _zeit := 0.0


func _init() -> void:
	fackeln.grafik = self
	gegenstaende.grafik = self
	monster.fuehler = fuehler
	waffentoene.fuehler = fuehler
	add_child(waffentoene)
	add_child(fackeln)
	add_child(monster)


# ---------------------------------------------------------------- Umgebung und Spielerlicht

static func umgebung() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.36, 0.45)
	env.ambient_light_energy = 0.12
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.1
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 2.5
	env.ssil_enabled = true
	env.ssr_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.2
	# Volumetrischer Nebel: Lichtkegel der Fackeln werden in der Luft sichtbar
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.035
	env.volumetric_fog_albedo = Color(0.75, 0.72, 0.68)
	env.volumetric_fog_length = 40.0
	env.volumetric_fog_ambient_inject = 0.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.0, 0.0, 0.0)
	env.fog_density = 0.02
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.9
	env.adjustment_contrast = 1.08
	return env


## Die Fackel in der Hand: warm, mit weichen Schatten und leichtem Flackern.
func licht_fuer_spieler() -> OmniLight3D:
	spieler_licht = OmniLight3D.new()
	spieler_licht.position = Vector3(0.35, 1.75, 0.1)
	spieler_licht.omni_range = 11.0
	spieler_licht.omni_attenuation = 1.4
	spieler_licht.light_energy = 2.2
	spieler_licht.light_color = Color(1.0, 0.72, 0.42)
	spieler_licht.shadow_enabled = true
	spieler_licht.shadow_blur = 1.5
	spieler_licht.light_volumetric_fog_energy = 0.6
	return spieler_licht


func _process(delta: float) -> void:
	_zeit += delta
	if spieler_licht:
		spieler_licht.light_energy = 2.2 + sin(_zeit * 7.0) * 0.1 + sin(_zeit * 19.0) * 0.07


# ---------------------------------------------------------------- Materialien

func _bild(datei: String, normalmap := false) -> Texture2D:
	if _bilder.has(datei):
		return _bilder[datei]
	var pfad := ProjectSettings.globalize_path("res://texturen/" + datei)
	var img := Image.load_from_file(pfad)
	if img == null or img.is_empty():
		push_warning("Textur fehlt: " + pfad)
		_bilder[datei] = null
		return null
	if normalmap:
		img.convert(Image.FORMAT_RGB8)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_bilder[datei] = tex
	return tex


## Steinmaterial aus einem Poly-Haven-Satz; fehlt die Textur, eine schlichte Ersatzfarbe.
func stein(name: String, massstab: float, ersatzfarbe: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var diff := _bild(name + "_diff.jpg")
	if diff == null:
		m.albedo_color = ersatzfarbe
		m.roughness = 0.95
		return m
	m.albedo_texture = diff
	m.normal_enabled = true
	m.normal_texture = _bild(name + "_nor_gl.jpg", true)
	m.normal_scale = 1.3
	var arm := _bild(name + "_arm.jpg")  # R = Umgebungsverdeckung, G = Rauheit, B = Metall
	m.ao_enabled = true
	m.ao_texture = arm
	m.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.ao_light_affect = 0.6
	m.roughness_texture = arm
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	m.roughness = 1.0
	m.metallic_texture = arm
	m.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	m.metallic = 1.0
	# Weltkoordinaten statt UV: Fugen laufen nahtlos über alle Wandblöcke hinweg
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 8.0
	m.uv1_scale = Vector3.ONE * massstab
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


## NetHack: eigene Optik für Sondergebiete, nach Zweig-Nummer der Sonde (Reihenfolge in nethack-src/dat/dungeon.def:
## 0 Dungeons of Doom, 1 Gehennom, 2 Gnomenminen, 3 Quest, 4 Sokoban, 5 Fort Ludios, 6 Vlads Turm, 7 Ebenen).
## Texturen Poly Haven (CC0), Peter 21.11.2026. Zweige ohne Eintrag nehmen die Rogue-Themen nach Tiefe.
const ZWEIG_THEMEN := {
	2: {"name": "minen", "stuetzen": true, "nebel": 0.03, "licht": Color(1.0, 0.7, 0.4), "reichweite": 10.0, "fackel_abstand": 6,
		"waende": ["cliff_side", "rock_boulder_cracked", "mossy_rock", "rock_pitted_mossy"],
		"boeden": ["brown_mud_rocks_01", "red_laterite_soil_stones", "rock_ground_02"],
		"gang": ["brown_mud_rocks_01", "rocky_trail"], "fels": ["cliff_side", "rock_wall"], "decke": ["rock_face", "cliff_side"]},
	4: {"name": "sokoban", "stuetzen": false, "nebel": 0.015, "licht": Color(1.0, 0.85, 0.65), "reichweite": 12.0, "fackel_abstand": 5,
		"waende": ["granite_wall", "white_sandstone_blocks_02", "sandstone_blocks_08"],
		"boeden": ["granite_tile", "marble_tiles"],
		"gang": ["granite_tile"], "fels": ["granite_wall"], "decke": ["granite_wall"]},
	1: {"name": "gehennom", "stuetzen": false, "nebel": 0.05, "licht": Color(1.0, 0.5, 0.3), "reichweite": 9.0, "fackel_abstand": 9,
		"waende": ["red_sandstone_wall", "terrain_red_01", "dark_rock"],
		"boeden": ["burned_ground_01", "cracked_red_ground", "red_mud_stones"],
		"gang": ["burned_ground_01"], "fels": ["dark_rock"], "decke": ["dark_rock", "terrain_red_01"]},
}
var zweig := -1   # NetHack: Zweig der aktuellen Ebene (von dungeon_3d.gd gesetzt), Rogue: -1


func _thema_fuer(ebene: int) -> Dictionary:
	if ZWEIG_THEMEN.has(zweig):
		return ZWEIG_THEMEN[zweig]
	for t in THEMEN:
		if ebene <= int(t.bis):
			return t
	return THEMEN[-1]


## Materialsatz für eine Ebene (1, 2, 3 ...): Thema nach Tiefe, innerhalb des Themas wechselnd.
## Stellt auch Nebel und Spielerlicht auf das Thema ein.
func materialien(ebene: int) -> Dictionary:
	thema = _thema_fuer(ebene)
	if umwelt:
		umwelt.volumetric_fog_density = float(thema.nebel) * 1.4
		umwelt.fog_density = thema.nebel
	if spieler_licht:
		spieler_licht.light_color = thema.licht
		spieler_licht.omni_range = thema.reichweite
	var i := maxi(ebene - 1, 0)
	var w: Array = thema.waende
	var b: Array = thema.boeden
	var g: Array = thema.gang
	var f: Array = thema.fels
	var d: Array = thema.decke
	aktuell = {
		"wand": stein(w[i % w.size()], 0.33, Color(0.62, 0.56, 0.5)),
		"boden": stein(b[i % b.size()], 0.4, Color(0.45, 0.42, 0.38)),
		"gang": stein(g[i % g.size()], 0.35, Color(0.36, 0.3, 0.24)),
		"fels": stein(f[i % f.size()], 0.25, Color(0.3, 0.28, 0.27)),
		"decke": stein(d[i % d.size()], 0.33, Color(0.25, 0.23, 0.22)),
		"tuer": stein(HOLZ, 0.5, Color(0.55, 0.33, 0.15)),
	}
	return aktuell


## Bild-Zwischenspeicher leeren: die Materialien der neuen Ebene laden ihre Texturen neu.
func zwischenspeicher_leeren() -> void:
	_bilder.clear()


## Neue Ebene: Fackeln, Holzrahmen, Monster und gemerkte Gegenstände der alten Ebene weg.
func ebene_neu() -> void:
	fackeln.ebene_neu()
	gegenstaende.ebene_neu()
	monster.ebene_neu()


# ---------------------------------------------------------------- Anschlüsse für dungeon_3d.gd

## Vor dem Start von Rogue: Werte des letzten Spiels vergessen.
func neues_spiel() -> void:
	fuehler.zuruecksetzen()


func fackeln_aktualisieren(gedaechtnis: Dictionary) -> void:
	fackeln.aktualisieren(gedaechtnis)


func gegenstand(c: String, p: Vector2i) -> Node3D:
	return gegenstaende.gegenstand(c, p)


func meldung_auswerten(meldung: String, feld: Vector2i) -> void:
	gegenstaende.meldung_auswerten(meldung, feld)


func treffer_pruefen(meldung: String) -> void:
	monster.treffer_pruefen(meldung)


func monster_beginnen() -> void:
	monster.beginnen()


func monster_melden(c: String, p: Vector2i, name := "") -> bool:
	return monster.melden(c, p, name)


func monster_fertig(spieler: Vector2i) -> void:
	monster.fertig(spieler)


func gang_voraus_lesen(ziel: Dictionary) -> void:
	fuehler.gaenge_lesen(ziel)
