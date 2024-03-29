extends Command
class_name CommandMove

enum Direction {
	North, NorthEast, East, SouthEast,
	South, SouthWest, West, NorthWest
}

const Directions := {
	Direction.North: Vector2.UP,
	Direction.NorthEast: Vector2.UP + Vector2.RIGHT,
	Direction.East: Vector2.RIGHT,
	Direction.SouthEast: Vector2.DOWN + Vector2.RIGHT,
	Direction.South: Vector2.DOWN,
	Direction.SouthWest: Vector2.DOWN + Vector2.LEFT,
	Direction.West: Vector2.LEFT,
	Direction.NorthWest: Vector2.UP + Vector2.LEFT,
}

var delta: Vector2i
var _old: Vector2i
var _map: TileMap
var _mob: Mob
var _rect: Rect2

func _init(mob: Mob, map: TileMap, d: int) -> void:
	delta = Directions[d]
	_map = map
	_mob = mob
	_rect = _map.get_used_rect()

func execute() -> void:
	_old = _mob.global_position
	if _rect.has_point(_map.local_to_map(_old) + delta):
		_mob.global_position += _map.map_to_local(delta)
	else:
		Audio.error()
		valid = false

func undo() -> void:
	_mob.global_position = _old

func redo() -> void:
	execute()
