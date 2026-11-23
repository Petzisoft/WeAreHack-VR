## Entwickler-Test für die Speicherplätze: Spiel starten, in Platz 3 speichern, weiterspielen, Platz 3 laden.
## Aufruf: Godot --path rogue-godot res://dungeon.tscn -- [--spiel=nethack] --spielstandtest
## Achtung: nur starten, wenn kein anderes Rogue/NetHack läuft (Sperrdateien, Spielstand-Datei).
extends RefCounted

const Spielstand = preload("res://spielstand.gd")


static func laufen(d) -> void:
	var baum: SceneTree = d.get_tree()
	await baum.create_timer(3.0).timeout
	var vorspann = load("res://vorspann.gd").aktiv(d)
	if vorspann:
		vorspann.schliessen()
	await baum.create_timer(1.5).timeout
	if d.nethack:
		d.taste_senden(ord("y"))
		await baum.create_timer(1.5).timeout
		for i in 4:
			d.taste_senden(32)
			await baum.create_timer(0.6).timeout
	print("SPIELSTANDTEST vorher feld=", d.feld, " ebene=", d.ebene, " status=", d.anzeigen.status_label.text.replace("\n", " | "))
	d.speichern(3)
	await baum.create_timer(6.0).timeout
	print("SPIELSTANDTEST gespeichert=", Spielstand.belegt(3), " info=", Spielstand.beschreibung(3), " laeuft=", d.rogue.laeuft,
			" ende=", d.ende_meldung, " feld=", d.feld, " meldung=", d.meldung)
	d.laden(3)
	await baum.create_timer(6.0).timeout
	print("SPIELSTANDTEST geladen laeuft=", d.rogue.laeuft, " ende=", d.ende_meldung, " feld=", d.feld, " meldung=", d.meldung,
			" status=", d.anzeigen.status_label.text.replace("\n", " | "))
	d.rogue.stoppen()
	baum.quit()
