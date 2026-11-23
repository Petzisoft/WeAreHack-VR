## Spielstände (Peter 22.11.2026): 3 Speicherplätze je Spiel (Rogue, NetHack, später Hack).
## Die Originalspiele bleiben unverändert: gespeichert wird mit ihrem eigenen Befehl S, danach wird die
## Spielstand-Datei in einen Platz kopiert und das Spiel lädt sie sofort wieder (man spielt einfach weiter).
## Laden: laufendes Spiel beenden, Datei aus dem Platz zurücklegen, Spiel neu starten (es lädt sie selbst).
## "Original-Modus" (Befehlsmenü): keine Speicherplätze, wie im Original.
## Plätze: user://spielstaende/<spiel>/platz<n>/ (Datei + info.txt mit Datum und Ebene).
extends RefCounted

const Spiel = preload("res://spiel.gd")
const Sprache = preload("res://sprache.gd")
const PLAETZE := 3
const EINSTELLUNGEN := "user://einstellungen.cfg"
const ROGUE_DATEI := "wah_spielstand.save"   # so tippt dungeon_3d.gd den Namen bei Rogues Frage ein


static func original_modus() -> bool:
	var cfg := ConfigFile.new()
	cfg.load(EINSTELLUNGEN)
	return bool(cfg.get_value(Spiel.welches(), "original_modus", false))


static func original_umschalten() -> void:
	var cfg := ConfigFile.new()
	cfg.load(EINSTELLUNGEN)
	cfg.set_value(Spiel.welches(), "original_modus", not original_modus())
	cfg.save(EINSTELLUNGEN)


## Wo das Originalspiel seinen Spielstand ablegt.
static func spieldatei() -> String:
	if Spiel.ist_nethack():
		return OS.get_environment("LOCALAPPDATA").path_join("NetHack/3.6/%s.NetHack-saved-game" % OS.get_environment("USERNAME"))
	# Rogue: eigener Dateiname statt Dokumente/rogue.save (dort liegt evtl. ein alter Spielstand von Peter, nicht anfassen)
	# Rogue liest höchstens 50 Zeichen ein: kurzer Name, liegt im Ordner von rogue.exe (dort startet die Brücke Rogue)
	return ProjectSettings.globalize_path("res://").path_join("../build/" + ROGUE_DATEI).simplify_path()


static func ordner(platz: int) -> String:
	return ProjectSettings.globalize_path("user://spielstaende/%s/platz%d" % [Spiel.welches(), platz])


static func belegt(platz: int) -> bool:
	return FileAccess.file_exists(ordner(platz).path_join("spielstand"))


## Text für das Menü: "Platz 1: 22.11. 06:50, Ebene 3" oder "Platz 1: leer".
static func beschreibung(platz: int) -> String:
	if not belegt(platz):
		return Sprache.t("Platz %d: leer") % platz
	var info := FileAccess.get_file_as_string(ordner(platz).path_join("info.txt")).strip_edges()
	if "|" in info:   # "22.11. 06:50|3" (Zeit|Ebene), Text erst hier in der gewählten Sprache
		info = Sprache.t("%s, Ebene %s") % [info.get_slice("|", 0), info.get_slice("|", 1)]
	return Sprache.t("Platz %d: %s") % [platz, info]


## Nach dem Speichern des Originalspiels: Datei in den Platz kopieren. true = geklappt.
static func in_platz_legen(platz: int, ebene: String) -> bool:
	var quelle := spieldatei()
	if not FileAccess.file_exists(quelle):
		return false
	DirAccess.make_dir_recursive_absolute(ordner(platz))
	if DirAccess.copy_absolute(quelle, ordner(platz).path_join("spielstand")) != OK:
		return false
	var z := Time.get_datetime_dict_from_system()
	var info := "%02d.%02d. %02d:%02d|%s" % [z.day, z.month, z.hour, z.minute, ebene if ebene != "" else "?"]
	var f := FileAccess.open(ordner(platz).path_join("info.txt"), FileAccess.WRITE)
	if f:
		f.store_line(info)
	return true


## Platz zurücklegen, damit das Originalspiel ihn beim nächsten Start lädt. true = geklappt.
static func aus_platz_holen(platz: int) -> bool:
	if not belegt(platz):
		return false
	var ziel := spieldatei()
	DirAccess.make_dir_recursive_absolute(ziel.get_base_dir())
	if FileAccess.file_exists(ziel):
		DirAccess.remove_absolute(ziel)
	return DirAccess.copy_absolute(ordner(platz).path_join("spielstand"), ziel) == OK


## NetHack: Sperrdateien eines hart beendeten Spiels (<name>.0, .1 ...) weg, sonst fragt es "Recover?".
## Nur aufrufen, wenn das eigene NetHack schon beendet ist.
static func nethack_sperren_weg() -> bool:
	var dir := OS.get_environment("LOCALAPPDATA").path_join("NetHack/3.6")
	var name := OS.get_environment("USERNAME")
	var ok := true
	for f in DirAccess.get_files_at(dir):
		var teile := f.split(".")
		if teile.size() == 2 and teile[0] == name and teile[1].is_valid_int():
			if DirAccess.remove_absolute(dir.path_join(f)) != OK:
				ok = false   # noch belegt: ein anderes NetHack läuft
	return ok


## Programm-Argumente zum Laden: Rogue bekommt die Datei mit, NetHack findet sie selbst.
static func lade_argumente() -> Array:
	if Spiel.ist_nethack():
		return []
	return [spieldatei()] if FileAccess.file_exists(spieldatei()) else []
