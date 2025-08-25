extends Node3D
class_name ProcLevel

signal generated(generated_seed: int)

@export var rng_seed: int = 123456
@export var room_count: int = 25
@export var grid_radius: int = 12
@export var room_size: Vector3 = Vector3(4.0, 3.0, 4.0)
@export var room_spacing: float = 6.0
@export var auto_light: bool = true
@onready var _camera: Camera3D = $Camera3D

var _rng: SeededRNG
var _rooms: Array[Vector2i] = []

func _ready() -> void:
		# Procedural generation
	_generate_internal(rng_seed)
	# Make sure our camera becomes the active camera
	_camera.current = true

func regenerate(new_seed: int = -1) -> void:
	_generate_internal(new_seed if new_seed >= 0 else rng_seed)

func clear_generated() -> void:
	for c in get_children():
		if c is MeshInstance3D:
			c.queue_free()

func _generate_internal(init_seed: int) -> void:
	clear_generated()

	var used_seed: int = init_seed if init_seed != 0 else 1
	_rng = SeededRNG.new(abs(used_seed))
	_rooms.clear()

	var occ: Dictionary = {}
	var current: Vector2i = Vector2i(0, 0)
	occ[current] = true
	_rooms.append(current)

	while _rooms.size() < room_count:
		var types: Array = RoomGrammar.all_types()
		if types.is_empty():
			break
		var arch: String = types[_rng.rand_int(types.size())]
		var dirs: Array = RoomGrammar.connections(arch)
		var placed := false

		if dirs.size() > 0:
			for _i in range(dirs.size()):
				var d: Vector2i = dirs[_rng.rand_int(dirs.size())]
				var next: Vector2i = current + d
				if not occ.has(next) and abs(next.x) <= grid_radius and abs(next.y) <= grid_radius:
					occ[next] = true
					_rooms.append(next)
					current = next
					placed = true
					break

		if not placed:
			current = _rooms[_rng.rand_int(_rooms.size())]

	for cell in _rooms:
		_spawn_room(cell)

	if auto_light:
		_add_test_light_if_missing()

	emit_signal("generated", used_seed)

func _spawn_room(grid: Vector2i) -> void:
	var room := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = room_size
	room.mesh = mesh
	room.transform.origin = Vector3(grid.x * room_spacing, room_size.y * 0.5, grid.y * room_spacing)
	add_child(room)

func _add_test_light_if_missing() -> void:
	for c in get_children():
		if c is DirectionalLight3D or c is OmniLight3D or c is SpotLight3D:
			return
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = false
	sun.rotate_x(deg_to_rad(-45))
	sun.rotate_y(deg_to_rad(35))
	add_child(sun)
