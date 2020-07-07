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

func priority(d: Dictionary) -> Object:
	var o
	var total := 0
	for value in d.values():
		total += value.priority if "priority" in value else value
	var selected := next(total)
	var current := 0
	for key in d.keys():
		var value = d[key]
		o = value if "priority" in value else key
		current += value.priority if "priority" in value else value
		if current > selected:
			break
	return o
