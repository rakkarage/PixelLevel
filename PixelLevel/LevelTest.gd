extends Control

@onready var _camera := $Container/SubViewport/Camera
@onready var _tileMap := $Container/SubViewport/TileMap
@onready var _generateButton := $Generate

var _dragLeft := false
var _capture := false

var _tweenStep : Tween

enum Layer {
	Back,
	Fore,
	Flower,
	WaterBack, SplitBack, ItemBack,
	Tree,
	ItemFore, SplitFore, WaterFore,
	Top,
	Light,
	Edge
}

enum Tile {
	Cliff1, Cliff2,	Banner1, Banner2, Doodad, Rug, Fountain, Loot,
	EdgeInside, EdgeInsideCorner, EdgeOutsideCorner, EdgeOutside,
	Light, LightDebug,
	DayGrass, DayPillar, DayPath, DayStair, DayDesert, DayDoodad,
	DayWeed, DayHedge, DayWall, DayFloor,
	NightGrass, NightPillar, NightPath, NightStair, NightDesert, NightDoodad,
	NightWeed, NightHedge, NightWall, NightFloor,
	Tree, TreeStump, Flower, Rubble,
	Theme1Torch, Theme1Wall, Theme1Floor, Theme1Stair, Theme1Door,
	Theme2Torch, Theme2Wall, Theme2Floor, Theme2Stair, Theme2Door,
	Theme3Torch, Theme3Wall, Theme3Floor, Theme3Stair, Theme3Door,
	Theme4Torch, Theme4Wall, Theme4Floor, Theme4Stair, Theme4Door,
	WaterShallow, WaterDeep, WaterShallowPurple, WaterDeepPurple,
}

const _floorTiles := [
	Tile.Theme1Floor, Tile.Theme2Floor, Tile.Theme3Floor, Tile.Theme4Floor,
	Tile.DayGrass, Tile.NightGrass, Tile.DayPath, Tile.NightPath,
	Tile.DayDesert, Tile.NightDesert, Tile.DayFloor, Tile.NightFloor, Tile.Rubble
]

const _wallTiles := [
	Tile.Theme1Torch, Tile.Theme1Wall, Tile.Theme2Torch, Tile.Theme2Wall,
	Tile.Theme3Torch, Tile.Theme3Wall, Tile.Theme4Torch, Tile.Theme4Wall,
	Tile.DayWall, Tile.NightWall, Tile.DayHedge, Tile.NightHedge
]

const _cliffTiles := [Tile.Cliff1, Tile.Cliff2]

const _stairTiles := [Tile.Theme1Stair, Tile.Theme2Stair, Tile.Theme3Stair, Tile.Theme4Stair, Tile.DayStair, Tile.NightStair]

const _doorTiles := [Tile.Theme1Door, Tile.Theme2Door, Tile.Theme3Door, Tile.Theme4Door]

const _waterTiles := [Tile.WaterShallow, Tile.WaterDeep, Tile.WaterShallowPurple, Tile.WaterDeepPurple]

const _waterDeepTiles := [Tile.WaterDeep, Tile.WaterDeepPurple]

const _waterPurpleTiles := [Tile.WaterShallowPurple, Tile.WaterDeepPurple]

func _ready() -> void:
	_generateButton.connect("pressed", _generate)

func _generate() -> void:
	print("Generating map...")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragLeft = true
				_capture = false
			else:
				if _capture:
					_cameraUpdate()
				elif _tweenStep:
					_targetTo(event.global_position, not _tweenStep.is_running())
					_targetUpdate()
				_dragLeft = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoomIn(event.global_position)
			_cameraUpdate()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoomOut(event.global_position)
			_cameraUpdate()
	elif event is InputEventMouseMotion:
		if _dragLeft:
			_capture = true
			_cameraTo(_camera.global_position - event.relative * _camera.zoom)
			emit_signal("updateMap")

func _processWasd() -> bool:
	var done := false
	if Input.is_action_pressed("ui_up"):
		_wasd(Vector2i.UP)
		done = true
	if Input.is_action_pressed("ui_ne"):
		_wasd(Vector2i.UP + Vector2i.RIGHT)
		done = true
	if Input.is_action_pressed("ui_right"):
		_wasd(Vector2i.RIGHT)
		done = true
	if Input.is_action_pressed("ui_se"):
		_wasd(Vector2i.DOWN + Vector2i.RIGHT)
		done = true
	if Input.is_action_pressed("ui_down"):
		_wasd(Vector2i.DOWN)
		done = true
	if Input.is_action_pressed("ui_sw"):
		_wasd(Vector2i.DOWN + Vector2i.LEFT)
		done = true
	if Input.is_action_pressed("ui_left"):
		_wasd(Vector2i.LEFT)
		done = true
	if Input.is_action_pressed("ui_nw"):
		_wasd(Vector2i.UP + Vector2i.LEFT)
		done = true
	return done

func _wasd(dir: Vector2i) -> void:
	pass

func _cameraTo(p: Vector2) -> void:
	pass

func _cameraUpdate() -> void:
	pass

func _targetTo(p: Vector2i, turn: bool) -> void:
	pass

func _targetUpdate() -> void:
	pass

func _zoomIn(p: Vector2) -> void:
	pass

func _zoomOut(p: Vector2) -> void:
	pass
