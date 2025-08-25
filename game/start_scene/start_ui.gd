extends CenterContainer

@onready var save_list_node: ItemList = $LoadGame/SaveList
var save_list: Array[String] = []

func _ready() -> void:
	# Root UI must capture mouse so clicks don't leak to 3D / overlays
	mouse_filter = Control.MOUSE_FILTER_STOP

	_set_pane(1)

	# Populate saves
	if PersistentWorld.instance:
		save_list = PersistentWorld.instance.list_saves()
		save_list_node.clear()
		for entry in save_list:
			save_list_node.add_item(str(entry))

	$MainMenu/LoadGameBtn.disabled = save_list.size() == 0


# ---------- Pane switching + autofocus ----------
func _set_pane(p_no: int) -> void:
	$MainMenu.visible = p_no == 1
	$NewGame.visible = p_no == 2
	$LoadGame.visible = p_no == 3
	$Options.visible = p_no == 4

	await get_tree().process_frame
	_focus_first_visible_button()

func _focus_first_visible_button() -> void:
	var b := _find_first_visible_button(self)
	if b:
		b.focus_mode = Control.FOCUS_ALL
		b.grab_focus()

func _find_first_visible_button(n: Node) -> Button:
	if n is Button and n.visible:
		return n
	for child in n.get_children():
		var r := _find_first_visible_button(child)
		if r != null:
			return r
	return null


# ---------- Desktop fallback: click hovered button ----------
func _unhandled_input(event: InputEvent) -> void:
	# Skip if XR session is running (VR will use rays)
	var xr_running: bool = false
	var iface = XRServer.primary_interface
	if iface != null:
		if iface.has_method("is_running") and iface.is_running():
			xr_running = true
		elif iface.has_method("is_session_running") and iface.is_session_running():
			xr_running = true
	if xr_running:
		return

	# Left click -> press the hovered Button
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hovered: Control = get_viewport().gui_get_hovered_control()
		if hovered and hovered is Button and hovered.visible:
			(hovered as Button).emit_signal("pressed")
			get_viewport().set_input_as_handled()


# ---------- Main menu ----------
func _on_new_game_btn_pressed() -> void:
	_set_pane(2)

func _on_load_game_btn_pressed() -> void:
	_set_pane(3)

func _on_options_btn_pressed() -> void:
	_set_pane(4)

func _on_exit_btn_pressed() -> void:
	get_tree().quit()


# ---------- New game ----------
func _on_easy_btn_pressed() -> void:
	GameState.new_game(GameState.GameDifficulty.GAME_EASY)

func _on_normal_btn_pressed() -> void:
	GameState.new_game(GameState.GameDifficulty.GAME_NORMAL)

func _on_hard_btn_pressed() -> void:
	GameState.new_game(GameState.GameDifficulty.GAME_HARD)

func _on_back_btn_pressed() -> void:
	_set_pane(1)


# ---------- Load game ----------
func _on_start_button_pressed() -> void:
	var selected_items: PackedInt32Array = save_list_node.get_selected_items()
	if selected_items.size() == 1:
		var selected_index: int = selected_items[0]
		var save_name: String = save_list[selected_index]
		GameState.load_game(save_name)
