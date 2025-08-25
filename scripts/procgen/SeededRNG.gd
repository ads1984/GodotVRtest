extends RefCounted
class_name SeededRNG

const MOD: int = 2147483647
const MUL: int = 48271

var rng_state: int = 1

func _init(p_seed: int = 1) -> void:
	rng_state = 1 if p_seed == 0 else p_seed

func _next() -> int:
	var q: int = MOD / MUL
	var r: int = MOD % MUL
	var t: int = MUL * (rng_state % q) - r * int(rng_state / q)
	rng_state = t if t > 0 else t + MOD
	return rng_state

func randf() -> float:
	return float(_next()) / float(MOD)

func rand_int(limit: int = 0) -> int:
	var value: int = _next()
	return int(value % limit) if limit > 0 else value

func rangef(min_val: float, max_val: float) -> float:
	return min_val + randf() * (max_val - min_val)

func choice(list: Array) -> Variant:
	return null if list.is_empty() else list[rand_int(list.size())]
