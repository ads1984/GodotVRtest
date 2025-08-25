@tool
class_name GameStaging
extends PersistentStaging

func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return

	# Never gate desktop on "press trigger"
	prompt_for_continue = false

	# Events
	scene_loaded.connect(_on_scene_loaded)
	xr_started.connect(_on_xr_started)
	xr_ended.connect(_on_xr_ended)

func _on_scene_loaded(scene:Node, _user_data:Variant) -> void:
	prompt_for_continue = false
	get_tree().paused = false                  # <- ensure not paused
	if not _is_vr_active():
		_ensure_ui_actions()                   # ui_accept/ui_up/down etc.
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_viewport().gui_disable_input = false
		_ensure_desktop_view(scene)            # optional fallback camera/light


func _on_xr_started() -> void:
	get_tree().paused = false


func _on_xr_ended() -> void:
	get_tree().paused = true


# -------------------- helpers --------------------

func _is_vr_active() -> bool:
	var iface := XRServer.primary_interface
	if iface == null:
		return false
	if iface.has_method("is_running") and iface.is_running():
		return true
	if iface.has_method("is_session_running") and iface.is_session_running():
		return true
	return false

func _prepare_desktop_ui(root: Node) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_viewport().gui_disable_input = false

	# ensure Controls allow mouse to reach Buttons
	_normalize_mouse_filters(root)

	# keyboard focus so Enter/Space works
	var btn := _find_first_button(root)
	if btn:
		btn.focus_mode = Control.FOCUS_ALL
		btn.grab_focus()

func _normalize_mouse_filters(n: Node) -> void:
	if n is Control:
		var c := n as Control
		if c is Button:
			c.mouse_filter = Control.MOUSE_FILTER_STOP
			c.focus_mode = Control.FOCUS_ALL
		else:
			# big panels/containers should not block mouse
			c.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in n.get_children():
		_normalize_mouse_filters(child)



func _unblock_fullscreen_controls(root: Node) -> void:
	var vp_size := get_viewport().get_visible_rect().size
	_recurse_unblock(root, vp_size)


func _recurse_unblock(n: Node, vp_size: Vector2i) -> void:
	if n is Control and n.visible:
		var c := n as Control
		# Heuristic: full-screen-ish Controls that aren't Buttons shouldn't block mouse
		var big := c.size.x >= float(vp_size.x) * 0.98 and c.size.y >= float(vp_size.y) * 0.98
		if big and c.mouse_filter == Control.MOUSE_FILTER_STOP and not (c is Button):
			c.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in n.get_children():
		_recurse_unblock(child, vp_size)


func _find_first_button(n: Node) -> Button:
	if n is Button:
		return n
	for child in n.get_children():
		var b := _find_first_button(child)
		if b != null:
			return b
	return null


# ------- Input Map bootstrapping (moved helpers out of function) -------

func _ensure_ui_actions() -> void:
	# Create base actions if missing
	_ensure_action("ui_accept")
	_ensure_action("ui_cancel")
	_ensure_action("ui_left")
	_ensure_action("ui_right")
	_ensure_action("ui_up")
	_ensure_action("ui_down")

	# Keyboard
	_add_key("ui_accept", KEY_SPACE)
	_add_key("ui_accept", KEY_ENTER)
	_add_key("ui_accept", KEY_KP_ENTER)
	_add_key("ui_cancel", KEY_ESCAPE)
	_add_key("ui_left", KEY_LEFT)
	_add_key("ui_right", KEY_RIGHT)
	_add_key("ui_up", KEY_UP)
	_add_key("ui_down", KEY_DOWN)

	# WASD
	_add_key("ui_left", KEY_A)
	_add_key("ui_right", KEY_D)
	_add_key("ui_up", KEY_W)
	_add_key("ui_down", KEY_S)

	# Xbox-style pad
	_add_pad_btn("ui_accept", JOY_BUTTON_A)
	_add_pad_btn("ui_cancel", JOY_BUTTON_B)
	_add_pad_btn("ui_left", JOY_BUTTON_DPAD_LEFT)
	_add_pad_btn("ui_right", JOY_BUTTON_DPAD_RIGHT)
	_add_pad_btn("ui_up", JOY_BUTTON_DPAD_UP)
	_add_pad_btn("ui_down", JOY_BUTTON_DPAD_DOWN)


func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)


func _add_key(action: String, keycode: int) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)


func _add_pad_btn(action: String, btn: int) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = btn
	InputMap.action_add_event(action, ev)


# ------- Optional: fallback camera & light so desktop isn't grey -------

func _ensure_desktop_view(root: Node) -> void:
	if get_viewport().get_camera_3d() != null:
		return
	var cam := Camera3D.new()
	cam.current = true
	cam.position = Vector3(0, 6, 12)
	cam.look_at(Vector3.ZERO, Vector3.UP)
	root.add_child(cam)

	var has_light := false
	for n in root.get_children():
		if n is DirectionalLight3D or n is OmniLight3D or n is SpotLight3D:
			has_light = true
			break
	if not has_light:
		var sun := DirectionalLight3D.new()
		sun.shadow_enabled = false
		sun.rotate_x(deg_to_rad(-45))
		sun.rotate_y(deg_to_rad(35))
		root.add_child(sun)
