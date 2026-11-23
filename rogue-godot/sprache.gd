## Sprache von "We Are Hack" (Peter 23.11.: englische Version, Englisch als Standard; Deutsch umschaltbar im Startmenü).
## Im Code stehen die deutschen Texte; sie sind zugleich die Schlüssel. Hier steht die englische Fassung dazu.
## Godot übersetzt Label-, Button- und Label3D-Texte selbst, wenn sie genau einem Schlüssel entsprechen;
## zusammengesetzte Texte holen sich die Übersetzung mit Sprache.t("...") bzw. tr("...").
## Die Originaltexte von Rogue und NetHack sind Englisch und werden nicht angefasst.
## Gewählte Sprache: user://einstellungen.cfg, [allgemein] sprache = "en" oder "de".
extends RefCounted

const EINSTELLUNGEN := "user://einstellungen.cfg"
const STANDARD := "en"

const HILFE_DE := """Tastatur und Maus

Alle Buchstaben sind Rogue-Befehle wie im Original:
  i Inventar  e essen  q trinken  r lesen  w Waffe
  W Rüstung  s suchen  d ablegen  >  Treppe  ?  Hilfe
  Leertaste aufheben (sonst: weiter)

Maus                    umsehen
                        (Esc oder F4 = Mauszeiger frei;
                        Remotedesktop: Maustaste halten
                        und ziehen)
Pfeil hoch / runter     Schritt vor / zurück
Pfeil links / rechts    um 90° drehen
Ziffernblock 8 2 4 6    vor / zurück / seitwärts
Ziffernblock 7 9 1 3    schräg
Taste halten            weiterlaufen, bis etwas passiert
Umschalt + Richtung     Rogue rennen lassen
Tab                     Befehlsmenü

F5  WASD zum Laufen ein/aus (dann w a s d
    als Rogue-Befehl mit Strg + Buchstabe)
F1 Hilfe   F2 Karte   F3 Original-Textbild"""

const HILFE_EN := """Keyboard and mouse

All letters are game commands as in the original:
  i inventory  e eat  q quaff  r read  w wield
  W wear  s search  d drop  >  stairs  ?  help
  Space  pick up (otherwise: continue)

Mouse                   look around
                        (Esc or F4 = free the pointer;
                        remote desktop: hold a mouse
                        button and drag)
Arrow up / down         step forward / back
Arrow left / right      turn 90°
Numpad 8 2 4 6          forward / back / sideways
Numpad 7 9 1 3          diagonal
Hold a key              keep walking until something happens
Shift + direction       run
Tab                     command menu

F5  WASD walking on/off (then w a s d
    as game commands with Ctrl + letter)
F1 help   F2 map   F3 original text screen"""

const CONTROLLER_DE := """Controller

Linker Stick            gehen (halten = weiterlaufen)
Rechter Stick           umsehen
LB / RB                 um 90° drehen
Steuerkreuz             vor / zurück / drehen
RT + Richtung           Rogue rennen lassen
LT                      eine Runde ausruhen

A   weiter / Treppe hinab / aufheben
B   abbrechen
X   suchen         Y   Inventar
Start   Befehlsmenü (essen, trinken ...)
Back    diese Hilfe
L3  Karte ein/aus    R3  Blick geradeaus

Fragt Rogue nach einem Gegenstand,
erscheint eine Liste zum Auswählen."""

const CONTROLLER_EN := """Controller

Left stick              walk (hold = keep walking)
Right stick             look around
LB / RB                 turn 90°
D-pad                   forward / back / turn
RT + direction          run
LT                      rest one turn

A   continue / go downstairs / pick up
B   cancel
X   search         Y   inventory
Start   command menu (eat, quaff ...)
Back    this help
L3  map on/off    R3  look straight ahead

When the game asks for an item,
a list appears to choose from."""

const EN := {
	# Startmenü und Vorspann
	"Welches Spiel?": "Which game?",
	"kommt bald": "coming soon",
	"Beenden": "Quit",
	"Hoch/Runter wählen, Enter, Klick oder A startet": "Up/Down to choose, Enter, click or A to start",
	"Das Original von 1980": "The original from 1980",
	"Das Original von 1987": "The original from 1987",
	"von Michael Toy, Ken Arnold und Glenn Wichman": "by Michael Toy, Ken Arnold and Glenn Wichman",
	"von Mike Stephenson und dem NetHack DevTeam": "by Mike Stephenson and the NetHack DevTeam",
	"Taste, Mausklick oder A drücken": "Press any key, click or A",
	# Spielende, Speichern, Laden
	"%s wurde beendet.": "%s has ended.",
	"Brückenprogramm nicht gefunden:\n": "Bridge program not found:\n",
	"Brückenprogramm konnte nicht gestartet werden.": "The bridge program could not be started.",
	"Fehler: ": "Error: ",
	"\n\nEnter / A = neues Spiel     Esc / B = Programm beenden": "\n\nEnter / A = new game     Esc / B = quit",
	"\n\nEnter = neues Spiel     Esc = Programm beenden": "\n\nEnter = new game     Esc = quit",
	"Gespeichert in Platz %d - weiter geht's": "Saved to slot %d - carry on",
	"Speichern ging gerade nicht - bitte nochmal versuchen": "Saving did not work just now - please try again",
	"Platz %d ist leer": "Slot %d is empty",
	"Laden ging nicht: ein anderes NetHack läuft noch": "Loading failed: another NetHack is still running",
	"Laden ging nicht (Platz %d)": "Loading failed (slot %d)",
	"Platz %d geladen": "Slot %d loaded",
	"Platz %d: leer": "Slot %d: empty",
	"Platz %d: %s": "Slot %d: %s",
	"%s, Ebene %s": "%s, level %s",
	# Befehlsmenü
	"Befehle": "Commands",
	"Inventar ansehen": "View inventory",
	"Essen": "Eat",
	"Trank trinken": "Quaff a potion",
	"Schriftrolle lesen": "Read a scroll",
	"Waffe in die Hand nehmen": "Wield a weapon",
	"Rüstung anziehen": "Wear armor",
	"Rüstung ausziehen": "Take off armor",
	"Ring anstecken": "Put on a ring",
	"Ring abnehmen": "Remove a ring",
	"Zauberstab benutzen": "Zap a wand",
	"Etwas werfen": "Throw something",
	"Etwas ablegen": "Drop something",
	"Aufheben": "Pick up",
	"Treppe hinab": "Go downstairs",
	"Treppe hinauf": "Go upstairs",
	"Suchen (Geheimtüren, Fallen)": "Search (secret doors, traps)",
	"Eine Runde ausruhen": "Rest one turn",
	"Kämpfen bis zum Ende": "Fight to the death",
	"Letzten Befehl wiederholen": "Repeat last command",
	"Letzte Meldung nochmal": "Show last message again",
	"Was habe ich entdeckt?": "What have I discovered?",
	"Gegenstand benennen": "Name an item",
	"Falle untersuchen (dann Richtung)": "Identify a trap (then direction)",
	"Gehen ohne aufzuheben (dann Richtung)": "Move without picking up (then direction)",
	"Dauerlaufen beim Halten: ": "Keep walking while held: ",
	"WASD zum Laufen (F5): ": "WASD walking (F5): ",
	"AN": "ON",
	"AUS": "OFF",
	"Karte oben rechts ein/aus": "Map top right on/off",
	"Original-Textbild ein/aus": "Original text screen on/off",
	"Hilfe anzeigen": "Show help",
	"Spiel beenden": "Quit game",
	"Speichern  -> ": "Save  -> ",
	"Laden     <- ": "Load  <- ",
	"Original-Modus (keine Speicherplätze): ": "Original mode (no save slots): ",
	"Strg+P": "Ctrl+P",
	# Gegenstand gewählt: was damit tun?
	"Gegenstand %s": "Item %s",
	"Trinken": "Quaff",
	"Lesen": "Read",
	"In die Hand nehmen (Waffe)": "Wield (weapon)",
	"Anziehen (Rüstung)": "Wear (armor)",
	"Ausziehen": "Take off",
	"Anstecken (Ring, Amulett)": "Put on (ring, amulet)",
	"Abnehmen": "Remove",
	"Werfen": "Throw",
	"Zappen (Zauberstab)": "Zap (wand)",
	"Ablegen": "Drop",
	"Anwenden (Werkzeug)": "Apply (tool)",
	# Auswahllisten und Fragen
	"Inventar  (wählen = was damit tun?)": "Inventory  (choose = what to do with it?)",
	"Auswahl": "Choose",
	"Ja (y)": "Yes (y)",
	"Nein (n)": "No (n)",
	"Wirklich aufhören?": "Really quit?",
	"Nein, weiterspielen": "No, keep playing",
	"Ja, Spiel beenden": "Yes, quit the game",
	"Welchen Gegenstand?": "Which item?",
	"Klick, Enter, Buchstabe oder A = auswählen     Esc oder B = abbrechen": "Click, Enter, letter or A = select     Esc or B = cancel",
	"WASD-Laufen AN  (Rogue-Befehle w a s d: Strg + Buchstabe)": "WASD walking ON  (game commands w a s d: Ctrl + letter)",
	"WASD-Laufen AUS  (alle Buchstaben gehen wie im Original an Rogue)": "WASD walking OFF  (all letters go to the game as in the original)",
	# Hinweiszeile
	"Remotedesktop erkannt: zum Umsehen Maustaste gedrückt halten und ziehen": "Remote desktop detected: hold a mouse button and drag to look around",
	"Hoch/Runter: auswählen     A: nehmen     B: abbrechen": "Up/Down: choose     A: take     B: cancel",
	"Linker Stick: Richtung wählen     B: abbrechen": "Left stick: choose direction     B: cancel",
	"A: weiter     B: schließen": "A: continue     B: close",
	"A: ohne Namen weiter     B: überspringen": "A: continue without a name     B: skip",
	"A: %s     X: suchen     Y: Inventar     Start: Befehle     Back: Hilfe": "A: %s     X: search     Y: inventory     Start: commands     Back: help",
	"aufheben": "pick up",
	"Wurf wiederholen": "Repeat throw",
	# Namensschilder (Gegenstände, Gelände, Rogue-Monster ohne Modell)
	"Trank": "Potion", "Schriftrolle": "Scroll", "Waffe": "Weapon", "Rüstung": "Armor", "Ring": "Ring",
	"Zauberstab": "Wand", "Gold": "Gold", "Nahrung": "Food", "Amulett": "Amulet", "Treppe ▼": "Stairs ▼",
	"Treppe ▲": "Stairs ▲", "Falle": "Trap", "Brunnen": "Fountain", "Altar": "Altar", "Thron": "Throne",
	"Grab": "Grave", "Spüle": "Sink", "Baum": "Tree", "Gitter": "Iron bars", "Tür (zu)": "Door (closed)",
	"Aquator": "Aquator", "Fledermaus": "Bat", "Zentaur": "Centaur", "Drache": "Dragon", "Emu": "Emu",
	"Fliegenfalle": "Venus flytrap", "Greif": "Griffin", "Hobgoblin": "Hobgoblin", "Eismonster": "Ice monster",
	"Jabberwock": "Jabberwock", "Falke": "Kestrel", "Kobold": "Kobold", "Medusa": "Medusa", "Nymphe": "Nymph",
	"Ork": "Orc", "Phantom": "Phantom", "Quagga": "Quagga", "Klapperschlange": "Rattlesnake", "Schlange": "Snake",
	"Troll": "Troll", "Einhorn": "Black unicorn", "Vampir": "Vampire", "Geist": "Wraith", "Xeroc": "Xeroc",
	"Yeti": "Yeti", "Zombie": "Zombie",
	HILFE_DE: HILFE_EN,
	CONTROLLER_DE: CONTROLLER_EN,
}

# "Was möchtest du essen?": englisch mit dem Originalverb des Spiels
const VERB_DE := {
	"eat": "essen", "quaff": "trinken", "read": "lesen", "wield": "in die Hand nehmen",
	"wear": "anziehen", "put on": "anstecken", "remove": "abnehmen", "throw": "werfen",
	"zap with": "benutzen", "drop": "ablegen", "call": "benennen", "identify": "bestimmen",
}

static var _bereit := false


## Übersetzungen anmelden und die gespeicherte Sprache einstellen (mehrfacher Aufruf schadet nicht).
static func einrichten() -> void:
	if _bereit:
		return
	_bereit = true
	var en := Translation.new()
	en.locale = "en"
	var de := Translation.new()   # Deutsch = die Schlüssel selbst (sonst nähme Godot die englische Rückfallsprache)
	de.locale = "de"
	for k in EN:
		en.add_message(k, EN[k])
		de.add_message(k, k)
	TranslationServer.add_translation(en)
	TranslationServer.add_translation(de)
	TranslationServer.set_locale(gespeichert())


static func gespeichert() -> String:
	var cfg := ConfigFile.new()
	cfg.load(EINSTELLUNGEN)
	var s := str(cfg.get_value("allgemein", "sprache", STANDARD))
	return s if s in ["en", "de"] else STANDARD


static func setzen(s: String) -> void:
	einrichten()
	TranslationServer.set_locale(s)
	var cfg := ConfigFile.new()
	cfg.load(EINSTELLUNGEN)
	cfg.set_value("allgemein", "sprache", s)
	cfg.save(EINSTELLUNGEN)


static func englisch() -> bool:
	return TranslationServer.get_locale().begins_with("en")


## Übersetzung eines deutschen Textes (Schlüssel); unbekannte Texte bleiben, wie sie sind.
static func t(s: String) -> String:
	return String(TranslationServer.translate(s))


## "Was möchtest du essen?" / "What do you want to eat?" (verb = englisches Verb aus der Frage des Spiels)
static func frage_verb(verb: String) -> String:
	if englisch():
		return "What do you want to " + verb + "?"
	return "Was möchtest du " + VERB_DE.get(verb, verb) + "?"
