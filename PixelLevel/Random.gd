extends Node

var _rng := RandomNumberGenerator.new()

func _init() -> void:
	_rng.randomize()

func next(n: int) -> int:
	return _rng.randi() % n

func nextBool() -> bool:
	return bool(_rng.randi() % 2)

func nextFloat() -> float:
	return _rng.randf()
