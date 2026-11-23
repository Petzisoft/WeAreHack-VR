## Spielprotokoll (Peter 21.11.2026): jede Taste, die an Rogue geht, jede neue Rogue-Meldung und jede
## geänderte Statuszeile, mit Uhrzeit. Datei spielprotokoll.txt im Spielordner, die vom letzten Programmstart
## heißt spielprotokoll_vorher.txt. Am Spiel ändert das nichts; es dient nur zum Nachlesen, was passiert ist.
extends RefCounted

static var _datei: FileAccess
static var _letzte_meldung := ""
static var _letzter_status := ""


static func _offen() -> FileAccess:
	if _datei == null:
		var ordner := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
		var zusatz := "" if preload("res://spiel.gd").welches() == "rogue" else "_" + preload("res://spiel.gd").welches()
		var pfad := ordner.path_join("spielprotokoll%s.txt" % zusatz)
		if FileAccess.file_exists(pfad):
			var vorher := ordner.path_join("spielprotokoll%s_vorher.txt" % zusatz)
			if FileAccess.file_exists(vorher):
				DirAccess.remove_absolute(vorher)
			if DirAccess.rename_absolute(pfad, vorher) != OK:
				# Datei gehört noch einem laufenden Spiel (zweites Fenster): nicht überschreiben, eigene Datei nehmen
				pfad = ordner.path_join("spielprotokoll%s_%d.txt" % [zusatz, OS.get_process_id()])
		_datei = FileAccess.open(pfad, FileAccess.WRITE)
	return _datei


static func _zeile(art: String, text: String) -> void:
	var f := _offen()
	if f == null:
		return
	var t := Time.get_time_dict_from_system()
	f.store_line("%02d:%02d:%02d.%03d  %-8s %s" % [t.hour, t.minute, t.second, Time.get_ticks_msec() % 1000, art, text])
	f.flush()


static func taste(code: int) -> void:
	var name := char(code)
	match code:
		13: name = "Enter"
		27: name = "Esc"
		32: name = "Leertaste"
		8: name = "Ruecktaste"
		_:
			if code < 32:
				name = "Strg+" + char(code + 64)
	_zeile("TASTE", name)


static func bild(meldung: String, status: String) -> void:
	if meldung != _letzte_meldung:
		_letzte_meldung = meldung
		if meldung != "":
			_zeile("MELDUNG", meldung)
	if status != _letzter_status:
		_letzter_status = status
		_zeile("STATUS", status)


static func notiz(text: String) -> void:
	_zeile("SPIEL", text)
