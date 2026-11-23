## Monster im Dungeon. Normalfall: unanimiertes 3D-Modell (modelle/monster3d/<Buchstabe>.glb,
## Füße auf y = 0, Blick nach -Z), das sich zum Spieler dreht, atmet, beim Angriff vorstößt
## und beim Tod umkippt. Fehlt das Modell, steht das Standbild (modelle/monster/<Buchstabe>.png)
## als Aufsteller da. Zustand und Lebenspunkte kommen aus dem Fühler, sonst aus Rogues Meldungen.
extends Node3D

const Masse = preload("res://raster_masse.gd")
const ModellHilfe = preload("res://grafik/modell_hilfe.gd")
const ZELLE := Masse.ZELLE

# Größe im Spiel in Metern (Höhe; bei Fliegern die Breite).
const MONSTER_GROESSE := {
	"A": 1.9, "B": 1.4, "C": 2.3, "D": 3.0, "E": 1.8, "F": 1.7, "G": 2.2, "H": 1.8, "I": 2.1,
	"J": 2.8, "K": 1.2, "L": 1.0, "M": 1.85, "N": 1.75, "O": 1.95, "P": 2.0, "Q": 1.8, "R": 1.1,
	"S": 1.3, "T": 2.6, "U": 2.0, "V": 1.95, "W": 2.1, "X": 1.0, "Y": 2.4, "Z": 1.85,
}
const FLIEGER := "BGK"            # schweben auf Augenhöhe im oberen Drittel des Gangs
# Sphären schweben wie die Flieger mit der Mitte auf FLUGHOEHE (Peter 22.11.: "alle Sphären Mitte auf 180")
const KUGELN := ["nh:e_Gassporen", "hk:E_SchwebendesAuge", "hk:F_Frostkugel", "nh:e_Flammenkugel", "nh:e_Blitzkugel", "nh:e_Betrachter",
	"hk:k_Killerbiene", "hk:x_Xan", "hk:y_GelbesLicht",
	"nh:a_Bienenkoenigin", "nh:B_Rabe", "nh:B_Vampirfledermaus"]   # Peter 22.11.: müssen fliegen   # fliegen auf Augenhöhe (Peter 22.11.)
# Von Peter festgelegte Größen (gehen vor monster_namen.txt), in Metern
const GROESSE_PETER := {   # Peter 22.11.
	"nh:Tilde_Hai": 1.2,   # neues waagerechtes Modell: 1,2 m hoch = ca. 3 m lang
	# Pferde/Einhörner (Peter 22.11.: "etwas zu groß"), Untote wie die Lebenden, junge Würmer:
	"nh:u_Pony": 1.3, "nh:u_Pferd": 1.9, "nh:u_Kriegspferd": 2.1, "nh:u_WeissesEinhorn": 1.9, "nh:u_GrauesEinhorn": 1.9,
	"nh:Z_Ghul": 1.7, "nh:Z_Gnomenzombie": 1.5, "nh:M_Gnomenmumie": 1.5, "nh:Z_Zwergenzombie": 1.4, "nh:M_Zwergenmumie": 1.4,
	"nh:w_JungerLangwurm": 1.2, "nh:w_JungerPurpurwurm": 1.3,   # Peter Nr. 311/312: zu groß
	"nh:Tilde_Riesenaal": 0.7, "nh:Tilde_Zitteraal": 0.6,   # Peter: Riesenaal zu groß; Aale liegen flach
	# Schleime, Puddings, Gallerten (Peter 22.11.: "viel viel zu groß"):
	"nh:P_GrauerSchleim": 0.6, "nh:P_BraunerPudding": 0.6, "nh:P_GruenerSchleim": 0.7, "nh:P_SchwarzerPudding": 0.8,
	"nh:j_BlaueGallerte": 0.9, "nh:j_GefleckteGallerte": 0.9, "nh:j_OckerGallerte": 0.9,
	# Schlangen und Nagas (Peter 22.11.: "zu groß"), Höhe nach Pose:
	"nh:S_Strumpfbandnatter": 0.6, "nh:S_Wassermokassin": 0.7, "nh:S_Grubenotter": 0.8, "nh:S_Python": 1, "nh:S_Kobra": 1.1,
	"nh:N_JungeRoteNaga": 0.9, "nh:N_JungeSchwarzeNaga": 0.9, "nh:N_JungeGoldeneNaga": 0.9, "nh:N_JungeWaechterNaga": 0.9,
	"nh:N_RoteNaga": 1.4, "nh:N_SchwarzeNaga": 1.4, "nh:N_GoldeneNaga": 1.4, "nh:N_WaechterNaga": 1.4,
	# Goblins und Orks (Peter 22.11.: "Goblin zu klein"):
	"nh:o_Goblin": 1.3, "nh:o_Goblinkoenig": 1.4, "nh:o_Huegelork": 1.75, "nh:o_MordorOrk": 1.8, "nh:o_UrukHai": 1.85,
	"nh:o_OrkSchamane": 1.6, "nh:o_OrkHauptmann": 1.9,
	# Kleinwüchsige stimmig (Peter 22.11.: "Hobbit zu klein"; Hack-Gnom hat Peter auf 1,5 m gesetzt):
	"nh:h_Hobbit": 1.5, "nh:h_Zwerg": 1.4, "nh:h_Zwergenfuerst": 1.5, "nh:h_Zwergenkoenig": 1.6,
	"nh:G_Gnomenzauberer": 1.5, "nh:G_Gnomenfuerst": 1.55, "nh:G_Gnomenkoenig": 1.6,
	"nh:k_GrosserKobold": 1.4, "nh:k_Koboldfuerst": 1.5, "nh:k_Koboldschamane": 1.2, "nh:M_Koboldmumie": 1.2, "nh:Z_Koboldzombie": 1.2,   # Peter: alle Kobolde zu klein
	# Katzen und Hunde stimmig (Peter 22.11.: "Kätzchen zu groß"), Höhe der ganzen Figur:
	"nh:f_Kaetzchen": 0.45, "nh:f_Hauskatze": 0.65, "nh:f_Grosskatze": 0.8, "nh:f_Luchs": 0.85,   # Peter: 0,2-0,6 war winzig
	"nh:d_Fuchs": 0.6, "nh:d_Kojote": 0.75, "nh:d_Wolf": 0.85, "nh:d_Warg": 1.2, "nh:d_Werwolf": 1.0,
	"nh:d_WinterwolfJunges": 0.5, "nh:d_Winterwolf": 1.1, "nh:d_HoellenhundJunges": 0.5, "nh:d_Hoellenhund": 1.0, "nh:d_Zerberus": 1.4,
	"nh:Doppelpunkt_Molch": 0.4, "nh:Doppelpunkt_Salamander": 1.1,   # Peter: zu groß (vorher 0,8 / 1,8 m)
	"nh:d_Dingo": 0.8,   # Peter: zu groß (vorher 1,8 m), mittelgroßer Hund
	"nh:At_Charon": 2.2, "nh:K_Polizist": 2.2, "nh:At_Wache": 2.2, "nh:At_Soldat": 2.1, "nh:At_Waechter": 2.0,   # Stab/Knüppel/Speer ragt über den Kopf: Körper ca. 1,8 m (Peter)
	"nh:At_Ritter": 2.4,   # Peter: wegen des Speers zu klein; Kopf liegt bei 75 % der Höhe -> Körper 1,8 m
	"nh:Doppelpunkt_Krokodil": 0.6, "nh:Doppelpunkt_JungesKrokodil": 0.35,   # Peter: zu groß (vorher 2,6 / 1,8 m hoch)
	"nh:f_Tiger": 1.3, "nh:f_Panther": 1.0,   # Peter: 2,6 zu groß, 1,0/0,75 zu klein; Gesamthöhe (Schulter ca. 1,0 / 0,75 m)
	"nh:d_Werschakal": 1.4,   # Peter: zu klein (vorher 1,0)
	"hk:R_Rostmonster": 1.1,   # neues flaches Modell (22.11.): etwa ponygroß; mit 1,8 m wäre es über 3 m lang
	"hk:E_SchwebendesAuge": 1.5,   # "schwebendes Auge größer" (vorher 1,0)
	"hk:i_Imp": 1.2, "hk:h_Homunkulus": 1.2,   # vorher 0,5
	"hk:G_Gnom": 1.5,   # vorher 1,0
	"hk:Komma_Fallensteller": 1.2,   # neues Modell neuC_2 (22.11.): Bodenplatte ca. 1,7 m breit
	"hk:Q_Quasit": 1.5,
	"hk:s_Skorpion": 1.2,   # neues Modell 22.11., Peter: 1,20
	"hk:j_Jaguar": 0.9,   # Höhe; vorher 2,6 (wirkte vertikal verzerrt)
	"hk:b_Riesenkaefer": 1.0,   # neues flaches Modell 22.11. (ponygroß); mit 2,6 m Höhe wäre er 6 m lang
	"hk:Tilde_LauererVonOben": 1.2,   # neues Modell 22.11. ist ein flacher Felsbrocken, 3,0 m ragte weit in den Gang
	"hk:t_Tengu": 1.9, "hk:v_VioletterPilz": 2.0,   # vorher je 1,0
}
# Etwas in den Boden absenken (Anteil der Höhe), wenn die Figur auf Stachelbeinchen o. Ä. steht und der Körper
# dadurch schwebend wirkt (Peter 22.11.: "Purpurwurm muss auf den Boden, schwebt"; Bauch ~3 % über den Spitzen)
const EINSINKEN := {"hk:P_Purpurwurm": 0.03,
	"hk:b_Riesenkaefer": 0.08}   # Käfer: Körper hoch auf dünnen Beinen wirkte schwebend (Peter 22.11.: "landen lassen")
## Mitte nach der ganzen Hülle statt nach den Füßen: hier liegt der Schwanz am Boden und zöge die Fußmitte weg
## Klumpen, Würfel und Wolken haben keine Füße: die Fußmitte schob sie bis 1 m neben das Feld (Peter 22.11.: "Schleimding steht
## mitten im Raum").
const MITTE_HUELLE := ["hk:c_Cockatrice", "hk:a_Saeureklumpen", "hk:g_Gallertwuerfel", "hk:q_Zitterklumpen", "hk:f_Nebelwolke",
	"hk:P_Purpurwurm", "hk:w_Langwurm", "hk:Tilde_LauererVonOben", "hk:Komma_Fallensteller", "hk:v_VioletterPilz"]
## Figuren mit Schleppe/Umhang (Peter 22.11.): Körper senkrecht nach den Füßen (KIPPEN), die Schleppe wird auf den
## Boden gedrückt statt die Figur zu kippen; Boden = Füße vorn.
const SCHLEPPE := ["nh:At_Earendil", "nh:At_Elfenfuerst", "nh:At_Elfenkoenig", "nh:At_Elwing", "nh:At_Hochelf", "nh:At_ThothAmon",
	"nh:n_Wassernymphe", "nh:At_Zauberer", "nh:V_Vampirmagier", "nh:G_Gnomenzauberer", "nh:o_OrkSchamane", "nh:At_Norn", "nh:At_ZaubererVonYendor", "nh:h_Gedankenschinder"]
## Schief erzeugte Modelle gerade stellen: Drehung in Grad (x, y, z) um die Achsen der Datei (Peter 22.11.)
const KIPPEN := {
	# Hack (22.11., grafik-test/schwerpunkt.py): Vor/Zurück aus dem Volumen-Schwerpunkt über der Standfläche,
	# Seitenneigung aus dem Umriss-Abgleich mit dem abgenommenen Bild; Tabelle grafik-test/schwerpunkt_hack.txt
	"hk:A_Riesenameise": Vector3(8, 0, -0.3),
	"hk:At_Ladenbesitzer": Vector3(0.75, 0, -0.25),
	"hk:b_Riesenkaefer": Vector3(1.75, 45, 0.5),
	"hk:c_Cockatrice": Vector3(9, 0, 1.5),
	"hk:d1_KleinerHund": Vector3(1, 45, -1.5),
	"hk:d2_Hund": Vector3(3.75, 45, -0.25),
	"hk:d3_GrosserHund": Vector3(6.75, 45, 0.25),
	"hk:Doppelpunkt_Chamaeleon": Vector3(7.5, 0, 0.25),
	"hk:e_Ettin": Vector3(8.5, 0, 0.75),
	"hk:f_Nebelwolke": Vector3(1.25, 0, 0),
	"hk:g_Gallertwuerfel": Vector3(1, 0, -0.25),
	"hk:G_Gnom": Vector3(1, 0, 0.8),
	"hk:h_Homunkulus": Vector3(-7.5, 0, -1),
	"hk:i_Imp": Vector3(-0.1, 0, -0),
	"hk:I_Pirscher": Vector3(0, 0, 0),
	"hk:j_Jaguar": Vector3(1.5, 45, -5),
	"hk:J_Schakal": Vector3(8.25, 0, -0.5),
	"hk:l_Leocrotta": Vector3(11.5, 0, 1.25),
	"hk:M_Mimic": Vector3(3.75, 0, -0.25),
	"hk:m_Minotaurus": Vector3(4.25, 0, 0.5),
	"hk:n_Krankenschwester": Vector3(-8.5, 0, 0),
	"hk:o_Eulenbaer": Vector3(15, 0, -0.75),
	"hk:p_Durchbohrer": Vector3(0.25, 0, 0.5),
	"hk:P_Purpurwurm": Vector3(11.25, 0, 0),
	"hk:Q_Quasit": Vector3(-18.25, 0, -0.25),
	"hk:q_Zitterklumpen": Vector3(-9.5, 0, 1.25),
	"hk:r_Riesenratte": Vector3(4, 0, 0),
	"hk:R_Rostmonster": Vector3(6.5, 45, -0.25),   # neues Modell neu_2 (22.11.), Schrägbild 45°, Schwerpunkt
	"hk:s_Skorpion": Vector3(-9, 45, 0),
	"hk:t_Tengu": Vector3(-10.6, 0, -0.2),
	"hk:Tilde_LauererVonOben": Vector3(-3, 0, -1),
	"hk:U_UmberHulk": Vector3(10.75, 0, -0.25),
	"hk:Und_Daemon": Vector3(-0.7, 0, -0.5),
	"hk:v_VioletterPilz": Vector3(10.25, 0, 1),
	"hk:w_Langwurm": Vector3(14.25, 0, -1.75),
	"hk:X_Xorn": Vector3(5, 0, 0),
	"hk:z_Zruty": Vector3(7.25, 0, -0.25),
	# NetHack (22.11., grafik-test/schwerpunkt.py wie Hack): Vor/Zurück aus dem Volumen-Schwerpunkt, Seite aus dem Bild-Umriss;
	# Stil-V-Figuren (Schrägbild) zusätzlich 45° gedreht. Tabelle grafik-test/schwerpunkt_nethack.txt
	"nh:A_Aleax": Vector3(2.5, 0, 0),
	"nh:A_Archon": Vector3(13, 0, 11.75),
	"nh:a_Bienenkoenigin": Vector3(22, 0, 0),
	"nh:A_Couatl": Vector3(0, 0, 7),
	"nh:A_Engel": Vector3(0.5, 0, 1.75),
	"nh:A_KiRin": Vector3(10.75, 45, 2.25),
	"nh:a_SoldatenAmeise": Vector3(11.5, 0, 0),
	"nh:At_Abt": Vector3(-5, 0, 0),
	"nh:At_Akolyth": Vector3(3.41, -0.06, 1.2),   # Saum flach (Peter: Robe liegt auf), Lehnen 1.0°
	"nh:At_Archaeologe": Vector3(-0.5, 0, -0.75),
	"nh:At_AshikagaTakauji": Vector3(1, 0, -0.75),
	"nh:At_Barbar": Vector3(2.75, 0, 0.5),
	"nh:At_Charon": Vector3(5.26, -0.02, -0.16),   # Saum flach (Peter: Robe liegt auf), Lehnen 6.3°
	"nh:At_DerDunkleEine": Vector3(4.96, 0.09, -0.17),   # Saum flach (Peter: Robe liegt auf), Lehnen 6.6°
	"nh:At_Diener": Vector3(2.96, 0, -0.01),   # Bodenflecken entfernt (splitter_weg.py), Saum flach
	"nh:At_Doppelgaenger": Vector3(0.5, 0, 0),
	"nh:At_Earendil": Vector3(1.41, 0, -0.12),   # Körper senkrecht, Schleppe liegt auf (SCHLEPPE)
	"nh:At_Elf": Vector3(3.04, -0, -0.39),   # Saum flach (Peter: Robe liegt auf), Lehnen 2.7°
	"nh:At_Elfenfuerst": Vector3(-2.76, 0, -0.78),   # Körper senkrecht, Schleppe liegt auf (SCHLEPPE)
	"nh:At_Elfenkoenig": Vector3(0.31, 0, 1.29),   # Körper senkrecht, Schleppe liegt auf (SCHLEPPE)
	"nh:At_Elwing": Vector3(4.67, 0, 0.77),   # Körper senkrecht, Schleppe liegt auf (SCHLEPPE)
	"nh:At_Erzpriester": Vector3(-7.03, -0, -0.12),   # neues Bild (Stil A) Nr. 2, Saum flach, Lehnen -1,6°
	"nh:At_Feldwebel": Vector3(4.5, 0, -0.25),
	"nh:At_Fuehrer": Vector3(-0.75, 0, -0.5),
	"nh:At_Gefangener": Vector3(8.25, 0, -1.5),
	"nh:At_Grauelf": Vector3(4.48, 0.02, 0.02),   # Saum flach (Peter: Robe liegt auf), Lehnen 5.7°
	"nh:At_Grossmeister": Vector3(8, 0.03, 0.4),   # Peter Nr. 20: lehnte minimal vor (vorher 11 / -1,64)
	"nh:At_Gruenelf": Vector3(3.89, 0.1, 0.9),   # Saum flach (Peter: Robe liegt auf), Lehnen 7.7°
	"nh:At_Haeuptling": Vector3(7.25, 0, -0.5),
	"nh:At_Hauptmann": Vector3(-1.5, 0, -1),
	"nh:At_Heiler": Vector3(9.81, -0.05, 0.13),   # Saum flach (Peter: Robe liegt auf), Lehnen 5.1°
	"nh:At_Hippokrates": Vector3(0.53, -0, -0.67),   # Saum flach (Peter: Robe liegt auf), Lehnen 0.9°
	"nh:At_Hochelf": Vector3(-0.23, 0, 3.88),   # Körper senkrecht, Schleppe liegt auf (SCHLEPPE)
	"nh:At_Hoehlenfrau": Vector3(-3, 0, -1.75),
	"nh:At_Hoehlenmensch": Vector3(6.06, 0.24, -0.94),   # neu gebaut (TRELLIS Seed 202), Saum flach, Lehnen 3,5°
	"nh:At_Hohepriester": Vector3(-0.01, -0, 0.12),   # Saum flach (Peter: Robe liegt auf), Lehnen 5.3°
	"nh:At_Jaeger": Vector3(0.81, 0, -0.01),   # Saum flach (Peter: Robe liegt auf), Lehnen 3.2°
	"nh:At_KoenigArtus": Vector3(1.25, 0, 0.5),
	"nh:At_Krieger": Vector3(-0.5, 0, -0.5),
	"nh:At_Kroesus": Vector3(1.74, -0.01, 0.63),   # Saum flach (Peter: Robe liegt auf), Lehnen 5.4°
	"nh:At_Lehrling": Vector3(-0.5, 0, -0.5),
	"nh:At_Leutnant": Vector3(0, 0, -0.25),
	"nh:At_LordCarnarvon": Vector3(-2.75, 0, -0.25),
	"nh:At_LordSato": Vector3(1.75, 0, -1.5),
	"nh:At_Meisterassassine": Vector3(4.25, 0, 0),
	"nh:At_MeisterDerDiebe": Vector3(0.25, 0, 0),
	"nh:At_MeisterKaen": Vector3(-1.75, 0, -2.25),
	"nh:At_Mensch": Vector3(3.25, 0, 0),
	"nh:At_Moench": Vector3(-3.99, 0.88, 5.21),   # Saum flach (Peter: Robe liegt auf), Lehnen 5.4°
	"nh:At_Neandertaler": Vector3(7.5, 0, 0.75),
	"nh:At_NeferetDieGruene": Vector3(7.72, 0.05, 1.32),   # Saum flach (Peter: Robe liegt auf), Lehnen 7.8°
	"nh:At_Ninja": Vector3(0.25, 0, 0.25),
	"nh:At_Norn": Vector3(0.86, 0, -0.01),   # Körper senkrecht, Schleppe liegt auf (SCHLEPPE)
	"nh:At_Orakel": Vector3(13.67, 0.43, 5.4),   # Saum flach (Peter: Robe liegt auf), Lehnen 1.7°
	"nh:At_Orion": Vector3(8, 0, 1.5),
	"nh:At_Page": Vector3(0.75, 0, 0),
	"nh:At_Pelias": Vector3(4, 0, -0.25),
	"nh:At_Priester": Vector3(2.3, -0, -0.06),   # Saum flach (Peter: Robe liegt auf), Lehnen 2.1°
	"nh:At_Priesterin": Vector3(10.17, 0.11, 0.69),   # Saum flach (Peter: Robe liegt auf), Lehnen 5.3°
	"nh:At_Ritter": Vector3(0, 0, 1.75),
	"nh:At_Roshi": Vector3(11.37, 0.12, -0.46),   # Saum flach (Peter: Robe liegt auf), Lehnen 5.4°
	"nh:At_Samurai": Vector3(2.25, 0, 0.75),
	"nh:At_SchamaneKarnov": Vector3(-4.52, 0, -1.67),   # Peter: lehnte zu weit vor; Rumpf senkrecht
	"nh:At_Schlaeger": Vector3(1, 0, 0),
	"nh:At_Schurke": Vector3(0.25, 0, 1.5),
	"nh:At_Soldat": Vector3(0, 0, -1),
	"nh:At_Student": Vector3(0, 0, -3.25),
	"nh:At_ThothAmon": Vector3(10.04, 0, -0.3),   # Körper senkrecht, Schleppe liegt auf (SCHLEPPE)
	"nh:At_Tourist": Vector3(-2.5, 0, 0),
	"nh:At_Twoflower": Vector3(0, 0, -0.25),
	"nh:At_Wache": Vector3(-0.25, 0, 0.5),
	"nh:At_Wachhauptmann": Vector3(1.25, 0, 1),
	"nh:At_Waechter": Vector3(7.5, 0, 8),
	"nh:At_Waldelf": Vector3(1.5, 0, -2),
	"nh:At_Waldlaeufer": Vector3(-0.26, 0, -0.05),   # Saum flach (Peter: Robe liegt auf), Lehnen 3.4°
	"nh:At_Walkuere": Vector3(2.67, 0, -0.8),   # Peter: lehnte stark vor; Rumpf senkrecht (fliegt)
	"nh:At_Werratte": Vector3(1.75, 0, -2.5),
	"nh:At_Werschakal": Vector3(0, 0, -0.5),
	"nh:At_Werwolf": Vector3(6.25, 0, -1),
	"nh:At_Zauberer": Vector3(-1.19, 0, 1.79),   # Körper senkrecht, Schleppe liegt auf (SCHLEPPE)
	"nh:At_ZaubererVonYendor": Vector3(-1.15, 0, 0.1),   # Körper senkrecht, Schleppe liegt auf (SCHLEPPE)
	"nh:B_Rabe": Vector3(-15.25, 0, 0),
	"nh:B_Riesenfledermaus": Vector3(10.75, 0, -2.75),
	"nh:B_Vampirfledermaus": Vector3(-2, 0, -4.5),
	"nh:C_Bergzentaur": Vector3(5.75, 45, -0.25),
	"nh:c_Chickatrice": Vector3(9, 0, 0.25),
	"nh:c_Pyrolisk": Vector3(8, 0, 0.5),
	"nh:C_Waldzentaur": Vector3(8, 45, -0.25),
	"nh:D_BlauerDrache": Vector3(8.25, 0, -0.25),
	"nh:D_ChromatischerDrache": Vector3(11.5, 0, 1.5),
	"nh:d_Dingo": Vector3(7, 45, -0.25),
	"nh:d_Fuchs": Vector3(4.75, 45, 0),
	"nh:D_GelberDrache": Vector3(10.25, 0, 0.5),
	"nh:D_GrauerDrache": Vector3(10.5, 0, 0),
	"nh:D_GruenerDrache": Vector3(9.75, 0, 0.5),
	"nh:d_Hoellenhund": Vector3(5.75, 45, 0.5),
	"nh:d_HoellenhundJunges": Vector3(7.75, 45, 0.5),
	"nh:D_Ixoth": Vector3(3.25, 0, -0.75),
	"nh:D_JungerBlauerDrache": Vector3(10.25, 0, -1.5),
	"nh:D_JungerGelberDrache": Vector3(6.25, 0, 0),
	"nh:D_JungerGrauerDrache": Vector3(6.9, 0, -0.2),
	"nh:D_JungerGruenerDrache": Vector3(4.75, 0, 0.75),
	"nh:D_JungerOrangeDrache": Vector3(4.25, 0, -1.75),
	"nh:D_JungerRoterDrache": Vector3(1.25, 0, 2),
	"nh:D_JungerSchillerdrache": Vector3(7.5, 0, 0),
	"nh:D_JungerSchwarzerDrache": Vector3(7.25, 0, 0.25),
	"nh:D_JungerSilberdrache": Vector3(7.75, 0, 2),
	"nh:D_JungerWeisserDrache": Vector3(0, 0, -0.25),
	"nh:d_Kojote": Vector3(5, 45, -2.25),
	"nh:D_OrangeDrache": Vector3(11.75, 0, 0.75),
	"nh:D_RoterDrache": Vector3(9.25, 0, -1.75),
	"nh:D_Schillerdrache": Vector3(11.25, 0, -1),
	"nh:D_SchwarzerDrache": Vector3(11.75, 0, -0.75),
	"nh:D_Silberdrache": Vector3(10.25, 0, -0.5),
	"nh:d_Warg": Vector3(6.75, 45, -1.25),
	"nh:D_WeisserDrache": Vector3(7.5, 0, 0),
	"nh:d_Werschakal": Vector3(-7.5, 0, -0.75),
	"nh:d_Werwolf": Vector3(3.5, 0, -1.5),
	"nh:d_Winterwolf": Vector3(6.25, 45, -0.25),
	"nh:d_WinterwolfJunges": Vector3(6, 45, 0),
	"nh:d_Wolf": Vector3(7.25, 45, -0.5),
	"nh:d_Zerberus": Vector3(2.25, 45, 1.25),
	"nh:Doppelpunkt_Eidechse": Vector3(-3, 45, 0.25),
	"nh:Doppelpunkt_Gecko": Vector3(0, 45, 0),
	"nh:Doppelpunkt_JungesKrokodil": Vector3(0, 45, 0),
	"nh:Doppelpunkt_Krokodil": Vector3(0, 45, 0),
	"nh:Doppelpunkt_Leguan": Vector3(2, 45, -0.75),
	"nh:Doppelpunkt_Molch": Vector3(-8.5, 45.2, -0.75),
	"nh:Doppelpunkt_Salamander": Vector3(0, 45, 0),
	"nh:E_Erdelementar": Vector3(3.75, 0, -0.75),
	"nh:E_Feuerelementar": Vector3(0.25, 0, 0),
	"nh:E_Luftelementar": Vector3(8.25, 0, -1.25),
	"nh:E_Wasserelementar": Vector3(1.75, 0, 0),
	"nh:F_BraunerSchimmel": Vector3(-2.75, 0, -4.75),
	"nh:F_Flechte": Vector3(20, 0, -6.5),
	"nh:f_Grosskatze": Vector3(2.5, 45, -1.75),
	"nh:F_GruenerSchimmel": Vector3(0.5, 0, -1.5),
	"nh:f_Hauskatze": Vector3(3.5, 45, -1.25),
	"nh:f_Kaetzchen": Vector3(8.5, 45, -1.25),
	"nh:F_Kreischer": Vector3(-5.25, 0, 2.75),
	"nh:f_Luchs": Vector3(6.5, 45, -2.75),
	"nh:f_Panther": Vector3(2.25, 45, -0.75),
	"nh:F_RoterSchimmel": Vector3(20.75, 0, 0),
	"nh:f_Tiger": Vector3(5.5, 45, -2.75),
	"nh:g_Gargoyle": Vector3(10, 0, 0.04),   # Peter: nach hinten geneigt (vorher -19,75); hockende Pose, Kopf bleibt etwas zurück
	"nh:g_GefluegelteGargoyle": Vector3(-4, 0, 0),
	"nh:G_Gnomenfuerst": Vector3(2.75, 0, -1),
	"nh:G_Gnomenkoenig": Vector3(-2.25, 0, 0),
	"nh:G_Gnomenzauberer": Vector3(-0.67, 0, -0.35),   # Körper senkrecht, Schleppe liegt auf (SCHLEPPE)
	"nh:g_Gremlin": Vector3(6.5, 0, -1.75),
	"nh:Golem_Eisengolem": Vector3(0.5, 0, -0.75),
	"nh:Golem_Fleischgolem": Vector3(6.25, 0, 0.5),
	"nh:Golem_Glasgolem": Vector3(5.25, 0, -0.25),
	"nh:Golem_Goldgolem": Vector3(5.25, 0, -0.25),
	"nh:Golem_Holzgolem": Vector3(5.5, 0, -0.5),
	"nh:Golem_Ledergolem": Vector3(1.5, 0, 0),
	"nh:Golem_Lehmgolem": Vector3(2.75, 0, -0.25),
	"nh:Golem_Papiergolem": Vector3(0.75, 0, -1.5),
	"nh:Golem_Seilgolem": Vector3(-2.5, 0, 0.75),
	"nh:Golem_Steingolem": Vector3(0.5, 0, 0),
	"nh:Golem_Strohgolem": Vector3(2.75, 0, 1.25),
	"nh:H_Feuerriese": Vector3(-1.75, 0, -0.75),
	"nh:H_Frostriese": Vector3(3.5, 0, 2.25),
	"nh:h_Gedankenschinder": Vector3(-2.79, 0, -0.08),   # Körper senkrecht, Schleppe liegt auf (SCHLEPPE)
	"nh:h_Grottenschrat": Vector3(5.75, 0, 0.5),
	"nh:h_Hobbit": Vector3(0.25, 0, -0.25),
	"nh:H_Huegelriese": Vector3(4.5, 0, 2.25),
	"nh:H_LordSurtur": Vector3(0, 0, 0.25),
	"nh:h_MeisterGedankenschinder": Vector3(5.19, 0, 0.16),   # Körper senkrecht
	"nh:H_Riese": Vector3(7.25, 0, 0.5),
	"nh:H_Steinriese": Vector3(5.25, 0, 1.5),
	"nh:H_Sturmriese": Vector3(3, 0, -0.25),
	"nh:H_Titan": Vector3(4.75, 0, -0.5),
	"nh:h_Zwerg": Vector3(0, 0, -1.25),
	"nh:h_Zwergenfuerst": Vector3(0.25, 0, 0.5),
	"nh:h_Zwergenkoenig": Vector3(8.75, 0, 0.75),
	"nh:H_Zyklop": Vector3(-0.25, 0, 0.5),
	"nh:i_Lemure": Vector3(7.25, 0, 0.5),
	"nh:i_Manes": Vector3(-15.5, 0, 0.5),
	"nh:j_BlaueGallerte": Vector3(6.75, 0, -0.25),
	"nh:j_OckerGallerte": Vector3(3.5, 0, 0),
	"nh:J_VorpalJabberwock": Vector3(9.5, 0, 0.25),
	"nh:k_GrosserKobold": Vector3(5.25, 0, -1.75),
	"nh:k_Koboldfuerst": Vector3(-0.3, 0, 0),   # Peter Nr. 191: lehnte zu weit vor (vorher 20,5 / -7,5); Rumpf senkrecht
	"nh:k_Koboldschamane": Vector3(4.5, 0, 1.75),
	"nh:K_KopKapitaen": Vector3(4.25, 0, -1.5),
	"nh:K_KopLeutnant": Vector3(4.25, 0, 0.5),
	"nh:K_KopSergeant": Vector3(3.5, 0, -0.25),
	"nh:K_Polizist": Vector3(2.25, 0, 0.5),
	"nh:L_Erzlich": Vector3(4.89, 0.01, -0.07),   # Saum flach (Peter: Robe liegt auf), Lehnen 9.1°
	"nh:L_Lich": Vector3(2.16, -0, 0.13),   # Saum flach (Peter: Robe liegt auf), Lehnen 2.8°
	"nh:L_Meisterlich": Vector3(4.08, -0.06, 0.08),   # Saum flach (Peter: Robe liegt auf), Lehnen 6.5°
	"nh:M_Elfenmumie": Vector3(2.75, 0, -0.25),
	"nh:M_Ettinmumie": Vector3(7.25, 0, -0.25),
	"nh:M_Gnomenmumie": Vector3(0.5, 0, -0.25),
	"nh:M_Koboldmumie": Vector3(8.5, 0, -0.5),
	"nh:M_Menschenmumie": Vector3(2, 0, -2.75),
	"nh:M_Orkmumie": Vector3(0, 0, 0.75),
	"nh:M_Riesenmumie": Vector3(2.5, 0, -1.25),
	"nh:M_Zwergenmumie": Vector3(-7.25, 0, 0),   # Peter Nr. 208: lehnte 10° vor (vorher 2,75)
	"nh:n_Bergnymphe": Vector3(6.33, -0.21, -2.48),   # Saum flach (Peter: Robe liegt auf), Lehnen 7.0°
	"nh:N_GoldeneNaga": Vector3(-1, 0, 1),
	"nh:N_JungeGoldeneNaga": Vector3(-3.5, 0, 0.75),
	"nh:N_JungeSchwarzeNaga": Vector3(-1.25, 0, -0.5),
	"nh:N_JungeWaechterNaga": Vector3(3.5, 0, 0),
	"nh:N_RoteNaga": Vector3(7.25, 0, -0.25),
	"nh:N_SchwarzeNaga": Vector3(8, 0, -1.25),
	"nh:N_WaechterNaga": Vector3(-3.5, 0, -0.5),
	"nh:n_Wassernymphe": Vector3(-2.13, 0, 0),   # Körper senkrecht, Schleppe liegt auf (SCHLEPPE)
	"nh:o_Goblin": Vector3(-6, 0.3, 2.69),   # Peter Nr. 219: lehnte vor (vorher 3,75); aufgerichtet, gebückte Pose bleibt
	"nh:o_Goblinkoenig": Vector3(-2.25, 0, 0.5),
	"nh:o_Huegelork": Vector3(-0.25, 0, 0),
	"nh:O_Oger": Vector3(1.75, 0, 0.5),
	"nh:O_Ogerfuerst": Vector3(2.19, 0, 0.26),   # Peter: lehnte nach vorn (vorher 15,75); Rumpf senkrecht
	"nh:O_Ogerkoenig": Vector3(5.5, 0, 0.25),
	"nh:o_OrkHauptmann": Vector3(-2, 0, 0),
	"nh:o_OrkSchamane": Vector3(-5.46, 0, -7.18),   # Körper senkrecht, Schleppe liegt auf (SCHLEPPE)
	"nh:o_UrukHai": Vector3(-1, 0, -0.25),
	"nh:P_BraunerPudding": Vector3(-2.75, 0, 0),
	"nh:p_Eisendurchbohrer": Vector3(-16.75, 0, -0.25),
	"nh:p_Glasdurchbohrer": Vector3(-11.5, 0, -0.25),
	"nh:q_Baluchitherium": Vector3(13, 45, -0.5),
	"nh:q_Mastodon": Vector3(5.5, 45, 0.25),
	"nh:q_Mumak": Vector3(6.5, 45, 0.25),
	"nh:Q_Quantenmechaniker": Vector3(6.75, 0, 0),
	"nh:q_Rothe": Vector3(8.25, 45, 0.5),
	"nh:q_Titanothere": Vector3(6.25, 45, 1),
	"nh:q_Wumpus": Vector3(5, 45, 0.5),
	"nh:R_Entzauberer": Vector3(10.25, 0, -0.25),
	"nh:r_Felsmaulwurf": Vector3(4.25, 45, 1.5),
	"nh:r_Kanalratte": Vector3(-3, 45, -1),
	"nh:r_Murmeltier": Vector3(9, 0, 0.5),
	"nh:r_TollwutRatte": Vector3(-0.75, 45, -0.75),
	"nh:r_Werratte": Vector3(-2, 45, -0.5),
	"nh:S_Grubenotter": Vector3(0.25, 0, -1.25),
	"nh:s_Hoehlenspinne": Vector3(3, 0, -0),
	"nh:s_Hundertfuesser": Vector3(13.6, 0, -0.5),
	"nh:S_Kobra": Vector3(2, 0, -0.75),
	"nh:S_Python": Vector3(2.25, 0, -0.5),
	"nh:s_Riesenspinne": Vector3(8.25, 0, 0),
	"nh:s_Scorpius": Vector3(23.75, 0, 0.5),
	"nh:S_Strumpfbandnatter": Vector3(-21, 0, 1),
	"nh:S_Wassermokassin": Vector3(-5, 0, 1.75),
	"nh:T_Eistroll": Vector3(9.75, 0, 0),
	"nh:T_Felstroll": Vector3(11.75, 0, -2),
	"nh:T_OlogHai": Vector3(-4, 0, 1),
	"nh:T_Wassertroll": Vector3(7.75, 0, -2),
	"nh:Tilde_Hai": Vector3(0, 90, 0),   # neues Modell (Bild 2, von der Seite, gerade): Kopf zum Weg, liegt waagerecht
	"nh:Tilde_Krake": Vector3(-10.5, 0, -4),
	"nh:Tilde_Piranha": Vector3(-5.8, -140.5, -8.4),   # Peter: stand falsch; liegt/schwimmt waagerecht (Hauptachsen)
	"nh:Tilde_Qualle": Vector3(-1, 0, 4.75),
	"nh:Tilde_Zitteraal": Vector3(-77.1, -155.2, -25.8),   # Peter: stand falsch; liegt/schwimmt waagerecht (Hauptachsen)
	"nh:u_GrauesEinhorn": Vector3(9.2, 46.77, -0.34),   # Peter Nr. 297: neu gebaut (Seed 303), schwebenden Brocken entfernt (splitter_weg.py), Hufe flach
	"nh:u_Kriegspferd": Vector3(7.5, 45, 0.5),
	"nh:u_Pferd": Vector3(8.25, 45, -1.75),
	"nh:u_Pony": Vector3(10, 45, 0.5),
	"nh:u_WeissesEinhorn": Vector3(11, 45, -2.75),
	"nh:Und_Asmodeus": Vector3(5.5, 0, 0.5),
	"nh:Und_Baalzebub": Vector3(11, 0, 0.5),
	"nh:Und_Balrog": Vector3(8.25, 0, -2.5),
	"nh:Und_Demogorgon": Vector3(15.25, 0, -0.25),
	"nh:Und_DienerHuhetotls": Vector3(4, 0, -2.25),
	"nh:Und_Dispater": Vector3(0, 0, -0.75),
	"nh:Und_Dschinn": Vector3(6, 0, -0.25),
	"nh:Und_Eisteufel": Vector3(0.5, 0, 5.75),
	"nh:Und_Erinnye": Vector3(-3, 0, 0),
	"nh:Und_GehoernterTeufel": Vector3(5.25, 0, -0.75),
	"nh:Und_Grubenunhold": Vector3(-4, 0, 2.5),
	"nh:Und_Hezrou": Vector3(8, 0, -0.25),
	"nh:Und_Hunger": Vector3(4.5, 0, 0.5),
	"nh:Und_Inkubus": Vector3(8.5, 0, -0.25),
	"nh:Und_Juiblex": Vector3(4, 0, 0.5),
	"nh:Und_Knochenteufel": Vector3(3, 0, -1.75),
	"nh:Und_Marilith": Vector3(7.5, 0, 0.5),
	"nh:Und_Nalfeshnee": Vector3(-1.25, 0, -0.25),
	"nh:Und_Nalzok": Vector3(16, 0, 6.5),
	"nh:Und_Orcus": Vector3(-1.25, 0, 0),
	"nh:Und_Pestilenz": Vector3(-0.05, 0, 0.74),   # Peter Nr. 288: Pferd stieg; Hufe flach (Reiter beugt sich vor)
	"nh:Und_Postdaemon": Vector3(4, 0, -1.5),
	"nh:Und_Sandestin": Vector3(0.75, 0, -0.25),
	"nh:Und_Stachelteufel": Vector3(1, 0, -0.25),
	"nh:Und_Sukkubus": Vector3(-0.7, 0, 0),   # Peter: 1,78 zu weit vor, -3,2 zu weit hinten -> Mitte
	"nh:Und_Tod": Vector3(6.46, 0.05, 0.34),   # Saum flach (Peter: Robe liegt auf), Lehnen 5.4°
	"nh:Und_Vrock": Vector3(-12, 0, 0.46),   # Peter Nr. 294: zu weit vor; Kompromiss (geduckte Geierpose)
	"nh:Und_Wasserdaemon": Vector3(5, 0, 0.5),
	"nh:Und_Yeenoghu": Vector3(2.64, 0, -0.09),   # Peter Nr. 296: lehnte zurück (vorher -20,25); Füße flach, Lehnen 1,4°
	"nh:v_Dampfwirbel": Vector3(-3, 0, -5),
	"nh:v_Eiswirbel": Vector3(-15, 0, 5.75),
	"nh:v_Energiewirbel": Vector3(1.5, 0, -6),
	"nh:v_Feuerwirbel": Vector3(-9.5, 0, 0),
	"nh:v_Staubwirbel": Vector3(-7.25, 0, -4.25),
	"nh:V_Vampirfuerst": Vector3(3.43, 0.01, 0.06),   # Saum flach (Peter: Robe liegt auf), Lehnen 7.7°
	"nh:V_Vampirmagier": Vector3(-3.56, 0, 4.42),   # Körper senkrecht, Schleppe liegt auf (SCHLEPPE)
	"nh:V_VladDerPfaehler": Vector3(-0.8, 0, -0.18),   # Saum flach (Peter: Robe liegt auf), Lehnen 5.4°
	"nh:W_Grabunhold": Vector3(-2.26, -0.01, 0.17),   # Saum flach (Peter: Robe liegt auf), Lehnen 6.6°
	"nh:w_JungerLangwurm": Vector3(6, 0, -0.5),
	"nh:w_JungerPurpurwurm": Vector3(-4.25, 0, 0.25),
	"nh:W_Nazgul": Vector3(1.75, 0, -0.5),
	"nh:X_Geist": Vector3(14.25, 0, -1.5),
	"nh:x_Gitterkaefer": Vector3(-14.75, 0, 2.75),
	"nh:X_Schatten": Vector3(-17.75, 0, 2.5),
	"nh:Y_Affe": Vector3(8, 0, 1.25),
	"nh:Y_Fleischfresseraffe": Vector3(5.75, 0, 0),
	"nh:Y_MenschenAffe": Vector3(9, 0, -1.25),
	"nh:Y_Sasquatch": Vector3(3, 0, 0.75),
	"nh:y_SchwarzesLicht": Vector3(-0.5, 0, 1.5),
	"nh:Z_Elfenzombie": Vector3(4, 0, 0.25),
	"nh:Z_Ettinzombie": Vector3(6.5, 0, 0.25),
	"nh:Z_Ghul": Vector3(1, 0, -1.75),
	"nh:Z_Gnomenzombie": Vector3(-0.75, 0, 0.25),
	"nh:Z_Koboldzombie": Vector3(6, 0, 1),
	"nh:Z_Orkzombie": Vector3(2.75, 0, 0.25),
	"nh:Z_Riesenzombie": Vector3(-4.5, 0, 0.25),   # Peter Nr. 328: lehnte vor
	"nh:Z_Skelett": Vector3(3.4, 0, 5.67),   # Peter Nr. 329: nach Vergleichsbild wieder wie vorher (3,4)
	"nh:Z_Zwergenzombie": Vector3(-1.75, 0, -0.5),
}
const FLUGHOEHE := 1.8            # Mitte des Fliegers über dem Boden
const MONSTER_HELLIGKEIT := 1.5   # Standbilder sind heller als ihre Umgebung, damit man sie erkennt
const WARTEN_AUF_MELDUNG := 30.0  # so lange darf die Todesmeldung nachkommen (--More-- wartet auf eine Taste)
# Englische Namen aus dem Original (extern.c), um Kampfmeldungen zuzuordnen
const ROGUE_NAMEN := {
	"A": "aquator", "B": "bat", "C": "centaur", "D": "dragon", "E": "emu", "F": "venus flytrap",
	"G": "griffin", "H": "hobgoblin", "I": "ice monster", "J": "jabberwock", "K": "kestrel",
	"L": "leprechaun", "M": "medusa", "N": "nymph", "O": "orc", "P": "phantom", "Q": "quagga",
	"R": "rattlesnake", "S": "snake", "T": "troll", "U": "black unicorn", "V": "vampire",
	"W": "wraith", "X": "xeroc", "Y": "yeti", "Z": "zombie",
}

var fuehler   # fuehler.gd, von grafik.gd gesetzt
# NetHack (1987) VR: Monster heißen dort "nh:<Schlüssel>" (nethack-monster) oder "hk:<Schlüssel>" (hack-monster),
# Rogue-Monster behalten ihren Buchstaben. Zuordnung englischer Name -> Figur: nethack-monster/monster_namen.txt.
var _nh_karte := {}             # englischer Name -> [Kennung, Meter]
var _nh_namen := {}             # Kennung -> englischer Name (klein), für Kampfmeldungen
var _nh_meter := {}             # Kennung -> Größe in Metern
var _nh_bilder := {}            # Schlüssel -> neuestes Bild in nethack-monster/bilder
## Von Hand aufgestellt (Galerie, Taste T): Kennung -> Vector4(kippen x, y, z in Grad, Höhe in cm).
## Steht in grafik/aufstellung.txt und geht vor KIPPEN (die Drehung ersetzt den KIPPEN-Wert, die Höhe kommt dazu).
const AUFSTELLUNG_DATEI := "res://grafik/aufstellung.txt"
var aufstellung := {}
var aufstellung_versatz := {}   # Kennung -> Vector2 (rechts, hinten) in cm, in Blickrichtung der Figur
var _aufstellung_geladen := false
var roh_merken := false         # Galerie: geladene Dateien im Speicher halten (schneller Neuaufbau beim Aufstellen)
var _roh := {}
var aktive: Array = []          # Monster auf dem aktuellen Bild: {c, p, knoten, versatz, bild, modell ...}
var _gemeldet: Array = []       # [Buchstabe, Feld] aus dem laufenden Rogue-Bild
var _sterbende: Array = []      # liegen als Leiche bis zum Ende der Ebene
var _verschwunden: Array = []   # eben vom Bild gegangen: die Todesmeldung kann noch nachkommen
var _bilder := {}               # "A" / "A_angriff" -> Texture2D oder null
var _masse_daten = null
var _modelle3d := {}            # Buchstabe -> Vorlage (Node3D) oder null
var _grundflaeche := {}         # Buchstabe -> Größe der Standfläche (x, z) in Metern, für den Kontaktschatten
var _schatten_stoff: StandardMaterial3D = null
var _blitz: ColorRect
var _zeit := 0.0
var _runde := 0
var _kampf := {}                # Buchstabe -> Runde der letzten Kampfmeldung
var _getoetet := {}             # Buchstabe -> Runde, in der Rogue seinen Tod gemeldet hat
var _letzte_kampfmeldung := ""
var _angriff_offen := {}        # Buchstabe -> hat in dieser Meldung wirklich angegriffen


func ebene_neu() -> void:
	_kampf.clear()
	alle_weg()


func alle_weg() -> void:
	for liste in [aktive, _sterbende, _verschwunden]:
		for m in liste:
			m.knoten.queue_free()
		liste.clear()


# ---------------------------------------------------------------- pro Rogue-Bild

func beginnen() -> void:
	_gemeldet.clear()


## true = dieses Monster zeichnet monster.gd (es gibt ein Bild), sonst Platzhalter in dungeon_3d.gd.
## NetHack: c leer lassen und den englischen Namen übergeben.
func melden(c: String, p: Vector2i, name := "") -> bool:
	if name != "":
		c = nh_kennung(name)
		if c == "":
			return false
	if _bild(c) == null and _modell3d(c) == null:
		return false
	_gemeldet.append([c, p])
	return true


## Nach jedem Rogue-Bild: Monster wiedererkennen (gleicher Buchstabe in der Nähe) und hingleiten lassen.
func fertig(spieler: Vector2i) -> void:
	_runde += 1
	fuehler.monster_lesen()
	var alt := aktive.duplicate()
	var neu: Array = []
	for g in _gemeldet:
		var c: String = g[0]
		var p: Vector2i = g[1]
		var bester := -1
		var dist := 99
		for i in alt.size():
			var m: Dictionary = alt[i]
			if m.c != c:
				continue
			var d: int = _abstand(m.p, p)
			if d < dist and d <= 3:
				dist = d
				bester = i
		var m: Dictionary
		if bester >= 0:
			m = alt[bester]
			alt.remove_at(bester)
			if m.p != p:
				m.bewegt = true
				var weg := Vector2(p - m.p)
				m.eigene_blick = atan2(-weg.x, -weg.y)   # hat es dich nicht bemerkt, schaut es in Laufrichtung
				create_tween().tween_property(m.knoten, "position", _ort(p), 0.25).set_trans(Tween.TRANS_SINE)
			m.p = p
		else:
			m = _bauen(c, p)
		neu.append(m)
		_zustand_pruefen(m, spieler)
	# Wer laut Meldung angegriffen hat: das nächste Monster dieser Art stößt vor
	for c in _angriff_offen:
		var bester: Dictionary = {}
		var dist := 999
		for m in neu:
			var d: int = _abstand(m.p, spieler)
			if m.c == c and d < dist:
				dist = d
				bester = m
		if bester and bester.get("drei_d", false):
			_vorstoss(bester, spieler)
	_angriff_offen.clear()
	for m in alt:
		if m.get("drei_d", false) and _getoetet.get(m.c, -9) >= _runde - 1:
			_getoetet.erase(m.c)
			_sterben_beginnen(m)
		else:
			# Rogue nimmt das Monster oft einen Moment vor der Todesmeldung vom Bild
			m.knoten.visible = false
			m.weg_zeit = WARTEN_AUF_MELDUNG
			_verschwunden.append(m)
	aktive = neu


func _abstand(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _ort(p: Vector2i) -> Vector3:
	return Vector3(p.x * ZELLE, 0.0, p.y * ZELLE)


func _bauen(c: String, p: Vector2i) -> Dictionary:
	var knoten := Node3D.new()
	knoten.position = _ort(p)
	add_child(knoten)
	var versatz := Node3D.new()      # für den Ruck beim Angriff
	knoten.add_child(versatz)
	var bild := MeshInstance3D.new()
	bild.mesh = QuadMesh.new()
	bild.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # Aufsteller-Schatten wären verdreht und stören den Nebel
	_bild_setzen(bild, c, _bild(c))
	versatz.add_child(bild)
	var m := {"c": c, "p": p, "knoten": knoten, "bild": bild, "versatz": versatz, "angriff": false,
			"phase": randf() * TAU}
	var modell := _modell3d(c)
	if modell:
		bild.visible = false
		if schwebt(c):
			modell.position.y += FLUGHOEHE - _meter(c) * 0.5   # Bodenausgleich steckt schon drin
		versatz.add_child(modell)
		if not schwebt(c) and _grundflaeche.has(c):
			versatz.add_child(_kontaktschatten(_grundflaeche[c]))
		m.modell = modell
		m.modell_y0 = modell.position.y
		m.drei_d = true
		# eigene Blickrichtung (eine der 8 Rogue-Richtungen); zum Spieler dreht es sich erst, wenn es ihn bemerkt
		m.eigene_blick = snappedf(randf() * TAU, PI / 4.0)
		knoten.rotation.y = m.eigene_blick
	return m


func _vorstoss(m: Dictionary, spieler: Vector2i) -> void:
	var richtung := Vector3(spieler.x - m.p.x, 0, spieler.y - m.p.y).normalized()
	var tw := create_tween()
	tw.tween_property(m.versatz, "position", richtung * 0.55, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(m.versatz, "position", Vector3.ZERO, 0.35).set_trans(Tween.TRANS_SINE)


## 3D-Monster kippt um und bleibt liegen.
func _sterben_beginnen(m: Dictionary) -> void:
	m.tot = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(m.modell, "rotation:x", -PI / 2.0 * 0.92, 0.9).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	var y: float = m.modell.position.y
	if schwebt(m.c):
		tw.tween_property(m.modell, "position:y", 0.2, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		tw.tween_property(m.modell, "position:y", y + 0.15, 0.9)
	_sterbende.append(m)


## Die Todesmeldung kam erst, nachdem das Monster vom Bild verschwunden war.
func _nachtraeglich_sterben(c: String) -> void:
	for i in range(_verschwunden.size() - 1, -1, -1):
		var m: Dictionary = _verschwunden[i]
		if m.c == c and m.get("drei_d", false):
			_verschwunden.remove_at(i)
			_getoetet.erase(c)
			m.knoten.visible = true
			_sterben_beginnen(m)
			return


# ---------------------------------------------------------------- 3D-Modelle

func _modell3d(c: String) -> Node3D:
	if not _modelle3d.has(c):
		var pfad := ProjectSettings.globalize_path("res://modelle/monster3d/%s.glb" % c)
		if c.begins_with("nh:") or c.begins_with("hk:"):
			pfad = _wah(("nethack-monster/3d/" if c.begins_with("nh:") else "hack-monster/3d/") + c.substr(3) + ".glb")
		var vorlage: Node3D = null
		if roh_merken and _roh.has(pfad):
			vorlage = (_roh[pfad] as Node3D).duplicate() as Node3D
		elif FileAccess.file_exists(pfad):
			vorlage = ModellHilfe.laden(pfad)
			if roh_merken and vorlage:
				_roh[pfad] = vorlage.duplicate()
		if vorlage:
			# Hack-/NetHack-Dateien blicken nach +Z, Rogue-Dateien nach -Z (Fototest 22.11.: zeigten den Rücken).
			# Schief erzeugte Modelle (Peter 22.11.: "viele sind gekippt") werden mit KIPPEN gerade gestellt.
			var dreh := Basis()
			if c.begins_with("nh:") or c.begins_with("hk:"):
				dreh = Basis(Vector3.UP, PI)
			aufstellung_laden()
			var hat_kippen: bool = aufstellung.has(c) or KIPPEN.has(c)
			if hat_kippen:
				var k: Vector3 = kippen_wert(c)
				dreh = dreh * Basis.from_euler(Vector3(deg_to_rad(k.x), deg_to_rad(k.y), deg_to_rad(k.z)))
			vorlage.transform = Transform3D(dreh, Vector3.ZERO)
			# gekippte Modelle genau über die Eckpunkte messen (die gedrehte Kiste wäre zu groß und sie schwebten)
			var kiste := ModellHilfe.huelle_genau(vorlage, Transform3D.IDENTITY) if hat_kippen \
					else ModellHilfe.huelle(vorlage, Transform3D.IDENTITY)
			if c in SCHLEPPE:
				var fy := ModellHilfe.fuss_hoehe_vorn(vorlage, kiste)
				ModellHilfe.boden_klemmen(vorlage, fy)
				kiste = ModellHilfe.huelle_genau(vorlage, Transform3D.IDENTITY)
			var ziel: float = _meter(c)
			var groesste := maxf(kiste.size.y, maxf(kiste.size.x, kiste.size.z) if schwebt(c) else 0.0)
			var f := ziel / groesste if groesste > 0.01 else 1.0
			# Füße genau auf den Boden, Mitte über das Feld (Peter 22.11.: "versinken alle"): nicht auf den
			# Ursprung der Datei verlassen, sondern nach der Hülle ausrichten. Flieger rechnen das in _bauen dazu.
			# Mitte = Füße (unterste 10 %), nicht die ganze Hülle: sonst schiebt eine große Axt, Flügel oder
			# ein Schwanz den Körper neben das Feld (Peter 22.11.: Minotaurus-Hufe neben dem Ring). Flieger wie bisher.
			var mitte := Vector2(kiste.position.x + kiste.size.x * 0.5, kiste.position.z + kiste.size.z * 0.5)
			if not schwebt(c) and not c in MITTE_HUELLE:
				mitte = ModellHilfe.fuss_mitte(vorlage, kiste.position.y + kiste.size.y * 0.1, mitte)
			vorlage.transform = Transform3D(dreh.scaled(Vector3.ONE * f), Vector3(
					-mitte.x * f,
					-(kiste.position.y + kiste.size.y * float(EINSINKEN.get(c, 0.0))) * f + hoehe_wert(c),
					-mitte.y * f) + Vector3(versatz_wert(c).x, 0, versatz_wert(c).y))
			print("3D-Monster geladen: ", c, " Größe ", kiste.size, " -> Faktor ", f)
			_grundflaeche[c] = Vector2(kiste.size.x, kiste.size.z) * f
			if c in GLAS:
				_glas_machen(vorlage)
			elif c in GEISTER:
				_glas_machen(vorlage, true)
		_modelle3d[c] = vorlage
	var v: Node3D = _modelle3d[c]
	return v.duplicate() as Node3D if v else null


## Dunkler, weicher Fleck direkt unter den Füßen (Peter 22.11.: "viele schweben", obwohl sie den Boden
## berühren). Ohne diesen Kontaktschatten wirken Figuren im Dämmerlicht, als hingen sie in der Luft.
## Drehung (Grad) für Kennung c: von Hand aufgestellt vor KIPPEN.
func kippen_wert(c: String) -> Vector3:
	aufstellung_laden()
	if aufstellung.has(c):
		var a: Vector4 = aufstellung[c]
		return Vector3(a.x, a.y, a.z)
	return KIPPEN.get(c, Vector3.ZERO)


## Zusätzliche Höhe in Metern (von Hand aufgestellt).
func hoehe_wert(c: String) -> float:
	aufstellung_laden()
	return (aufstellung[c] as Vector4).w / 100.0 if aufstellung.has(c) else 0.0


## Verschiebung in Metern (rechts, hinten), von Hand aufgestellt.
func versatz_wert(c: String) -> Vector2:
	aufstellung_laden()
	return (aufstellung_versatz.get(c, Vector2.ZERO) as Vector2) / 100.0


func aufstellung_laden() -> void:
	if _aufstellung_geladen:
		return
	_aufstellung_geladen = true
	if not FileAccess.file_exists(AUFSTELLUNG_DATEI):
		return
	for z in FileAccess.get_file_as_string(AUFSTELLUNG_DATEI).split("\n", false):
		var t := z.strip_edges().split("|")
		if z.begins_with("#") or t.size() < 5:
			continue
		aufstellung[t[0]] = Vector4(float(t[1]), float(t[2]), float(t[3]), float(t[4]))
		if t.size() >= 7:
			aufstellung_versatz[t[0]] = Vector2(float(t[5]), float(t[6]))


## Neuen Wert setzen, sofort speichern und die Vorlage verwerfen (die Figur muss neu gebaut werden).
func aufstellung_setzen(c: String, wert: Vector4, versatz_cm := Vector2.ZERO) -> void:
	aufstellung_laden()
	aufstellung[c] = wert
	if versatz_cm != Vector2.ZERO:
		aufstellung_versatz[c] = versatz_cm
	else:
		aufstellung_versatz.erase(c)
	_modelle3d.erase(c)
	_aufstellung_schreiben()


func _aufstellung_schreiben() -> void:
	var schluessel := aufstellung.keys()
	schluessel.sort()
	var text := "# Von Hand aufgestellte Figuren (Galerie, Taste T): Kennung|kippen x|y|z (Grad)|Höhe (cm)|verschoben rechts|hinten (cm)\n"
	for k in schluessel:
		var a: Vector4 = aufstellung[k]
		var v: Vector2 = aufstellung_versatz.get(k, Vector2.ZERO)
		text += "%s|%s|%s|%s|%s|%s|%s\n" % [k, snappedf(a.x, 0.1), snappedf(a.y, 0.1), snappedf(a.z, 0.1), snappedf(a.w, 0.1),
				snappedf(v.x, 0.1), snappedf(v.y, 0.1)]
	var f := FileAccess.open(ProjectSettings.globalize_path(AUFSTELLUNG_DATEI), FileAccess.WRITE)
	if f:
		f.store_string(text)
		f.close()


## Von Hand aufgestellten Wert wieder löschen (Figur zurück auf KIPPEN/Ausgang).
func aufstellung_entfernen(c: String) -> void:
	aufstellung_laden()
	if aufstellung.has(c):
		aufstellung.erase(c)
		aufstellung_versatz.erase(c)
		_modelle3d.erase(c)
		_aufstellung_schreiben()


func _kontaktschatten(flaeche: Vector2) -> MeshInstance3D:
	if _schatten_stoff == null:
		var verlauf := Gradient.new()
		verlauf.set_color(0, Color(0, 0, 0, 0.8))
		verlauf.set_color(1, Color(0, 0, 0, 0))
		verlauf.add_point(0.55, Color(0, 0, 0, 0.45))
		var tex := GradientTexture2D.new()
		tex.gradient = verlauf
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(0.5, 0.0)
		tex.width = 128
		tex.height = 128
		_schatten_stoff = StandardMaterial3D.new()
		_schatten_stoff.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_schatten_stoff.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_schatten_stoff.albedo_texture = tex
		_schatten_stoff.albedo_color = Color(1, 1, 1, 1)
		_schatten_stoff.no_depth_test = false
		_schatten_stoff.render_priority = -1
	var fleck := MeshInstance3D.new()
	var ebene := PlaneMesh.new()
	# etwas größer als die Standfläche, aber nicht riesig bei Flügeln/Schwänzen
	var groesse := Vector2(clampf(flaeche.x * 1.05, 0.4, 3.0), clampf(flaeche.y * 1.05, 0.4, 3.0))
	ebene.size = groesse
	fleck.mesh = ebene
	fleck.material_override = _schatten_stoff
	fleck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fleck.position.y = 0.006
	fleck.name = "Kontaktschatten"
	return fleck


## Durchsichtige Figuren (Peter 22.11.: Glasgolem durchsichtiger): Farbe bleibt, aber wie Glas.
const GLAS := ["nh:Golem_Glasgolem", "nh:p_Glasdurchbohrer"]
## Geister halb durchsichtig mit kaltem Schimmer (Peter 22.11.: "Gespenst wirklich wie Gespenst durchsichtig").
const GEISTER := ["nh:X_Geist", "nh:X_Schatten"]


func _glas_machen(knoten: Node, geist := false) -> void:
	if knoten is MeshInstance3D:
		var mi := knoten as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var alt := mi.get_active_material(i) as BaseMaterial3D
			var m := StandardMaterial3D.new()
			if alt:
				m.albedo_texture = alt.albedo_texture
				m.albedo_color = alt.albedo_color
				m.normal_enabled = alt.normal_enabled
				m.normal_texture = alt.normal_texture
			m.albedo_color.a = 0.35
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
			if geist:
				m.albedo_color = Color(m.albedo_color.r, m.albedo_color.g, m.albedo_color.b, 0.28)
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				m.emission_enabled = true
				m.emission = Color(0.55, 0.7, 0.9)
				m.emission_energy_multiplier = 0.6
				m.disable_receive_shadows = true
			m.roughness = 0.05
			m.metallic = 0.3
			m.metallic_specular = 1.0
			m.rim_enabled = true      # helle Kanten, damit man die Form im Dunkeln erkennt
			m.rim = 0.6
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			if geist:
				m.metallic = 0.0
			mi.set_surface_override_material(i, m)
			if geist:
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for k in knoten.get_children():
		_glas_machen(k, geist)


func _blick_zum_spieler(von: Vector3) -> float:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return 0.0
	var v := cam.global_position - von
	return atan2(-v.x, -v.z)


# ---------------------------------------------------------------- Standbilder (Ersatz ohne 3D-Modell)

func _bild(name: String) -> Texture2D:
	if not _bilder.has(name):
		var pfad := ProjectSettings.globalize_path("res://modelle/monster/" + name + ".png")
		if name.begins_with("nh:") or name.begins_with("hk:"):
			pfad = _nh_bildpfad(name)
		var tex: Texture2D = null
		if FileAccess.file_exists(pfad):
			var img := Image.load_from_file(pfad)
			if img and not img.is_empty():
				img.generate_mipmaps()
				tex = ImageTexture.create_from_image(img)
		_bilder[name] = tex
	return _bilder[name]


## Bildgrößen der Posen (modelle/monster/masse.json), damit z. B. eine hockende Pose kleiner wirkt.
func _masse() -> Dictionary:
	if _masse_daten == null:
		var txt := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://modelle/monster/masse.json"))
		var d = JSON.parse_string(txt) if txt != "" else null
		_masse_daten = d if d is Dictionary else {}
	return _masse_daten


## Bild auf ein senkrechtes Rechteck legen, das sich immer zur Kamera dreht (nur um die Hochachse).
## Durchsichtige Stellen werden ausgeschnitten.
func _bild_setzen(bild: MeshInstance3D, c: String, tex: Texture2D, name := "") -> void:
	if tex == null:
		# Kein Standbild (im Paket liegen nur die 3D-Modelle): Aufsteller unsichtbar, die 3D-Figur kommt trotzdem
		bild.visible = false
		bild.set_meta("tex", null)
		return
	var meter: float = _meter(c)
	var flieger := schwebt(c)
	var faktor := 1.0
	if name != "" and name != c:
		var mb: Dictionary = _masse().get(c, {})
		var mp: Dictionary = _masse().get(name, {})
		if mb and mp:
			faktor = float(mp.breite if flieger else mp.hoehe) / maxf(float(mb.breite if flieger else mb.hoehe), 0.01)
	meter *= faktor
	var seite := float(tex.get_width()) / tex.get_height()
	var groesse := Vector2(meter, meter / seite) if flieger else Vector2(meter * seite, meter)
	(bild.mesh as QuadMesh).size = groesse
	bild.position.y = FLUGHOEHE if flieger else groesse.y / 2.0
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.billboard_keep_scale = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.85
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.albedo_color = Color.WHITE * MONSTER_HELLIGKEIT
	m.disable_receive_shadows = true
	if c in GEISTER or c in GLAS:   # auch als Standbild durchsichtig
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color.a = 0.35
	bild.material_override = m
	bild.set_meta("tex", tex)


## Standbild für den Zustand (A_angriff, A_ruhe ...; "zweites" = kurzes Zwischenbild), sonst das Grundbild.
func _zustandsbild(m: Dictionary, zustand: String, zweites := false) -> void:
	var name: String = m.c
	if zustand == "angriff":
		name = m.c + ("_angriff2" if zweites else "_angriff")
	elif zustand == "ruhe":
		name = m.c + ("_ruhe2" if zweites else "_ruhe")
	var tex := _bild(name)
	if tex == null and zweites:
		return
	if tex == null:
		name = m.c
		tex = _bild(m.c)
	if m.bild.get_meta("tex") != tex:
		_bild_setzen(m.bild, m.c, tex, name)
		_verletzung_zeigen(m)


## Verletzt: das Standbild wird mit sinkenden Lebenspunkten dunkler und röter.
func _verletzung_zeigen(m: Dictionary) -> void:
	var lp: float = m.get("lp", 1.0)
	var mat := m.bild.material_override as StandardMaterial3D
	if mat:
		var schaden := clampf(1.0 - lp, 0.0, 1.0)
		var a := mat.albedo_color.a   # Durchsichtigkeit (Geister, Glas) behalten
		mat.albedo_color = (Color.WHITE * MONSTER_HELLIGKEIT).lerp(Color(0.85, 0.45, 0.4) * MONSTER_HELLIGKEIT, schaden * 0.9)
		mat.albedo_color.a = a


# ---------------------------------------------------------------- Kampf und Zustand

## Wird das Monster in diesem Text genannt? ("snake" steckt auch in "rattlesnake")
func _genannt(c: String, text: String) -> bool:
	return _namen().get(c, "#ohne Namen#") in text and not (c == "S" and "rattlesnake" in text)


## Namen für Kampfmeldungen: Rogue-Buchstaben und die NetHack-Monster dieser Ebene.
func _namen() -> Dictionary:
	if _nh_namen.is_empty():
		return ROGUE_NAMEN
	var n := ROGUE_NAMEN.duplicate()
	n.merge(_nh_namen, true)
	return n


# ---------------------------------------------------------------- NetHack-Figuren

## Pfad im Projektordner "We Are Hack" (eine Ebene über rogue-godot).
func _wah(teil: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("..").path_join(teil).simplify_path()


## Kennung der Figur zum englischen NetHack-Namen ("" = keine Figur, dann Platzhalter).
func nh_kennung(name: String) -> String:
	if _nh_karte.is_empty():
		# Hack hat eine eigene Tabelle (Hack-Figuren, Rogue-Modelle, wenige NetHack-Ersatzfiguren)
		var hack: bool = preload("res://spiel.gd").ist_hack()
		var txt := FileAccess.get_file_as_string(_wah("hack-monster/monster_namen.txt" if hack else "nethack-monster/monster_namen.txt"))
		for z in txt.split("\n", false):
			var t := z.strip_edges().split("|")
			if z.begins_with("#") or t.size() < 4:
				continue
			var kennung: String = t[2] if t[1] == "rogue" else ("nh:" if t[1] == "nethack" else "hk:") + t[2]
			_nh_karte[t[0]] = [kennung, minf(float(t[3]), 3.0)]   # nicht höher als die Gänge
		if _nh_karte.is_empty():
			_nh_karte["-"] = ["", 1.8]
	var e: Array = _nh_karte.get(name, [])
	if e.is_empty():
		return ""
	var kennung: String = e[0]
	if not kennung.begins_with("nh:") and not kennung.begins_with("hk:"):
		if NH_ROGUE_GROESSE.has(kennung) and not preload("res://spiel.gd").ist_hack():
			_nh_rogue_groesse[kennung] = NH_ROGUE_GROESSE[kennung]
		return kennung   # Rogue-Monster: Buchstabe, eigene Größe aus MONSTER_GROESSE (in NetHack ggf. NH_ROGUE_GROESSE)
	_nh_meter[kennung] = e[1]
	_nh_namen[kennung] = name.to_lower()
	return kennung


## Fliegt oder schwebt die Figur (Flieger und Sphären)?
static func schwebt(c: String) -> bool:
	return (c.length() == 1 and c in FLIEGER) or c in KUGELN


## NetHack-eigene Größen für Figuren, die das Rogue-Modell nutzen (Rogue selbst bleibt bei MONSTER_GROESSE):
## Kobold = Rogue-L, Hobgoblin = Rogue-H, Ork = Rogue-O (Peter 22.11.).
const NH_ROGUE_GROESSE := {"L": 1.2, "H": 1.6, "O": 1.8}
var _nh_rogue_groesse := {}     # wird nur im NetHack-Spiel gefüllt (nh_kennung)
const MINDESTGROESSE := 0.8   # Peter 22.11.: "alle kleineren so 80 cm" (Chamäleon, Ratte ...), nur Hack/NetHack


func _meter(c: String) -> float:
	if GROESSE_PETER.has(c):
		return GROESSE_PETER[c]
	if _nh_rogue_groesse.has(c):
		return _nh_rogue_groesse[c]
	if MONSTER_GROESSE.has(c):
		return MONSTER_GROESSE[c]
	return maxf(float(_nh_meter.get(c, 1.8)), MINDESTGROESSE)


## Standbild einer NetHack-/Hack-Figur ("" = keins; Zustandsbilder wie _angriff gibt es dort nicht).
func _nh_bildpfad(name: String) -> String:
	for endung in ["_angriff2", "_angriff", "_ruhe2", "_ruhe"]:
		if name.ends_with(endung):
			return ""
	var key := name.substr(3)
	if name.begins_with("hk:"):
		return _wah("hack-monster/gewaehlt/" + key + ".png")
	if _nh_bilder.is_empty():
		var ordner := _wah("nethack-monster/bilder")
		var zeit := {}
		for f in DirAccess.get_files_at(ordner):
			if not f.ends_with("_00001_.png"):
				continue
			var k := f.substr(0, f.rfind("_", f.length() - 12))   # <Schlüssel>_<nr>_00001_.png
			var t := FileAccess.get_modified_time(ordner.path_join(f))
			if t >= int(zeit.get(k, -1)):
				zeit[k] = t
				_nh_bilder[k] = ordner.path_join(f)
		if _nh_bilder.is_empty():
			_nh_bilder["-"] = ""
	return _nh_bilder.get(key, "")


## Kämpft gerade jemand? ("the centaur hits", "you miss the orc", "the bat bit you" ...)
func _kampf_auswerten(meldung: String) -> void:
	var m := meldung.to_lower()
	if "defeated" in m or "kill" in m or "destroy" in m:
		for c in _namen():
			if _genannt(c, m):
				_getoetet[c] = _runde
				_nachtraeglich_sterben(c)
		if " it" in m and not _verschwunden.is_empty():   # im Dunkeln nennt Rogue keinen Namen
			_nachtraeglich_sterben(_verschwunden.back().c)
	if not ("hit" in m or "miss" in m or "injur" in m or "swing" in m or "scored" in m or " bit" in m):
		_letzte_kampfmeldung = ""
		return
	for c in _namen():
		if _genannt(c, m):
			_kampf[c] = _runde
	# Greift ein Monster gerade wirklich an? Rogue schreibt dann "the bat hit you" oder "the bat misses you".
	var text := m.replace("--more--", "").strip_edges()
	if text == _letzte_kampfmeldung:
		return
	_letzte_kampfmeldung = text
	for satz in text.split("."):
		if not satz.ends_with(" you") and not " you " in satz:
			continue
		if satz.strip_edges().begins_with("you "):
			continue
		for c in _namen():
			if _genannt(c, satz):
				_angriff_offen[c] = true


## Zustand bestimmen: ruhe (schläft / steht nur), lauf (wach, unterwegs), angriff (wach und neben dir).
## Mit Fühler kommen die echten Werte aus Rogue, sonst wird aus den Meldungen geschätzt
## (Angriff erst nach dem ersten Kampf mit dieser Art, Peters Wunsch).
func _zustand_pruefen(m: Dictionary, spieler: Vector2i) -> void:
	var nah := _abstand(m.p, spieler) == 1
	var werte: Dictionary = fuehler.monster.get(m.p, {})
	var wach: bool
	if fuehler.aktiv and werte:
		wach = (int(werte.flags) & fuehler.ISRUN) != 0
		m.lp = float(werte.hp) / float(werte.max)
	else:
		wach = _kampf.has(m.c) or m.get("bewegt", false)
	var zustand := "angriff" if (nah and wach) else ("lauf" if wach else "ruhe")
	var drei_d: bool = m.get("drei_d", false)
	if zustand != m.get("zustand", ""):
		m.zustand = zustand
		m.bildzeit = 0.0
		if not drei_d:
			_zustandsbild(m, zustand)
	if zustand == "angriff" and not drei_d:
		var richtung := Vector3(spieler.x - m.p.x, 0, spieler.y - m.p.y).normalized()
		var tw := create_tween()
		tw.tween_property(m.versatz, "position", richtung * 0.45, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(m.versatz, "position", Vector3.ZERO, 0.3).set_trans(Tween.TRANS_SINE)
	m.angriff = zustand == "angriff"
	_verletzung_zeigen(m)


## Roter Blitz, wenn ein Monster trifft.
func treffer_pruefen(meldung: String) -> void:
	_kampf_auswerten(meldung)
	var m := meldung.to_lower()
	if not (" hit you" in m or " hits you" in m or "injured you" in m or "hit on you" in m or " bit you" in m):
		return
	if _blitz == null:
		var ebene := CanvasLayer.new()
		ebene.layer = 5
		add_child(ebene)
		_blitz = ColorRect.new()
		_blitz.color = Color(0.7, 0.0, 0.0, 0.0)
		_blitz.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_blitz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ebene.add_child(_blitz)
	_blitz.color.a = 0.35
	create_tween().tween_property(_blitz, "color:a", 0.0, 0.4)


# ---------------------------------------------------------------- Bewegung in jedem Bild

func _process(delta: float) -> void:
	_zeit += delta
	for m in _verschwunden.duplicate():
		m.weg_zeit -= delta
		if m.weg_zeit <= 0.0:
			m.knoten.queue_free()
			_verschwunden.erase(m)
	for m in aktive:
		var t: float = _zeit + m.phase
		m.bildzeit = m.get("bildzeit", 0.0) + delta
		var zustand: String = m.get("zustand", "lauf")
		if m.get("drei_d", false):
			_modell_bewegen(m, t, zustand)
		else:
			_bild_bewegen(m, t, zustand)


## 3D-Modell: atmen, Flieger schweben auf und ab. Blick (Peter 22.11.): nur beim Angriff (wach und neben dir)
## dreht es sich zu dir; sonst schaut es in seine eigene Richtung bzw. dorthin, wohin es zuletzt lief.
func _modell_bewegen(m: Dictionary, t: float, zustand: String) -> void:
	if zustand == "angriff":
		m.knoten.rotation.y = lerp_angle(m.knoten.rotation.y, _blick_zum_spieler(m.knoten.position), 0.12)
	else:
		m.knoten.rotation.y = lerp_angle(m.knoten.rotation.y, m.get("eigene_blick", m.knoten.rotation.y), 0.08)
	var sy := 1.0 + sin(t * (1.2 if zustand == "ruhe" else 1.8)) * 0.012
	m.modell.scale = Vector3(m.modell.scale.x, m.modell.scale.x * sy, m.modell.scale.x)
	if not schwebt(m.c) and m.has("modell_y0"):
		# um die Füße atmen, nicht um den Ursprung der Datei (sonst sinken große Figuren wie der Minotaurus ein)
		m.modell.position.y = float(m.modell_y0) * sy
	if schwebt(m.c):
		m.versatz.position.y = sin(t * 4.0) * 0.12


## Standbild: Bildwechsel im Zustand, schweben, atmen, taumeln bei wenig Lebenspunkten.
func _bild_bewegen(m: Dictionary, t: float, zustand: String) -> void:
	if zustand == "angriff":
		# ausholen, zuschlagen, ausholen ... (Takt 1,1 s)
		var takt := fmod(m.bildzeit, 1.1)
		_zustandsbild(m, "angriff", takt > 0.5 and takt < 0.9)
	elif zustand == "ruhe":
		# ab und zu kurz zucken: alle ~4 s zweimal
		var takt := fmod(m.bildzeit + m.phase, 4.0)
		_zustandsbild(m, "ruhe", (takt > 3.0 and takt < 3.25) or (takt > 3.5 and takt < 3.75))
	if schwebt(m.c):
		m.versatz.position.y = sin(t * 4.0) * 0.12
		m.bild.rotation.z = sin(t * 2.3) * 0.06
		return
	m.bild.rotation.z = lerpf(m.bild.rotation.z, 0.0, 0.2)
	if zustand != "angriff":
		m.versatz.position.y = lerpf(m.versatz.position.y, 0.0, 0.2)
	var s := 1.0 + sin(t * (1.2 if zustand == "ruhe" else 1.8)) * 0.015
	m.bild.scale = Vector3(1.0 / sqrt(s), s, 1.0)
	if m.get("lp", 1.0) < 0.35:
		m.bild.rotation.z += sin(t * 1.3) * 0.05
