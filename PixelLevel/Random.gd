extends Node

var _rng := RandomNumberGenerator.new()

func _init() -> void:
	_rng.randomize()

func next(n: int) -> int:
	return 0 if n == 0 else _rng.randi() % n

func nextRange(from: int, to: int) -> int:
	return _rng.randi_range(from, to)

func nextRangeEven(from: int, to: int) -> int:
	return nextRange(int(from / 2.0), int(to / 2.0)) * 2

func nextRangeOdd(from: int, to: int) -> int:
	return nextRangeEven(from, to) + 1

func nextBool() -> bool:
	return bool(next(2))

func nextFloat() -> float:
	return _rng.randf()
