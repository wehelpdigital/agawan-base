class_name UiScale
extends RefCounted
## Keeps menus, text and buttons a comfortable size on every screen. The project stretches a 1280x720
## canvas to fit the window, so on a phone everything would be drawn at a third of its size. UiScale
## sets the root window's content_scale_factor (2D only; 3D keeps full resolution), so one UI pixel is
## about one CSS pixel on phones, a little more on tablets, and desktops stay as designed. The player's
## Text Size setting multiplies the result.
##
## Tests can pretend to be a device: --device=phone_portrait, phone_landscape, tablet_portrait,
## tablet_landscape or desktop, with a matching --resolution.

const BASE := Vector2(1280, 720)
const PHONE_PORTRAIT := 0.92
const PHONE_LANDSCAPE := 0.82
const TABLET := 1.05
const DESKTOP_MIN := 0.78
const MAX_FACTOR := 3.6
const TEXT_SIZES := {"small": 0.88, "normal": 1.0, "large": 1.15}

static var kind := "desktop"
static var factor := 1.0
static var _test_device := ""


## Recomputes the scale for the current window. Safe to call on every resize.
static func apply(tree: SceneTree) -> void:
	var window := tree.root
	var css := css_viewport(window)
	kind = _kind_for(css)
	var fit := minf(css.x / BASE.x, css.y / BASE.y)
	var target := fit
	match kind:
		"phone":
			target = PHONE_LANDSCAPE if css.x > css.y else PHONE_PORTRAIT
		"tablet":
			target = TABLET
		_:
			target = maxf(fit, DESKTOP_MIN)
	var next := clampf(target / maxf(fit, 0.01), 1.0, MAX_FACTOR) * float(TEXT_SIZES.get(Settings.text_size, 1.0))
	if DisplayServer.get_name() == "headless" and not TEST_SIZES.has(_test_device):
		next = 1.0
	if is_equal_approx(next, window.content_scale_factor):
		return
	factor = next
	window.content_scale_factor = next


const TEST_SIZES := {"phone_portrait": true, "phone_landscape": true, "tablet_portrait": true, "tablet_landscape": true, "desktop": true}


## The window size in CSS pixels (on native builds, device-independent pixels).
static func css_viewport(window: Window) -> Vector2:
	if _test_device == "":
		_test_device = "-"
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--device="):
				_test_device = arg.trim_prefix("--device=")
	if TEST_SIZES.has(_test_device):
		return Vector2(window.size)
	if OS.has_feature("web"):
		var w: Variant = JavaScriptBridge.eval("window.innerWidth", true)
		var h: Variant = JavaScriptBridge.eval("window.innerHeight", true)
		if (w is int or w is float) and (h is int or h is float) and float(w) > 0.0:
			return Vector2(float(w), float(h))
	return Vector2(window.size) / (density() if OS.has_feature("mobile") else 1.0)


## Device pixels per CSS pixel. Android's screen_get_scale() is capped, so its dpi is used instead.
static func density() -> float:
	if OS.has_feature("web"):
		var ratio: Variant = JavaScriptBridge.eval("window.devicePixelRatio || 1", true)
		return float(ratio) if (ratio is float or ratio is int) and float(ratio) > 0.0 else 1.0
	if OS.get_name() == "Android":
		return clampf(DisplayServer.screen_get_dpi() / 160.0, 0.75, 6.0)
	return maxf(DisplayServer.screen_get_scale(), 1.0)


static func is_phone() -> bool:
	return kind == "phone"


static func _kind_for(css: Vector2) -> String:
	if not Quality.is_handheld():
		return "desktop"
	return "phone" if minf(css.x, css.y) < 600.0 else "tablet"
