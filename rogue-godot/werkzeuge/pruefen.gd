## Entwickler-Werkzeug: lädt alle Spielskripte und meldet, ob sie fehlerfrei sind.
## Aufruf: Godot --headless --path rogue-godot --script res://werkzeuge/pruefen.gd
extends SceneTree

const SKRIPTE := ["res://dungeon_3d.gd", "res://anzeigen.gd", "res://platzhalter.gd", "res://grafik.gd",
		"res://grafik/fackeln.gd", "res://grafik/gegenstaende.gd", "res://grafik/monster.gd",
		"res://grafik/waffentoene.gd", "res://grafik/fuehler.gd", "res://grafik/modell_hilfe.gd",
		"res://steuerung.gd", "res://auswahl_menue.gd", "res://vr.gd", "res://rogue_verbindung.gd",
		"res://text_raster.gd", "res://rogue_anzeige.gd", "res://raster_masse.gd", "res://vorspann.gd", "res://protokoll.gd",
		"res://spiel.gd", "res://nethack_uebersetzer.gd", "res://grafik/fluessig.gd", "res://spielstand.gd"]


func _init() -> void:
	for f in SKRIPTE:
		var s := load(f) as GDScript
		print(f, " ok=", s != null and s.can_instantiate())
	quit()
