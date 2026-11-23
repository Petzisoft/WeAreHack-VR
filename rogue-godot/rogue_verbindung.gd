## Startet Rogue (über rogue-bruecke.exe) und hält das aktuelle Zeichenraster.
## Diese Klasse kennt keine Darstellung - Schritt 3 (3D) kann sie unverändert nutzen.

extends RefCounted

const Protokoll = preload("res://protokoll.gd")

## Wird gesendet, wenn ein neues Bild von Rogue da ist.
signal bild_geaendert
## Wird gesendet, wenn Rogue beendet ist (oder nicht starten konnte).
signal beendet(meldung: String)

var spalten := 80
var zeilen := 25
## Das Raster als Liste von Textzeilen (je `spalten` Zeichen).
var raster: PackedStringArray = []
## Cursorposition (bei Rogue steht der Cursor meist auf dem @).
var cursor := Vector2i.ZERO
var laeuft := false
## Die zuletzt an Rogue geschickte Taste (z. B. um eine stehengebliebene alte Frage zu erkennen).
var letzte_taste := 0

var _pipe: FileAccess
var _pid := -1
var _thread: Thread
var _lauf := 0   # zählt die Starts, damit Nachrichten einer alten Brücke nicht ins neue Spiel geraten


## programm: Spiel, das die Brücke starten soll (leer = build\rogue.exe, z. B. nethack-spiel\NetHack.exe).
## argumente: weitere Argumente für das Spiel (Rogue: Spielstand-Datei zum Laden).
func starten(bruecke_pfad: String, programm := "", argumente: Array = []) -> bool:
	stoppen()   # neues Spiel: die alte Brücke und ihren Lesefaden sauber beenden
	if not FileAccess.file_exists(bruecke_pfad):
		beendet.emit(tr("Brückenprogramm nicht gefunden:\n") + bruecke_pfad)
		return false
	var info := OS.execute_with_pipe(bruecke_pfad, ([programm] + argumente) if programm != "" else [])
	if info.is_empty():
		beendet.emit(tr("Brückenprogramm konnte nicht gestartet werden."))
		return false
	_pipe = info["stdio"]
	_pid = info["pid"]
	laeuft = true
	_lauf += 1
	_thread = Thread.new()
	_thread.start(_lesen.bind(_pipe, _lauf))
	return true


## Schickt eine Taste (ASCII-Code) an Rogue.
func taste(code: int) -> void:
	if laeuft and _pipe and code > 0 and code < 128:
		letzte_taste = code
		Protokoll.taste(code)
		_pipe.store_buffer(PackedByteArray([code]))


func stoppen() -> void:
	laeuft = false
	if _pid > 0 and OS.is_process_running(_pid):
		OS.kill(_pid)
	_pid = -1
	if _thread and _thread.is_started():
		_thread.wait_to_finish()
	_thread = null
	_pipe = null


# Läuft im Hintergrund-Thread: liest Bild für Bild von der Brücke.
func _lesen(pipe: FileAccess, lauf: int) -> void:
	var meldung := TranslationServer.translate("%s wurde beendet.") % preload("res://spiel.gd").wert("name").get_slice(" (", 0)   # Rogue oder NetHack
	while true:
		var kopf := pipe.get_line()
		if kopf == "" and pipe.get_error() != OK:
			break
		if kopf.begins_with("FRAME"):
			var t := kopf.split(" ", false)
			if t.size() < 5 or not (t[1].is_valid_int() and t[2].is_valid_int() and t[3].is_valid_int() and t[4].is_valid_int()) \
					or int(t[2]) <= 0 or int(t[2]) > 200:
				continue   # kaputte Kopfzeile: überspringen, das nächste Bild kommt gleich
			var sp := int(t[1])
			var ze := int(t[2])
			var neu := PackedStringArray()
			for i in ze:
				neu.append(pipe.get_line())
			_neues_bild.call_deferred(lauf, neu, sp, ze, Vector2i(int(t[3]), int(t[4])))
		elif kopf == "EXIT":
			break
		elif kopf.begins_with("ERROR"):
			meldung = TranslationServer.translate("Fehler: ") + kopf.substr(6)
			break
	_ende.call_deferred(lauf, meldung)


func _neues_bild(lauf: int, neu: PackedStringArray, sp: int, ze: int, cur: Vector2i) -> void:
	if lauf != _lauf:
		return
	raster = neu
	spalten = sp
	zeilen = ze
	cursor = cur
	bild_geaendert.emit()


func _ende(lauf: int, meldung: String) -> void:
	if laeuft and lauf == _lauf:
		laeuft = false
		beendet.emit(meldung)
