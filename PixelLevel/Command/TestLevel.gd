extends TestLevelBase
class_name TestLevel

@onready var _undoButton: Button = $Panel/VBox/Buttons/Undo
@onready var _redoButton: Button = $Panel/VBox/Buttons/Redo
@onready var _list: ItemList = $Panel/VBox/Scroll/ItemList
@onready var _path: Node2D = $Level/SubViewport/Path
@onready var _mob: Sprite2D = $Level/SubViewport/Mob
@onready var _mobs: Node2D = $Level/SubViewport/Mobs
@onready var _target: Node2D = $Level/SubViewport/Target
var _startAt := Vector2(4, 4)
var _time := 0.0
const _turnTime := 0.22

var _commands := CommandQueue.new()

func _ready() -> void:
	Utility.stfu(_undoButton.connect("pressed", Callable(self, "_undoPressed")))
	Utility.stfu(_redoButton.connect("pressed", Callable(self, "_redoPressed")))
	Utility.stfu(_commands.connect("changed", Callable(self, "_commandsChanged")))
	_mob.global_position = _world(_startAt) + _back.cell_size / 2.0
	_target.modulate = Color.TRANSPARENT
	_addMobs()
	_cameraToMob()

func _cameraToMob() -> void:
	_cameraTo(-(_worldSize() / 2.0) + _mob.global_position)

func _process(_delta: float) -> void:
	_commands.execute(_processWasd())
	# _time += delta
	# if _time > _turnTime and (_turn or _processWasd()):
	# 	_timeTotal += _time
	# 	_turnTotal += 1
	# 	var test = _turn
	# 	_turn = false
	# 	if test:
	# 		if not _handleDoor():
	# 			yield(_move(_mob), "completed")
	# 		if not _handleStair():
	# 			_lightUpdate(mobPosition(), lightRadius)
	# 			_checkCenter()
	# 	_time = 0.0

func _undoPressed() -> void:
	_commands.undo()

func _redoPressed() -> void:
	_commands.redo()

func _commandsChanged() -> void:
	_list.clear()
	for i in _commands:
		_list.add_item(str(i.delta))
	if _commands.index != -1:
		_list.select(_commands.index)
		_list.ensure_current_is_visible()

func _processWasd() -> Command:
	if Input.is_action_just_pressed("ui_up"):
		return CommandMove.new(_mob, _back, CommandMove.Direction.North)
	if Input.is_action_just_pressed("ui_ne"):
		return CommandMove.new(_mob, _back, CommandMove.Direction.NorthEast)
	if Input.is_action_just_pressed("ui_right"):
		return CommandMove.new(_mob, _back, CommandMove.Direction.East)
	if Input.is_action_just_pressed("ui_se"):
		return CommandMove.new(_mob, _back, CommandMove.Direction.SouthEast)
	if Input.is_action_just_pressed("ui_down"):
		return CommandMove.new(_mob, _back, CommandMove.Direction.South)
	if Input.is_action_just_pressed("ui_sw"):
		return CommandMove.new(_mob, _back, CommandMove.Direction.SouthWest)
	if Input.is_action_just_pressed("ui_left"):
		return CommandMove.new(_mob, _back, CommandMove.Direction.West)
	if Input.is_action_just_pressed("ui_nw"):
		return CommandMove.new(_mob, _back, CommandMove.Direction.NorthWest)
	return null

const _mobCount := 3

func _addMobs() -> void:
	var list := Utility.listFiles("res://PixelMob/Mob")
	if list.size():
		for i in _mobCount:
			var r = Random.next(list.size() - 1) + 1
			var mob : Node2D = load(list[r]).instantiate()
			var x := Random.next(int(_back.get_used_rect().size.x))
			var y := Random.next(int(_back.get_used_rect().size.y))
			mob.position = _back.map_to_local(Vector2(x, y)) + _back.cell_size / 2
			_mobs.add_child(mob)

