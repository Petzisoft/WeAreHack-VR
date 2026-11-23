## Entwickler-Werkzeug: prüft die Verbindung zu Rogue (Neustart, kaputte Zeilen).
## Aufruf: Godot --headless --path rogue-godot --script res://werkzeuge/verbindung_test.gd [-- <falsche_bruecke.exe>]
## Mit einer Test-Brücke, die kaputte FRAME-Zeilen schickt, muss trotzdem das gute Bild ankommen.
extends SceneTree

const RogueVerbindung = preload("res://rogue_verbindung.gd")
var bilder := 0
var enden: Array = []


func _initialize() -> void:
	_laufen.call_deferred()


func _laufen() -> void:
	var r := RogueVerbindung.new()
	r.bild_geaendert.connect(func(): bilder += 1)
	r.beendet.connect(func(m): enden.append(m))
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		r.starten(args[0])
		await create_timer(2.0).timeout
		print("TEST kaputte Zeilen: bilder=", bilder, " raster=", r.raster, " enden=", enden)
		r.stoppen()
	else:
		var pfad := ProjectSettings.globalize_path("res://").path_join("../bruecke/rogue-bruecke.exe").simplify_path()
		r.starten(pfad)
		await create_timer(2.0).timeout
		var vorher := bilder
		r.starten(pfad)   # Neustart: alte Brücke beenden, neue starten
		await create_timer(2.0).timeout
		print("TEST Neustart: bilder vorher=", vorher, " nachher=", bilder - vorher, " laeuft=", r.laeuft, " enden=", enden)
		r.stoppen()
	quit()
