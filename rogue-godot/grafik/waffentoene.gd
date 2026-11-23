## Waffentöne (CC0-Aufnahmen in modelle/ton/waffe/): Rogue meldet im Fühler
## "klang <nr> <art> <waffe> <ergebnis>" (siehe fight.c, weapons.c und sticks.c).
extends Node

const WAFFE_NAME := {0: "kolben", 1: "schwert", 3: "pfeil", 4: "dolch", 5: "zweihaender", 6: "wurfpfeil", 7: "shuriken", 8: "speer"}
const PRUEF_TAKT := 0.1   # Sekunden zwischen zwei Blicken in die Fühler-Datei

var fuehler   # fuehler.gd, von grafik.gd gesetzt
var _klang_nr := -1
var _uhr := 0.0
var _toene := {}            # Name -> AudioStreamMP3 oder null
var _sprecher: Array = []   # wiederverwendete AudioStreamPlayer


func _process(delta: float) -> void:
	_uhr -= delta
	if _uhr > 0.0 or fuehler.fest:
		return
	_uhr = PRUEF_TAKT
	var k: Array = fuehler.klang_lesen()
	if k.is_empty():
		return
	var t: PackedStringArray = String(k[0]).split(" ")
	var nr := int(t[1]) if t.size() >= 4 else 0
	if nr == _klang_nr:
		return
	var erstes := _klang_nr < 0   # beim ersten Lesen nur merken, nichts abspielen
	_klang_nr = nr
	if not erstes and t.size() >= 4:
		_waffe_klingt(t[2], int(t[3]), t[4].strip_edges() if t.size() > 4 else "", k[1])


func _waffe_klingt(art: String, waffe: int, ergebnis: String, bogen: bool) -> void:
	if art == "stab":
		_spielen("stab")
		return
	var name: String = WAFFE_NAME.get(waffe, "faust")
	var flug: String = "bogen" if name == "pfeil" and bogen else ("wurfpfeil" if name == "pfeil" else name)
	_spielen(flug)
	var spaeter := 0.22 if art == "wurf" else 0.12
	if ergebnis == "treffer":
		get_tree().create_timer(spaeter).timeout.connect(_spielen.bind(name + "_treffer"))
	elif ergebnis == "wand":
		get_tree().create_timer(spaeter).timeout.connect(_spielen.bind("wand"))


func _spielen(name: String) -> void:
	if not _toene.has(name):
		var pfad := ProjectSettings.globalize_path("res://modelle/ton/waffe/%s.mp3" % name)
		var st: AudioStreamMP3 = null
		if FileAccess.file_exists(pfad):
			st = AudioStreamMP3.new()
			st.data = FileAccess.get_file_as_bytes(pfad)
		_toene[name] = st
	if _toene[name] == null:
		return
	var sp: AudioStreamPlayer = null
	for k in _sprecher:
		if not k.playing:
			sp = k
			break
	if sp == null:
		sp = AudioStreamPlayer.new()
		add_child(sp)
		_sprecher.append(sp)
	sp.stream = _toene[name]
	sp.play()
