class_name WebTextInput
extends Node
## Phones and tablets in the browser: lays a real HTML <input> over every visible text field. Browsers
## (iOS Safari above all) only open the on-screen keyboard when an input is focused inside the tap itself,
## and the engine's own hidden input is focused a frame later, so the keyboard sometimes stayed shut.
## With the HTML input on top, the tap lands on it directly; its text is mirrored into the LineEdit,
## which keeps drawing the field as usual.

const JS := """
(function () {
	if (window.__ctbText) { return; }
	const inputs = {};
	const canvas = document.getElementById('canvas');
	const send = (id, kind, value) => { if (window.__ctbTextEvent) { window.__ctbTextEvent(id, kind, value); } };
	window.__ctbText = {
		ensure(id, secret) {
			let el = inputs[id];
			if (!el) {
				el = document.createElement('input');
				el.setAttribute('autocomplete', 'off');
				el.setAttribute('autocorrect', 'off');
				el.setAttribute('autocapitalize', 'off');
				el.spellcheck = false;
				// 16px stops iOS from zooming the page on focus; the input itself is invisible.
				Object.assign(el.style, { position: 'fixed', zIndex: 5, opacity: '0.011', background: 'transparent',
					border: 'none', outline: 'none', color: 'transparent', caretColor: 'transparent',
					fontSize: '16px', padding: '0', margin: '0', display: 'none' });
				el.addEventListener('input', () => send(id, 'input', el.value));
				el.addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); send(id, 'submit', el.value); } });
				el.addEventListener('focus', () => send(id, 'focus', el.value));
				el.addEventListener('blur', () => send(id, 'blur', el.value));
				document.body.appendChild(el);
				inputs[id] = el;
			}
			el.type = secret ? 'password' : 'text';
		},
		place(id, x, y, w, h) {
			const el = inputs[id];
			if (!el) { return; }
			const r = canvas.getBoundingClientRect();
			const sx = r.width / canvas.width;
			const sy = r.height / canvas.height;
			Object.assign(el.style, { display: 'block', left: (r.left + x * sx) + 'px', top: (r.top + y * sy) + 'px',
				width: (w * sx) + 'px', height: (h * sy) + 'px' });
		},
		hide(id) {
			const el = inputs[id];
			if (el) { if (document.activeElement === el) { el.blur(); } el.style.display = 'none'; }
		},
		value(id, text) { const el = inputs[id]; if (el && el.value !== text) { el.value = text; } },
		remove(id) { const el = inputs[id]; if (el) { el.remove(); delete inputs[id]; } },
	};
})();
"""
const SCAN_SECONDS := 0.25

var _fields: Dictionary = {}  # instance id -> LineEdit
var _placed: Dictionary = {}  # instance id -> last rect sent, or null when hidden
var _dom_text: Dictionary = {}
var _api: JavaScriptObject
var _callback: JavaScriptObject
var _scan := 0.0


func _ready() -> void:
	JavaScriptBridge.eval(JS, true)
	_api = JavaScriptBridge.get_interface("__ctbText")
	_callback = JavaScriptBridge.create_callback(_on_event)
	JavaScriptBridge.get_interface("window").__ctbTextEvent = _callback


func _process(delta: float) -> void:
	_scan -= delta
	if _scan <= 0.0:
		_scan = SCAN_SECONDS
		_collect()
	for id: int in _fields.keys():
		_sync(id)


func _collect() -> void:
	var seen := {}
	for node: Node in get_tree().root.find_children("*", "LineEdit", true, false):
		var field := node as LineEdit
		var id := field.get_instance_id()
		seen[id] = true
		if not _fields.has(id):
			_fields[id] = field
			_placed[id] = null
			_dom_text[id] = ""
			field.virtual_keyboard_enabled = false
			_api.ensure(id, field.secret)
	for id: int in _fields.keys():
		if not seen.has(id):
			_forget(id)


func _sync(id: int) -> void:
	var field: LineEdit = _fields[id]
	if not is_instance_valid(field):
		_forget(id)
		return
	if not (field.is_visible_in_tree() and field.editable):
		if _placed[id] != null:
			_api.hide(id)
			_placed[id] = null
		return
	var xform := field.get_viewport().get_final_transform() * field.get_global_transform_with_canvas()
	var rect := Rect2(xform.origin, field.size * xform.get_scale()).abs()
	if _placed[id] == null or not (_placed[id] as Rect2).is_equal_approx(rect):
		_api.place(id, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
		_placed[id] = rect
	if field.text != _dom_text[id]:
		_dom_text[id] = field.text
		_api.value(id, field.text)


func _forget(id: int) -> void:
	_api.remove(id)
	_fields.erase(id)
	_placed.erase(id)
	_dom_text.erase(id)


func _on_event(args: Array) -> void:
	var id := int(args[0])
	var field: LineEdit = _fields.get(id)
	if field == null or not is_instance_valid(field):
		return
	var text := str(args[2])
	match str(args[1]):
		"input":
			if field.max_length > 0:
				text = text.left(field.max_length)
			_dom_text[id] = text
			if field.text != text:
				field.text = text
				field.caret_column = text.length()
				field.text_changed.emit(text)
		"submit":
			field.text_submitted.emit(field.text)
		"focus":
			if field.is_visible_in_tree():
				field.grab_focus()
				field.caret_column = field.text.length()
		"blur":
			if field.has_focus():
				field.release_focus()
