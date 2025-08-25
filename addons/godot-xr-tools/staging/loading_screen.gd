@tool
extends Node3D

## XR Tools Loading Screen

signal continue_pressed

@export var follow_camera: bool = true: set = set_follow_camera
@export var follow_speed: Curve
@export var splash_screen: Texture2D: set = set_splash_screen
@export_range(0.0, 1.0, 0.01) var progress: float = 0.5: set = set_progress_bar
@export var enable_press_to_continue: bool = false: set = set_enable_press_to_continue

# Camera to track
var _camera: XRCamera3D
# Materials
var _splash_screen_material: StandardMaterial3D
var _progress_material: ShaderMaterial

# Desktop fallback actions (Space/Enter/Mouse via Input Map)
const DESKTOP_ACCEPT_ACTIONS: PackedStringArray = ["trigger_click_mouse", "ui_accept"]

func _ready() -> void:
	# Materials
	_splash_screen_material = $SplashScreen.get_surface_override_material(0)
	_progress_material = $ProgressBar.mesh.surface_get_material(0)

	# Ensure HoldButton is configured and connected
	_configure_hold_button()

	# Initial UI state
	_update_splash_screen()
	_update_progress_bar()
	_update_enable_press_to_continue()
	_update_follow_camera()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _camera == null:
		return

	# Rotate towards camera (horizontal)
	var camera_dir := _camera.global_transform.basis.z
	camera_dir.y = 0.0
	camera_dir = camera_dir.normalized()

	var loading_screen_dir := global_transform.basis.z
	var angle := loading_screen_dir.signed_angle_to(camera_dir, Vector3.UP)
	if angle == 0.0:
		return

	global_transform.basis = global_transform.basis.rotated(
		Vector3.UP * sign(angle),
		follow_speed.sample_baked(abs(angle) / PI) * delta
	).orthonormalized()


# ------------------------------------------------------------
# Desktop fallback: allow Space / Mouse to pass the gate, too.
# ------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	# Only when the splash is asking to continue
	if not enable_press_to_continue:
		return
	# If VR isn't active (desktop), allow keyboard/mouse to continue
	if not _is_vr_active():
		for a in DESKTOP_ACCEPT_ACTIONS:
			if event.is_action_pressed(a):
				_on_HoldButton_pressed()
				get_viewport().set_input_as_handled()
				break


# ---------- Public setters ----------
func set_camera(p_camera: XRCamera3D) -> void:
	_camera = p_camera
	_update_follow_camera()

func set_follow_camera(p_enabled: bool) -> void:
	follow_camera = p_enabled
	_update_follow_camera()

func set_splash_screen(p_splash_screen: Texture2D) -> void:
	splash_screen = p_splash_screen
	_update_splash_screen()

func set_progress_bar(p_progress: float) -> void:
	progress = p_progress
	_update_progress_bar()

func set_enable_press_to_continue(p_enable: bool) -> void:
	enable_press_to_continue = p_enable
	_update_enable_press_to_continue()


# ---------------- Internal helpers ----------------
func _configure_hold_button() -> void:
	var hold := $PressToContinue/HoldButton
	if hold == null:
		push_warning("LoadingScreen: HoldButton node not found at PressToContinue/HoldButton.")
		return

	# Force it to listen to our action
	var prop_names: PackedStringArray = []
	for p in hold.get_property_list():
		if typeof(p) == TYPE_DICTIONARY and p.has("name"):
			prop_names.append(p["name"])

	for prop in ["action", "input_action", "action_name"]:
		if prop_names.has(prop):
			hold.set(prop, "trigger_click_mouse")
			break

	# Optional: shorten hold time if supported
	if prop_names.has("hold_time"):
		hold.set("hold_time", 0.15)

	# Ensure signal is connected
	if not hold.is_connected("pressed", Callable(self, "_on_HoldButton_pressed")):
		hold.pressed.connect(_on_HoldButton_pressed)


func _update_follow_camera() -> void:
	if _camera != null and not Engine.is_editor_hint():
		set_process(follow_camera)

func _update_splash_screen() -> void:
	if _splash_screen_material:
		_splash_screen_material.albedo_texture = splash_screen

func _update_progress_bar() -> void:
	if _progress_material:
		_progress_material.set_shader_parameter("progress", progress)

func _update_enable_press_to_continue() -> void:
	if not is_inside_tree():
		return
	$ProgressBar.visible = not enable_press_to_continue
	$PressToContinue.visible = enable_press_to_continue
	$PressToContinue/HoldButton.enabled = enable_press_to_continue


func _on_HoldButton_pressed() -> void:
	emit_signal("continue_pressed")


# XR active check that works across plugin versions
func _is_vr_active() -> bool:
	var iface := XRServer.primary_interface
	if iface == null:
		return false
	# OpenXRInterface usually has is_running(); older builds may have is_session_running()
	if iface.has_method("is_running") and iface.is_running():
		return true
	if iface.has_method("is_session_running") and iface.is_session_running():
		return true
	# As a last resort, consider initialized as "active enough"
	if iface.has_method("is_initialized") and iface.is_initialized():
		# Not strictly "running", but prevents false negatives on some builds
		return true
	return false
