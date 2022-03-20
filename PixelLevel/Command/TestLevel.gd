extends TestLevelBase
class_name TestLevel

# TODO: make 3 mobs selectable
# add undo and redo buttons
# step 1: create new version of level with scoll and zoom working etc
# put in base class?
# working with commands and undo

onready var _path: Node2D = $Path
onready var _mob: Sprite = $Mob
onready var _target: Node2D = $Target
var _startAt := Vector2(4, 4)
var _turn := false
var _time := 0.0
const _turnTime := 0.22

var _commands: Array
var _commandIndex: int

func _ready() -> void:
	_mob.global_position = _world(_startAt) + _back.cell_size / 2.0
	_target.modulate = Color.transparent

func _unhandled_input(event: InputEvent) -> void:
	# if (isPressed(BUTTON_X)) return buttonX_;
	# if (isPressed(BUTTON_Y)) return buttonY_;
	# if (isPressed(BUTTON_A)) return buttonA_;
	# if (isPressed(BUTTON_B)) return buttonB_;
	# print(event)
	pass

func _process(delta: float) -> void:
	_time += delta
	if (_time > _turnTime) and _turn:
		_turn = false
		var command = _processWasd()
		if command:
			command.execute()
		# if test:
		# 	if not _handleDoor():
		# 		yield(_move(_mob), "completed")
		# 	if not _handleStair():
		# 		_lightUpdate(mobPosition(), lightRadius)
		# 		_checkCenter()
		_time = 0.0

func _processWasd() -> CommandMove:
	if Input.is_action_pressed("ui_up"):
		return CommandMove.new(_mob, CommandMove.Direction.North)
	if Input.is_action_pressed("ui_ne"):
		return CommandMove.new(_mob, CommandMove.Direction.NorthEast)
	if Input.is_action_pressed("ui_right"):
		return CommandMove.new(_mob, CommandMove.Direction.East)
	if Input.is_action_pressed("ui_se"):
		return CommandMove.new(_mob, CommandMove.Direction.SouthEast)
	if Input.is_action_pressed("ui_down"):
		return CommandMove.new(_mob, CommandMove.Direction.South)
	if Input.is_action_pressed("ui_sw"):
		return CommandMove.new(_mob, CommandMove.Direction.SouthWest)
	if Input.is_action_pressed("ui_left"):
		return CommandMove.new(_mob, CommandMove.Direction.West)
	if Input.is_action_pressed("ui_nw"):
		return CommandMove.new(_mob, CommandMove.Direction.NorthWest)
	return null

# func _wasd(direction: Vector2) -> void:
# 	var p := mobPosition() + direction
# 	if isDoorShutV(p):
# 		_toggleDoorV(p)
# 	if not isBlockedV(p):
# 		_face(_mob, direction)
# 		yield(_step(_mob, direction), "completed")
# 		_pathClear()
# 		if not isStairV(p):
# 			_lightUpdate(p, lightRadius)
# 			_checkCenter()
# 		else:
# 			if isStairDownV(p):
# 				emit_signal("generate")
# 			elif isStairUpV(p):
# 				emit_signal("generateUp")
