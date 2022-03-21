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

var delta: Vector2
var _old: Vector2
var _map: TileMap
var _rect: Rect2

func _init(mob: Mob, map: TileMap, d: int).(mob) -> void:
	delta = Directions[d]
	_map = map
	_rect = _map.get_used_rect()

func execute() -> void:
	_old = _mob.global_position
	if _rect.has_point(_map.world_to_map(_old) + delta):
		_mob.global_position += _map.map_to_world(delta)
	else:
		print("beep")

func undo() -> void:
	_mob.global_position = _old

func redo() -> void:
	execute()
