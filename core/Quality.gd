class_name Quality
extends RefCounted
## Graphics level: "auto", "low" or "high", kept in Settings. "auto" means High in the desktop app and
## in desktop browsers, Low on phones and tablets. If the game runs slowly for a while it steps itself
## down to Low (see Main.gd), and tells the player once.

static var auto_lowered := false
static var _handheld: Variant = null


static func is_low() -> bool:
	if auto_lowered:
		return true
	match Settings.quality:
		"low": return true
		"high": return false
	return is_handheld()


## Phones and tablets: native mobile, or a browser on Android/iOS or with only a coarse pointer.
static func is_handheld() -> bool:
	if _handheld == null:
		_handheld = _detect_handheld()
	return bool(_handheld)


static func _detect_handheld() -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--device="):
			return arg.begins_with("--device=phone") or arg.begins_with("--device=tablet")
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
	if OS.has_feature("web"):
		var coarse: Variant = JavaScriptBridge.eval("(window.matchMedia && matchMedia('(pointer: coarse)').matches && !matchMedia('(pointer: fine)').matches) ? 1 : 0", true)
		return (coarse is int or coarse is float) and int(coarse) == 1
	return false


## Applies what depends on the level to the window: lighter rendering on phones. Device pixel ratios of
## 3 are wasted on a game this chunky, and fill rate is what phones run out of first.
static func apply(tree: SceneTree) -> void:
	var low := is_low()
	var root := tree.root
	root.msaa_3d = Viewport.MSAA_2X if low else Viewport.MSAA_4X
	var ratio := minf(1.0, 1.8 / maxf(UiScale.density(), 1.0)) if low else minf(1.0, 2.4 / maxf(UiScale.density(), 1.0))
	root.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	root.scaling_3d_scale = clampf(ratio, 0.5, 1.0)
