extends TestLevelBase
class_name TestLevel

onready var _undoButton: Button = $Fore/Viewport/Panel/VBox/Buttons/Undo
onready var _selectButton: Button = $Fore/Viewport/Panel/VBox/Buttons/Select
onready var _redoButton: Button = $Fore/Viewport/Panel/VBox/Buttons/Redo
onready var _list: ItemList = $Fore/Viewport/Panel/VBox/ItemList
onready var _level: TestLevel = $Level/Viewport
onready var _path: Node2D = $Path
onready var _mob: Sprite = $Mob
onready var _target: Node2D = $Target
var _startAt := Vector2(4, 4)
var _time := 0.0
const _turnTime := 0.22

var _commands: CommandQueue = CommandQueue.new()

func _ready() -> void:
	Utility.srfu(_commands.connect("changed", self, "_commandsChanged"))
	_mob.global_position = _world(_startAt) + _back.cell_size / 2.0
	_target.modulate = Color.transparent

func _process(_delta: float) -> void:
	_commands.execute(_processWasd())

func _undo() -> void:
	_commands.undo()

func _redo() -> void:
	_commands.redo()

func _commandsChanged() -> void:
	pass

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
