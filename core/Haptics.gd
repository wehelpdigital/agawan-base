class_name Haptics
extends RefCounted
## A short buzz at the big moments, on phones and on game controllers. Settings can turn it off.

const PULSES := {  ## kind -> [milliseconds, strength 0..1]
	"tag": [40, 0.5],
	"jailed": [180, 0.9],
	"power": [20, 0.3],
	"capture": [220, 1.0],
	"win": [120, 0.7],
}

static var last := ""  ## The last buzz asked for: what tests check, as a desktop has nothing to buzz.


static func buzz(kind: String) -> void:
	if not PULSES.has(kind) or not Settings.vibration:
		return
	last = kind
	var pulse: Array = PULSES[kind]
	var pads := Input.get_connected_joypads()
	if not pads.is_empty():
		Input.start_joy_vibration(pads[0], float(pulse[1]) * 0.6, float(pulse[1]), float(pulse[0]) / 1000.0)
	elif OS.has_feature("mobile") or OS.has_feature("web"):
		Input.vibrate_handheld(int(pulse[0]), float(pulse[1]))
