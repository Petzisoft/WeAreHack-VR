## Test für das Startmenü: klickt per Tastatur und Gamepad durch (Hack muss übersprungen werden), startet NetHack
## und prüft, dass dungeon.tscn mit NetHack und dessen Vorspann läuft. Fotos: startmenue_test_*.png im Projektordner.
## Aufruf: Godot --path rogue-godot res://start.tscn -- --menuetest
extends RefCounted

const Spiel = preload("res://spiel.gd")
const Sprache = preload("res://sprache.gd")


static func laufen(m) -> void:
	var baum: SceneTree = m.get_tree()
	await baum.create_timer(1.0).timeout
	await _foto(baum, 1)
	print("MENUETEST start index=", m.index, " hack_aus=", m.knoepfe[1].disabled)
	_taste(KEY_DOWN)
	print("MENUETEST runter (Hack übersprungen) index=", m.index, " ok=", m.index == 2)
	_taste(KEY_UP)
	print("MENUETEST hoch index=", m.index, " ok=", m.index == 0)
	_taste(KEY_UP)
	print("MENUETEST hoch rundum (Beenden) index=", m.index, " ok=", m.index == 4)
	# Sprache umschalten (Eintrag 3), Text prüfen, Foto, wieder zurück
	var vorher: bool = Sprache.englisch()
	_taste(KEY_UP)
	print("MENUETEST Sprache-Eintrag index=", m.index, " ok=", m.index == 3)
	_taste(KEY_ENTER)
	await baum.process_frame
	print("MENUETEST umgeschaltet englisch=", Sprache.englisch(), " text=", m.knoepfe[3].text, " titel=", Sprache.t("Welches Spiel?"),
			" ok=", Sprache.englisch() != vorher)
	await _foto(baum, 4)
	_taste(KEY_ENTER)
	await baum.process_frame
	print("MENUETEST zurück englisch=", Sprache.englisch(), " ok=", Sprache.englisch() == vorher)
	_pad(JOY_BUTTON_DPAD_UP)
	await baum.process_frame
	print("MENUETEST Gamepad hoch index=", m.index, " ok=", m.index == 2)
	await _foto(baum, 2)
	_pad(JOY_BUTTON_A)
	await baum.create_timer(1.5).timeout
	var s := baum.current_scene
	print("MENUETEST szene=", s.name if s else "?", " spiel=", Spiel.welches(),
			" ok=", s != null and s.name == "Dungeon3D" and Spiel.welches() == "nethack")
	await baum.create_timer(2.5).timeout
	var v = load("res://vorspann.gd").aktiv(baum.current_scene)
	if v:
		print("MENUETEST vorspann_text=", v.get_child(0).get_child(1).text, " -> ", v.get_child(0).get_child(1).atr(v.get_child(0).get_child(1).text))
	print("MENUETEST vorspann=", v != null)
	await _foto(baum, 3)
	baum.quit()


static func _taste(k: int) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)
	Input.flush_buffered_events()


static func _pad(b: int) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)


static func _foto(baum: SceneTree, n: int) -> void:
	await RenderingServer.frame_post_draw
	var pfad := ProjectSettings.globalize_path("res://").path_join("../startmenue_test_%d.png" % n).simplify_path()
	baum.root.get_viewport().get_texture().get_image().save_png(pfad)
