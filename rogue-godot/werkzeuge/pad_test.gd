## Entwickler-Werkzeug: zeigt angeschlossene Controller und welche Achsen/Knöpfe gerade "gedrückt" melden.
## Aufruf: Godot --path rogue-godot --script res://werkzeuge/pad_test.gd
extends SceneTree


func _initialize() -> void:
	_laufen.call_deferred()


func _laufen() -> void:
	for i in 30:
		await process_frame
	await create_timer(1.0).timeout
	for p in Input.get_connected_joypads():
		var achsen := []
		for a in JOY_AXIS_MAX:
			achsen.append(snappedf(Input.get_joy_axis(p, a), 0.01))
		var knoepfe := []
		for b in JOY_BUTTON_MAX:
			if Input.is_joy_button_pressed(p, b):
				knoepfe.append(b)
		print("PAD ", p, " name=", Input.get_joy_name(p), " guid=", Input.get_joy_guid(p), " achsen=", achsen, " gedrueckt=", knoepfe)
	print("PADS gesamt: ", Input.get_connected_joypads().size())
	quit()
