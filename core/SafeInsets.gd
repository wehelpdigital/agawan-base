class_name SafeInsets
extends RefCounted
## Keeps the interface clear of notches, camera holes and rounded corners. On Android and iOS the game
## runs full screen, so a button could sit under a cutout. Returns left, top, right, bottom in UI pixels.
## Tests can fake a cutout with --safe-inset=L,T,R,B (window pixels).

const ROUND_CORNER_DP := 8.0
const ROUND_CORNER_ASPECT := 1.9


static func get_insets(tree: SceneTree) -> Vector4:
	var window := tree.root
	var size := Vector2(window.size)
	var px := Vector4.ZERO
	var faked := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--safe-inset="):
			var parts := arg.trim_prefix("--safe-inset=").split(",")
			if parts.size() == 4:
				px = Vector4(float(parts[0]), float(parts[1]), float(parts[2]), float(parts[3]))
				faked = true
	if not faked and OS.has_feature("mobile") and not OS.has_feature("web"):
		var safe := DisplayServer.get_display_safe_area()
		if safe.size.x > 0 and safe.size.y > 0:
			px = Vector4(safe.position.x, safe.position.y, size.x - safe.end.x, size.y - safe.end.y)
		if size.x > size.y and size.x / maxf(size.y, 1.0) >= ROUND_CORNER_ASPECT:
			var corner := ROUND_CORNER_DP * UiScale.density()
			px.x = maxf(px.x, corner)
			px.z = maxf(px.z, corner)
	var view := window.get_visible_rect().size
	var k := view / Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0))
	return Vector4(ceilf(clampf(px.x, 0.0, size.x * 0.25) * k.x), ceilf(clampf(px.y, 0.0, size.y * 0.25) * k.y),
		ceilf(clampf(px.z, 0.0, size.x * 0.25) * k.x), ceilf(clampf(px.w, 0.0, size.y * 0.25) * k.y))
