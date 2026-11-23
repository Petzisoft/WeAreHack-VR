## Entwickler-Test für Hack (1982) in der 3D-Ansicht: Vorspann zu, Figur auswürfeln lassen,
## Einleitung wegklicken, umsehen, Fotos hack_test_*.png im Projektordner. Beendet danach das Programm.
## Aufruf: Godot --path rogue-godot res://dungeon.tscn -- --spiel=hack --hacktest
extends RefCounted


static func laufen(d) -> void:
	var baum: SceneTree = d.get_tree()
	await baum.create_timer(3.0).timeout
	await _foto(d, 1)
	var vorspann = load("res://vorspann.gd").aktiv(d)
	if vorspann:
		vorspann.schliessen()
	await baum.create_timer(1.5).timeout
	await _foto(d, 2)   # Frage "Are you an experienced player?"
	d.taste_senden(ord("n"))   # nein: Hack wählt die Figur selbst
	if "--wahl" in OS.get_cmdline_user_args():
		await baum.create_timer(1.5).timeout
		await _foto(d, 9)
		print("HACKTEST liste=", d.steuerung.auswahl.visible)
	await baum.create_timer(1.5).timeout
	for i in 4:   # Einleitungstext und --More--
		d.taste_senden(32)
		await baum.create_timer(0.7).timeout
	await baum.create_timer(1.0).timeout
	print("HACKTEST feld=", d.feld, " ebene=", d.ebene, " textseite=", d.textseite, " gueltig=", d.nethack.gueltig,
			" monster=", d.nethack.monster_namen, " status=", d.anzeigen.status_label.text.replace("\n", " | "))
	await _foto(d, 3)
	d.taste_senden(ord("i"))   # Inventar soll als Auswahlliste kommen
	await baum.create_timer(1.2).timeout
	await _foto(d, 10)
	print("HACKTEST inventar liste=", d.steuerung.auswahl.visible, " art=", d.steuerung._wahl_art, " n=", d.steuerung.auswahl.eintraege.size())
	if d.steuerung.auswahl.visible:
		d.steuerung._gewaehlt()   # ersten Gegenstand wählen -> Befehlsliste
		await baum.create_timer(0.6).timeout
		await _foto(d, 11)
		print("HACKTEST aktionen=", d.steuerung.auswahl.eintraege.slice(0, 4))
		d.steuerung._abbrechen()
		await baum.create_timer(0.8).timeout
	# Gegenstandsnamen (Peter 23.11.): Bild mit Standard (aus), dann eingeschaltet, dann zurück
	var vorher: bool = load("res://spielstand.gd").gegenstandsnamen()
	await _foto(d, 20 if not vorher else 21)
	load("res://spielstand.gd").gegenstandsnamen_umschalten(baum)
	await baum.create_timer(0.3).timeout
	await _foto(d, 21 if not vorher else 20)
	print("HACKTEST namen vorher=", vorher, " schilder=", baum.get_nodes_in_group("gegenstandsname").size(),
			" sichtbar=", baum.get_nodes_in_group("gegenstandsname").filter(func(n): return n.visible).size())
	load("res://spielstand.gd").gegenstandsnamen_umschalten(baum)
	for i in 3:
		d.drehen_um(1)
		await baum.create_timer(0.7).timeout
		await _foto(d, 4 + i)
	d.rogue.stoppen()
	baum.quit()


static func _foto(d, n: int) -> void:
	await RenderingServer.frame_post_draw
	var pfad := ProjectSettings.globalize_path("res://").path_join("../hack_test_%d.png" % n).simplify_path()
	d.get_viewport().get_texture().get_image().save_png(pfad)
