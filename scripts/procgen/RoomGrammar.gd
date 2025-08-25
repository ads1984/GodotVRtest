extends Node
class_name RoomGrammar
# You can autoload this or just rely on the static calls.

static func all_types() -> Array[String]:
	return ["cross", "line", "corner", "tee"]

static func connections(arch: String) -> Array:
	match arch:
		"cross":
			return [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
		"line":
			return [Vector2i(1,0), Vector2i(-1,0)]
		"corner":
			return [Vector2i(1,0), Vector2i(0,1)]
		"tee":
			return [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1)]
		_:
			return [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
