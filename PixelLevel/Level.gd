extends DynamicTileMap
class_name Level

#region Variable

@onready var _hero: Node2D = $Hero
@onready var _target: Node2D = $Target
@onready var _map_edge: TileMap = $TileMapEdge

signal generate(delta: int)
signal update_map_depth

const _path_scene := preload("res://Interface/Path.tscn")
const Directions: Array[Vector2i] = [Vector2i.UP, Vector2i.UP + Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT + Vector2i.DOWN,
	Vector2i.DOWN, Vector2i.DOWN + Vector2i.LEFT, Vector2i.LEFT, Vector2i.LEFT + Vector2i.UP]
const _edge := Vector2i(2, 2)
const _turn_time := 0.22
const _min_path_alpha := 0.1
const _max_path_alpha := 0.75

var _astar: AStar2D = AStar2D.new()
var _path_points := PackedVector2Array()
var _turn := false
var _time := 0.0
var start_at := Vector2i(4, 4)
var _tween_step : Tween
var _sources: Array[TileSetSource]

var _theme := 0 # dungeon _theme
var _day := true # _day or night outside _theme
var _desert := false # _desert or grass outside _theme
const _theme_count := 4 # number of dungeon themes
var _theme_cliff := 0 # cliff _theme
const _theme_cliff_count := 2 # number of cliff themes
var _use_light := true

#endregion

#region Tile Data

enum Direction { N, NE, E, SE, S, SW, W, NW }

# matches tileMap layers
enum Layer {
	Back,
	Fore,
	Flower,
	ItemBack, SplitBack, WaterBack,
	Tree,
	ItemFore, SplitFore, WaterFore,
	Top,
	Light }

# matches tileSet source id
enum Tile {
	Invalid = -1,
	Cliff1, Cliff2,	Banner1, Banner2, Doodad, Rug, Fountain, Loot,
	EdgeInside, EdgeInsideCorner, EdgeOutsideCorner, EdgeOutside,
	Light, LightDebug,
	DayGrass, DayPillar, DayPath, DayStair, DayDesert, DayDoodad,
	DayWeed, DayHedge, DayWall, DayFloor,
	NightGrass, NightPillar, NightPath, NightStair, NightDesert, NightDoodad,
	NightWeed, NightHedge, NightWall, NightFloor,
	TreeFore, TreeBack, TreeStump, Flower, Rubble,
	Theme1Torch, Theme1WallPlain, Theme1Wall, Theme1Floor, Theme1FloorRoom, Theme1Stair, Theme1Door,
	Theme2Torch, Theme2WallPlain, Theme2Wall, Theme2Floor, Theme2FloorRoom, Theme2Stair, Theme2Door,
	Theme3Torch, Theme3WallPlain, Theme3Wall, Theme3Floor, Theme3FloorRoom, Theme3Stair, Theme3Door,
	Theme4Torch, Theme4WallPlain, Theme4Wall, Theme4Floor, Theme4FloorRoom, Theme4Stair, Theme4Door,
	WaterShallowBack, WaterShallowFore, WaterDeepBack, WaterDeepFore,
	WaterShallowPurpleBack, WaterShallowPurpleFore, WaterDeepPurpleBack, WaterDeepPurpleFore }

# used for testing if a tile is a certain type
const _floor_tiles := [
	Tile.Theme1Floor, Tile.Theme2Floor, Tile.Theme3Floor, Tile.Theme4Floor,
	Tile.Theme1FloorRoom, Tile.Theme2FloorRoom, Tile.Theme3FloorRoom, Tile.Theme4FloorRoom,
	Tile.DayGrass, Tile.NightGrass, Tile.DayPath, Tile.NightPath,
	Tile.DayDesert, Tile.NightDesert, Tile.DayFloor, Tile.NightFloor, Tile.Rubble ]
const _wall_tiles := [
	Tile.Theme1Torch, Tile.Theme1Wall, Tile.Theme1WallPlain, Tile.Theme2Torch, Tile.Theme2Wall, Tile.Theme2WallPlain,
	Tile.Theme3Torch, Tile.Theme3Wall, Tile.Theme3WallPlain, Tile.Theme4Torch, Tile.Theme4Wall, Tile.Theme4WallPlain,
	Tile.DayWall, Tile.NightWall, Tile.DayHedge, Tile.NightHedge ]
const _cliff_tiles := [Tile.Cliff1, Tile.Cliff2]
const _stair_tiles := [Tile.Theme1Stair, Tile.Theme2Stair, Tile.Theme3Stair, Tile.Theme4Stair, Tile.DayStair, Tile.NightStair]
const _door_tiles := [Tile.Theme1Door, Tile.Theme2Door, Tile.Theme3Door, Tile.Theme4Door]
const _water_tiles := [Tile.WaterShallowBack, Tile.WaterShallowFore, Tile.WaterDeepBack, Tile.WaterDeepFore,
	Tile.WaterShallowPurpleBack, Tile.WaterShallowPurpleFore, Tile.WaterDeepPurpleBack, Tile.WaterDeepPurpleFore]
const _water_deep_tiles := [Tile.WaterDeepBack, Tile.WaterDeepFore, Tile.WaterDeepPurpleBack, Tile.WaterDeepPurpleFore]
const _water_purple_tiles := [Tile.WaterShallowPurpleBack, Tile.WaterShallowPurpleFore, Tile.WaterDeepPurpleBack, Tile.WaterDeepPurpleFore]

# atlas coords
enum Door { Shut, Open, Broke }
enum Stair { Down, Up}
enum Loot { ChestShut, ChestOpenFull, ChestOpenEmpty, ChestBroke, Pile }
enum Weed { BackDry, Back, ForeDry, Fore }
enum EdgeOutsideCorner { TopRight, TopLeft, BottomLeft, BottomRight }

# alternatives
enum Edge { Top, TopFlip, Bottom, Left, Right, LeftFlip, BottomFlip, RightFlip }
enum EdgeInsideCorner { TopLeft, TopRight, BottomLeft, TopLeftFlip, TopRightFlip, BottomLeftFlip, BottomRight, BottomRightFlip }

#endregion

#region Init / Input

func _ready() -> void:
	await get_tree().get_root().ready # wait for all nodes (LevelManager) to be ready
	super._ready()
	_cache_sources()
	if not LevelStore.data.level.is_empty():
		load_map(LevelStore.data.level)
		start_at = LevelStore.data.main.position
		update_map_depth.emit()
		generated()
	else:
		generate.emit(0)
	update_map.emit()

func generated() -> void:
	_draw_edge()
	_hero.global_position = map_to_local(start_at)
	_path_clear()
	_target.modulate = Color.TRANSPARENT
	_camera_to_hero()
	_dark()
	_find_torches()
	_light_update(_hero_position(), light_radius)
	verify_cliff()
	_add_points()
	_connect()
	var rect := tile_rect()
	LevelStore.data.main.width = rect.size.x
	LevelStore.data.main.height = rect.size.y
	LevelStore.data.level = save_map([Layer.Light])

func _cache_sources() -> void:
	for i in _map.tile_set.get_source_count():
		_sources.append(_map.tile_set.get_source(i))

func _process(delta: float) -> void:
	super._process(delta)
	_time += delta
	LevelStore.data.main.time += _time
	if _time > _turn_time and (_turn or _process_wasd()):
		LevelStore.data.main.turns += 1
		var test := _turn
		_turn = false
		if test:
			if not _handle_door():
				await _move(_hero)
			if not _handle_stair():
				_light_update(_hero_position(), light_radius)
				if not _panning:
					_check_center()
		_time = 0.0

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_turn = false
			if not event.pressed && not _panning:
				var turn := not _tween_step or not _tween_step.is_running()
				_target_to(global_to_map(event.global_position), turn)

func clear() -> void:
	super.clear()
	_map_edge.clear()

func _check_center() -> void:
	constrain_tile_to_camera(_hero_position())

func _process_wasd() -> bool:
	var done := false
	if Input.is_action_pressed("ui_up"):
		_wasd(Vector2i.UP)
		done = true
	if Input.is_action_pressed("ui_right"):
		_wasd(Vector2i.RIGHT)
		done = true
	if Input.is_action_pressed("ui_down"):
		_wasd(Vector2i.DOWN)
		done = true
	if Input.is_action_pressed("ui_left"):
		_wasd(Vector2i.LEFT)
		done = true
	return done

func _wasd(direction: Vector2i) -> void:
	var p := _hero_position() + direction
	if is_door_shut(p):
		_toggle_door(p)
	if not is_blocked(p):
		_face(_hero, direction)
		await _step(_hero, direction)
		_path_clear()
		if not is_stair(p):
			_light_update(p, light_radius)
			if not _panning:
				_check_center()
		else:
			if is_stair_down(p):
				generate.emit(1)
			elif is_stair_up(p):
				generate.emit(-1)
	else:
		Audio.bump()

#endregion

#region Map

func save_maps_texture() -> void:
	var viewport := SubViewport.new()
	var tile_size := _map_edge.tile_set.tile_size
	var new_size := _map_edge.get_used_rect().size * tile_size
	var new_camera := _camera.duplicate()
	new_camera.global_position = (new_size - tile_size * 2) / 2
	new_camera.zoom = Vector2i.ONE
	viewport.add_child(new_camera)
	viewport.add_child(_map_edge.duplicate())
	viewport.add_child(_map.duplicate())
	viewport.add_child(_hero.duplicate())
	viewport.size = new_size
	viewport.transparent_bg = true
	viewport.render_target_clear_mode = ClearMode.CLEAR_MODE_ONCE
	viewport.render_target_update_mode = UpdateMode.UPDATE_ONCE
	add_child(viewport)
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var ok := func(path: String) -> void:
		image.save_png(path)
		viewport.queue_free()
	AutoFileDialog.show_save(ok, ["*.png ; PNG Files"])

func _move(mob: Node2D) -> void:
	await get_tree().process_frame
	if _path_points.size() > 1:
		var delta := _delta(_path_points[0], _path_points[1])
		_face(mob, delta)
		_fade_and_free()
		await _step(mob, delta)

func _fade_and_free() -> void:
	_path_points.remove_at(0)
	var node := _map.get_child(0)
	await create_tween().tween_property(node, "modulate", Color.TRANSPARENT, _turn_time).finished
	node.queue_free()
	if _path_points.size() > 1:
		_turn = true
	else:
		_path_clear()

func _handle_stair() -> bool:
	if _path_points.size() == 1:
		var p := _hero_position()
		if is_stair_down(p):
			LevelStore.data.main.depth += 1
			generate.emit(1)
			return true
		elif is_stair_up(p):
			LevelStore.data.main.depth -= 1
			generate.emit(-1)
			return true
	return false

func _handle_door() -> bool:
	var from := _hero_position()
	var to := _target_position()
	if (from - to).length() < 2.0:
		if is_door(to):
			_toggle_door(to)
			return true
	return false

const _door_break_chance = 0.02

func _toggle_door(p: Vector2i) -> void:
	if not is_door(p): return
	var door := _map.get_cell_atlas_coords(Layer.Fore, p)
	var source := _sources[_map.get_cell_source_id(Layer.Fore, p)]
	var doorBroke := source.get_tile_id(Door.Broke)
	var doorOpen := source.get_tile_id(Door.Open)
	if door != doorBroke:
		var broke := Random.next_float() <= _door_break_chance
		set_door(p, Door.Broke if broke else Door.Shut if door == doorOpen else Door.Open)
		_astar.set_point_disabled(tile_index(p), is_door_shut(p))

func _face(mob: Node2D, direction: Vector2i) -> void:
	if direction.x > 0 or direction.y > 0:
		mob.scale = Vector2i(-1, 1)
	else:
		mob.scale = Vector2i(1, 1)

func _step(mob: Node2D, direction: Vector2i) -> void:
	mob.walk()
	var map := local_to_map(mob.global_position) + direction
	var to: Vector2 = map_to_local(map)
	_tween_step = create_tween()
	_tween_step.tween_property(mob, "global_position", to, _turn_time)
	_tween_step.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN_OUT)
	_tween_step.tween_callback(func(): update_map.emit())
	await _tween_step.finished
	LevelStore.data.main.position = map

func _add_points() -> void:
	_astar.clear()
	var rect := tile_rect()
	for y in rect.size.y:
		for x in rect.size.x:
			var p := Vector2i(x, y)
			_astar.add_point(tile_index(p), p)
			if is_door_shut(p):
				_astar.set_point_disabled(tile_index(p))

func _connect() -> void:
	var rect := tile_rect()
	for y in rect.size.y:
		for x in rect.size.x:
			var cell := Vector2i(x, y)
			var cellId := tile_index(cell)
			if is_inside_map(cell) and not is_blocked(cell):
				for direction in Directions:
					var neighbor := cell + direction
					var neighborId := tile_index(neighbor)
					if is_inside_map(neighbor) and not is_blocked(neighbor) and not _astar.are_points_connected(cellId, neighborId):
						_astar.connect_points(cellId, neighborId)

func is_blocked(p: Vector2i) -> bool:
	return !is_floor(p) || is_blocked_light(p)

func is_blocked_light(p: Vector2i) -> bool:
	return is_wall(p) or is_door_shut(p)

func _camera_to_hero() -> void:
	move_camera_to(_hero.global_position)

#endregion

#region Target

func _hero_position() -> Vector2i:
	return local_to_map(_hero.global_position)

func _target_position() -> Vector2i:
	return local_to_map(_target.global_position)

func _target_to_hero() -> void:
	_target_to(_hero_position())

func _target_to(tile: Vector2i, turn := true) -> void:
	if is_inside_map(tile):
		if tile == _target_position():
			_turn = turn
		else:
			_targetUpdate(tile)
	else:
		_targetUpdate(_targetClosest(tile))

func _targetClosest(tile: Vector2i) -> Vector2i:
	return _astar.get_point_position(_astar.get_closest_point(tile, true))

func _targetUpdate(tile: Vector2i) -> void:
	var from := _hero_position()
	var to: Vector2 = map_to_local(tile)
	var toColor := _get_path_color(tile)
	toColor.a = 0.75
	_target.global_position = map_to_local(from)
	_target.modulate = Color.TRANSPARENT
	var tween := create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_property(_target, "global_position", to, _duration)
	tween.parallel().tween_property(_target, "modulate", toColor, _duration)
	_path_clear()
	if from != tile:
		_drawPath(from, tile)

#endregion

#region Path

func _drawPath(from: Vector2i, to: Vector2i) -> void:
	var rotation := 0
	var path_delta := _delta(from, to)
	_path_points = _astar.get_point_path(tile_index(from), tile_index(to))
	for i in _path_points.size():
		var tile := _path_points[i]
		if i + 1 < _path_points.size():
			rotation = _path_rotate(_delta(tile, _path_points[i + 1]), path_delta)
		var child := _path_scene.instantiate()
		var to_color := _get_path_color(to)
		to_color.a = i / float(_path_points.size()) * (_max_path_alpha - _min_path_alpha) + _min_path_alpha
		create_tween().tween_property(child, "modulate", to_color, _duration).set_delay(i / float(_path_points.size()) * _duration)
		child.global_rotation_degrees = rotation
		child.global_position = map_to_local(tile)
		_map.add_child(child)

func _delta(from: Vector2i, to: Vector2i) -> Vector2:
	return to - from

func _path_rotate(step_delta: Vector2i, path_delta: Vector2i) -> int:
	var rotation := 0
	var trending = abs(path_delta.y) > abs(path_delta.x)
	if step_delta.x > 0 and step_delta.y < 0:
		rotation = 270 if trending else 0
	elif step_delta.x > 0 and step_delta.y > 0:
		rotation = 90 if trending else 0
	elif step_delta.x < 0 and step_delta.y < 0:
		rotation = 270 if trending else 180
	elif step_delta.x < 0 and step_delta.y > 0:
		rotation = 90 if trending else 180
	elif step_delta.x > 0:
		rotation = 0
	elif step_delta.x < 0:
		rotation = 180
	elif step_delta.y < 0:
		rotation = 270
	elif step_delta.y > 0:
		rotation = 90
	return rotation

func _path_clear():
	_target.modulate = Color.TRANSPARENT
	for path in _map.get_children():
		path.free()
	for i in range(_path_points.size() - 1, 0, -1):
		_path_points.remove_at(i)

#endregion

#region MiniMap

const _alpha := 0.8
const _color_mob := Color(0, 1, 0, _alpha)
const _color_stair := Color(1, 1, 0, _alpha)
const _color_door := Color(0, 0, 1, _alpha)
const _color_wall_lit := Color(1, 1, 1, _alpha)
const _color_wall := Color(0.8, 0.8, 0.8, _alpha)
const _color_floor_lit := Color(0.4, 0.4, 0.4, _alpha)
const _color_floor := Color(0.2, 0.2, 0.2, _alpha)
const _color_camera := Color(1, 0, 1, _alpha)

func _is_on_rect(p: Vector2i, r: Rect2i) -> bool:
	return (((p.x >= r.position.x and p.x <= r.position.x + r.size.x - 1) and (p.y == r.position.y or p.y == r.position.y + r.size.y - 1)) or
			((p.y >= r.position.y and p.y <= r.position.y + r.size.y - 1) and (p.x == r.position.x or p.x == r.position.x + r.size.x - 1)))

func get_map_color(p: Vector2i) -> Color:
	var camera := camera_bounds_map()
	var color := Color(0.25, 0.25, 0.25, 0.25)
	var on := _is_on_rect(p, camera)
	if on:
		color = _color_camera
	var lit := is_lit(p)
	var explored := is_explored(p)
	var hero := _hero_position()
	if not _map.is_layer_enabled(Layer.Light) or (lit or explored):
		if p == hero:
			color = _color_mob
		elif is_stair(p):
			color = _color_stair
		elif is_door(p):
			color = _color_door
		elif on:
			color = _color_camera
		elif is_wall(p):
			color = _color_wall_lit if lit else _color_wall
		elif is_floor(p):
			color = _color_floor_lit if lit else _color_floor
		else:
			color = _color_wall_lit if lit else _color_wall
	return color

func _get_path_color(p: Vector2i) -> Color:
	var color := _color_wall
	if is_stair(p):
		color = _color_stair
	elif is_door(p):
		color = _color_door
	elif is_wall(p):
		color = _color_wall
	elif is_floor(p):
		color = _color_mob
	return color

#endregion

#region Light

const _torch_radius := 8
const _torch_radius_max := _torch_radius * 2
var light_radius := 16
const _light_min := 0
const _light_max := 31
const _light_explored := 8
const _light_count := 24
const _fov_octants = [
	[1,  0,  0, -1, -1,  0,  0,  1],
	[0,  1, -1,  0,  0, -1,  1,  0],
	[0,  1,  1,  0,  0, -1, -1,  0],
	[1,  0,  0,  1, -1,  0,  0, -1]
]
var _torches := {}

func light_toggle() -> void:
	_use_light = not _map.is_layer_enabled(Layer.Light)
	_map.set_layer_enabled(Layer.Light, _use_light)

func light_increase() -> void:
	light_radius += 1
	_light_update(_hero_position(), light_radius)

func light_decrease() -> void:
	light_radius -= 1
	_light_update(_hero_position(), light_radius)

# https://web.archive.org/web/20130705072606/http://doryen.eptalys.net/2011/03/ramblings-on-lights-in-full-color-roguelikes/
# https://journal.stuffwithstuff.com/2015/09/07/what-the-hero-sees/
# https://www.roguebasin.com/index.php/FOV_using_recursive_shadowcasting
func _light_emit_recursive(at: Vector2i, radius: float, max_radius: float, start: float, end: float, xx: int, xy: int, yx: int, yy: int) -> void:
	if start < end: return
	var max_radius_squared := max_radius * max_radius
	var new_start := 0.0
	for i in range(radius, max_radius + 1):
		var dx := -i - 1
		var dy := -i
		var blocked := false
		while dx <= 0:
			dx += 1
			var p := Vector2i(at.x + dx * xx + dy * xy, at.y + dx * yx + dy * yy)
			if not is_inside_map(p): continue
			var slope_left := (dx - 0.5) / (dy + 0.5)
			var slope_right := (dx + 0.5) / (dy - 0.5)
			if start < slope_right: continue
			elif end > slope_left: break
			else:
				var distance_squared := (at.x - p.x) * (at.x - p.x) + (at.y - p.y) * (at.y - p.y)
				if distance_squared < max_radius_squared:
					var intensity_1 := 1.0 / (1.0 + distance_squared / max_radius)
					var intensity_2 := intensity_1 - 1.0 / (1.0 + max_radius_squared)
					var intensity := intensity_2 / (1.0 - 1.0 / (1.0 + max_radius_squared))
					var light := int(intensity * _light_count)
					_set_light(p, _light_explored + light, true)
				var blocked_at := is_blocked_light(p)
				if blocked:
					if blocked_at:
						new_start = slope_right
						continue
					else:
						blocked = false
						start = new_start
				elif blocked_at and radius < max_radius:
					blocked = true
					_light_emit_recursive(at, i + 1, max_radius, start, slope_left, xx, xy, yx, yy)
					new_start = slope_right
		if blocked: break

func _light_emit(at: Vector2i, radius: int) -> void:
	for i in range(_fov_octants[0].size()):
		_light_emit_recursive(at, 1, radius, 1.0, 0.0, _fov_octants[0][i], _fov_octants[1][i], _fov_octants[2][i], _fov_octants[3][i])
	_set_light(at, _light_max, true)

func _light_update(at: Vector2i, radius: int) -> void:
	_map.set_layer_enabled(Layer.Light, _use_light)
	if _use_light:
		_darken()
		_light_emit(at, radius)
		_light_torches()

func _find_torches() -> void:
	_torches.clear()
	var torch_0 := _map.get_used_cells_by_id(Layer.Fore, Tile.Theme1Torch)
	var torch_1 := _map.get_used_cells_by_id(Layer.Fore, Tile.Theme1Torch)
	var torch_2 := _map.get_used_cells_by_id(Layer.Fore, Tile.Theme2Torch)
	var torch_3 := _map.get_used_cells_by_id(Layer.Fore, Tile.Theme3Torch)
	for p in torch_0 + torch_1 + torch_2 + torch_3:
		_torches[p] = Random.next(_torch_radius)

func _light_torches() -> void:
	for p in _torches.keys():
		_torches[p] = clamp(_torches[p] + Random.next_range(-1, 1), 2, _torch_radius_max)
		var current = _torches[p]
		var north := Vector2i(p.x, p.y + 1)
		var east := Vector2i(p.x + 1, p.y)
		var south := Vector2i(p.x, p.y - 1)
		var west := Vector2i(p.x - 1, p.y)
		var emitted := false
		if is_inside_map(p):
			var north_blocked := is_blocked(north)
			if not north_blocked and is_lit(north):
				emitted = true
				_light_emit(north, current)
			var east_blocked := is_blocked(east)
			if not east_blocked and is_lit(east):
				emitted = true
				_light_emit(east, current)
			var south_blocked := is_blocked(south)
			if not south_blocked and is_lit(south):
				emitted = true
				_light_emit(south, current)
			var west_blocked := is_blocked(west)
			if not west_blocked and is_lit(west):
				emitted = true
				_light_emit(west, current)
			if not emitted:
				var north_east := Vector2i(p.x + 1, p.y + 1)
				var south_east := Vector2i(p.x + 1, p.y - 1)
				var south_west := Vector2i(p.x - 1, p.y - 1)
				var north_west := Vector2i(p.x - 1, p.y + 1)
				if north_blocked and east_blocked and not is_blocked(north_east) and is_lit(north_east):
					_light_emit(north_east, current)
				if south_blocked and east_blocked and not is_blocked(south_east) and is_lit(south_east):
					_light_emit(south_east, current)
				if south_blocked and west_blocked and not is_blocked(south_west) and is_lit(south_west):
					_light_emit(south_west, current)
				if north_blocked and west_blocked and not is_blocked(north_west) and is_lit(north_west):
					_light_emit(north_west, current)

func _dark() -> void:
	var rect := tile_rect()
	for y in rect.size.y:
		for x in rect.size.x:
			_set_light(Vector2i(x, y), _light_min, false)

func _darken() -> void:
	var rect := tile_rect()
	for y in rect.size.y:
		for x in rect.size.x:
			var p := Vector2i(x, y)
			if _get_light(p) != _light_min:
				_set_light(p, _light_explored, false)

#endregion

#region Tile

func _set_tile_map(map: TileMap, layer: Layer, p: Vector2i, tile := INVALID, coords := INVALID_CELL, alternative := 0) -> void:
	map.set_cell(layer, p, tile, coords, alternative)

func _set_tile(layer: Layer, p: Vector2i, tile := INVALID, coords := INVALID_CELL, alternative := 0) -> void:
	_set_tile_map(_map, layer, p, tile, coords, alternative)

func _clear_tile(layer: Layer, p: Vector2i) -> void:
	_set_tile(layer, p)

func _set_random_tile_map(tileMap: TileMap, layer: Layer, p: Vector2i, tile: Tile, index := INVALID, alternative := INVALID) -> void:
	var coord := _random_tile_coords_index(tile) if index == INVALID else index
	var alt := _random_tile_alternative(tile, coord) if alternative == INVALID else alternative
	_set_tile_map(tileMap, layer, p, tile, _sources[tile].get_tile_id(coord), alt)

func _set_random_tile(layer: Layer, p: Vector2i, tile: Tile, index := INVALID, alternative := INVALID) -> void:
	_set_random_tile_map(_map, layer, p, tile, index, alternative)

# fake layer with Layer.Back, 0, for edge
func _set_random_tile_edge(p: Vector2i, tile: Tile, index := INVALID, alternative := INVALID) -> void:
	_set_random_tile_map(_map_edge, Layer.Back, p, tile, index, alternative)

func _random_tile_coords_index(tile: Tile) -> int:
	var array: Array[float] = []
	var source := _sources[tile]
	for i in source.get_tiles_count():
		array.append(source.get_tile_data(source.get_tile_id(i), 0).probability)
	return Random.probability_index(array)

func _random_tile_alternative(tile: Tile, index: int) -> int:
	var source := _sources[tile]
	return Random.next(source.get_alternative_tiles_count(source.get_tile_id(index)))

#region Back / Floor

## used to test for "cliff" walls which are just empty tiles, no floor
func is_back_invalid(p: Vector2i) -> bool:
	return _map.get_cell_tile_data(Layer.Back, p) == null

func clear_back(p: Vector2i) -> void:
	_clear_tile(Layer.Back, p)

func _set_back_random(p: Vector2i, tile: int, wonky := true) -> void:
	_set_random_tile(Layer.Back, p, tile, INVALID, INVALID if wonky else 0)

func set_floor(p: Vector2, wonky: bool) -> void:
	var tile: Tile
	match _theme:
		0: tile = Tile.Theme1Floor
		1: tile = Tile.Theme2Floor
		2: tile = Tile.Theme3Floor
		3: tile = Tile.Theme4Floor
	_set_back_random(p, tile, wonky)

func set_floor_room(p: Vector2, wonky: bool) -> void:
	var tile: Tile
	match _theme:
		0: tile = Tile.Theme1FloorRoom
		1: tile = Tile.Theme2FloorRoom
		2: tile = Tile.Theme3FloorRoom
		3: tile = Tile.Theme4FloorRoom
	_set_back_random(p, tile, wonky)

func set_outside(p: Vector2i) -> void:
	if _desert:
		_set_back_random(p, Tile.DayDesert if _day else Tile.NightDesert)
	else:
		_set_back_random(p, Tile.DayGrass if _day else Tile.NightGrass)

func set_outside_floor(p: Vector2) -> void:
	_set_back_random(p, Tile.DayFloor if _day else Tile.NightFloor)

func set_outside_path(p: Vector2i) -> void:
	_set_back_random(p, Tile.DayPath if _day else Tile.NightPath)

func set_rubble(p: Vector2i) -> void:
	_set_back_random(p, Tile.Rubble)

func _is_back_tile(p: Vector2i, tiles: Array) -> bool:
	return tiles.has(_map.get_cell_source_id(Layer.Back, p))

func is_floor(p: Vector2i) -> bool:
	return _is_back_tile(p, _floor_tiles)

#endregion

#region Fore / Wall

func is_fore_invalid(p: Vector2i) -> bool:
	return _map.get_cell_tile_data(Layer.Fore, p) == null

func clear_fore(p: Vector2i) -> void:
	_clear_tile(Layer.Fore, p)

func _set_fore_random(p: Vector2i, tile: int, coords := INVALID, alternative := INVALID) -> void:
	_set_random_tile(Layer.Fore, p, tile, coords, alternative)

func set_wall_plain(p: Vector2i) -> void:
	var tile: Tile
	match _theme:
		0: tile = Tile.Theme1WallPlain
		1: tile = Tile.Theme2WallPlain
		2: tile = Tile.Theme3WallPlain
		3: tile = Tile.Theme4WallPlain
	_set_fore_random(p, tile)

func set_wall(p: Vector2i) -> void:
	var tile: Tile
	match _theme:
		0: tile = Tile.Theme1Wall
		1: tile = Tile.Theme2Wall
		2: tile = Tile.Theme3Wall
		3: tile = Tile.Theme4Wall
	_set_fore_random(p, tile)

func set_torch(p: Vector2i) -> void:
	var tile: Tile
	match _theme:
		0: tile = Tile.Theme1Torch
		1: tile = Tile.Theme2Torch
		2: tile = Tile.Theme3Torch
		3: tile = Tile.Theme4Torch
	_set_fore_random(p, tile)

func set_outside_wall(p: Vector2i) -> void:
	_set_fore_random(p, Tile.DayWall if _day else Tile.NightWall)

func set_outside_hedge(p: Vector2i) -> void:
	_set_fore_random(p, Tile.DayHedge if _day else Tile.NightHedge)

func set_cliff(p: Vector2i) -> void:
	var tile: Tile
	match _theme_cliff:
		0: tile = Tile.Cliff1
		1: tile = Tile.Cliff2
	_set_fore_random(p, tile)

func _set_stair(p: Vector2i, type: Stair) -> void:
	var tile: Tile
	match _theme:
		0: tile = Tile.Theme1Stair
		1: tile = Tile.Theme2Stair
		2: tile = Tile.Theme3Stair
		3: tile = Tile.Theme4Stair
	_set_fore_random(p, tile, type, 0)

func set_stair_down(p: Vector2i) -> void:
	_set_stair(p, Stair.Down)

func set_stair_up(p: Vector2i) -> void:
	_set_stair(p, Stair.Up)

func _set_stair_outside(p: Vector2i, type: Stair) -> void:
	var tile := Tile.DayStair if _day else Tile.NightStair
	if _desert:
		_set_fore_random(p, tile, type + 2)
	else:
		_set_fore_random(p, tile, type)

func set_stair_outside_up(p: Vector2i) -> void:
	_set_stair_outside(p, Stair.Up)

func set_stair_outside_down(p: Vector2i) -> void:
	_set_stair_outside(p, Stair.Down)

func set_door(p: Vector2i, type = Random.next(Door.size())) -> void:
	var tile: Tile
	match _theme:
		0: tile = Tile.Theme1Door
		1: tile = Tile.Theme2Door
		2: tile = Tile.Theme3Door
		3: tile = Tile.Theme4Door
	_set_fore_random(p, tile, type)

func set_door_broke(p: Vector2i) -> void:
	var tile: Tile
	match _theme:
		0: tile = Tile.Theme1Door
		1: tile = Tile.Theme2Door
		2: tile = Tile.Theme3Door
		3: tile = Tile.Theme4Door
	_set_fore_random(p, tile, Door.Broke)

func set_fountain(p: Vector2i) -> void:
	_set_fore_random(p, Tile.Fountain)

func set_banner_1(p: Vector2i) -> void:
	_set_fore_random(p, Tile.Banner1)

func set_banner_2(p: Vector2i) -> void:
	_set_fore_random(p, Tile.Banner2)

func _is_fore_tile(p: Vector2i, tiles: Array) -> bool:
	return tiles.has(_map.get_cell_source_id(Layer.Fore, p))

func is_wall(p: Vector2i) -> bool:
	return _is_fore_tile(p, _wall_tiles)

func is_cliff(p: Vector2i) -> bool:
	return _is_fore_tile(p, _cliff_tiles)

func is_stair(p: Vector2i) -> bool:
	return _is_fore_tile(p, _stair_tiles)

func is_stair_up(p: Vector2i) -> bool:
	var source := _sources[_map.get_cell_source_id(Layer.Fore, p)]
	return is_stair(p) and _map.get_cell_atlas_coords(Layer.Fore, p) == source.get_tile_id(Stair.Up)

func is_stair_down(p: Vector2i) -> bool:
	var source := _sources[_map.get_cell_source_id(Layer.Fore, p)]
	return is_stair(p) and _map.get_cell_atlas_coords(Layer.Fore, p) == source.get_tile_id(Stair.Down)

func is_door(p: Vector2i) -> bool:
	return _is_fore_tile(p, _door_tiles)

func is_door_shut(p: Vector2i) -> bool:
	var source := _sources[_map.get_cell_source_id(Layer.Fore, p)]
	return is_door(p) and _map.get_cell_atlas_coords(Layer.Fore, p) == source.get_tile_id(Door.Shut)

func verify_cliff() -> void:
	var rect := tile_rect()
	for y in rect.size.y:
		for x in rect.size.x:
			var p = Vector2i(x, y)
			if is_cliff(p) and not is_floor(Vector2i(x, y - 1)):
				clear_fore(p)

#endregion

#region Outside

func set_flower(p: Vector2i) -> void:
	_set_random_tile(Layer.Flower, p, Tile.Flower)

func set_tree(p: Vector2i) -> void:
	var random := Random.next(3)
	_set_random_tile(Layer.Top, p + Vector2i(0, -1), Tile.TreeFore, random)
	_set_random_tile(Layer.Tree, p, Tile.TreeBack, random)

func set_tree_stump(p: Vector2i) -> void:
	_set_random_tile(Layer.Tree, p, Tile.TreeStump)

func clear_tree(p: Vector2i) -> void:
	_clear_tile(Layer.Top, p + Vector2i(0, -1))
	_clear_tile(Layer.Tree, p)

func cut_tree(p: Vector2i) -> void:
	clear_tree(p)
	set_tree_stump(p)

func set_weed(p: Vector2i) -> void:
	var tile := Tile.DayWeed if _day else Tile.NightWeed
	if _desert:
		_set_random_tile(Layer.SplitBack, p, tile, Weed.BackDry)
		_set_random_tile(Layer.SplitFore, p, tile, Weed.ForeDry)
	else:
		_set_random_tile(Layer.SplitBack, p, tile, Weed.Back)
		_set_random_tile(Layer.SplitFore, p, tile, Weed.Fore)

#endregion

#region Water

func set_water_shallow(p: Vector2i) -> void:
	var c := _random_tile_coords_index(Tile.WaterShallowBack)
	var a := _random_tile_alternative(Tile.WaterShallowBack, c)
	_set_random_tile(Layer.WaterBack, p, Tile.WaterShallowBack, c, a)
	_set_random_tile(Layer.WaterFore, p, Tile.WaterShallowFore, c, a)

func set_water_deep(p: Vector2i) -> void:
	var c := _random_tile_coords_index(Tile.WaterDeepBack)
	var a := _random_tile_alternative(Tile.WaterDeepBack, c)
	_set_random_tile(Layer.WaterBack, p, Tile.WaterDeepBack, c, a)
	_set_random_tile(Layer.WaterFore, p, Tile.WaterDeepFore, c, a)

func set_water_shallow_purple(p: Vector2i) -> void:
	var c := _random_tile_coords_index(Tile.WaterShallowPurpleBack)
	var a := _random_tile_alternative(Tile.WaterShallowPurpleBack, c)
	_set_random_tile(Layer.WaterBack, p, Tile.WaterShallowPurpleBack, c, a)
	_set_random_tile(Layer.WaterFore, p, Tile.WaterShallowPurpleFore, c, a)

func set_water_deep_purple(p: Vector2i) -> void:
	var c := _random_tile_coords_index(Tile.WaterDeepPurpleBack)
	var a := _random_tile_alternative(Tile.WaterDeepPurpleBack, c)
	_set_random_tile(Layer.WaterBack, p, Tile.WaterDeepPurpleBack, c, a)
	_set_random_tile(Layer.WaterFore, p, Tile.WaterDeepPurpleFore, c, a)

func _is_water_tile(p: Vector2i, tiles: Array) -> bool:
	return tiles.has(_map.get_cell_source_id(Layer.WaterBack, p)) or tiles.has(_map.get_cell_source_id(Layer.WaterFore, p))

func is_water(p: Vector2i) -> bool:
	return _is_water_tile(p, _water_tiles)

func is_water_deep(p: Vector2i) -> bool:
	return _is_water_tile(p, _water_deep_tiles)

func is_water_purple(p: Vector2i) -> bool:
	return _is_water_tile(p, _water_purple_tiles)

#endregion

#region Item

func _set_item_fore_random(p: Vector2i, tile: int) -> void:
	_set_random_tile(Layer.ItemFore, p, tile)

func _set_item_back_random(p: Vector2i, tile: int) -> void:
	_set_random_tile(Layer.ItemBack, p, tile)

func set_loot(p: Vector2i) -> void:
	_set_item_back_random(p, Tile.Loot)

#endregion

#region Light

func _get_light(p: Vector2i) -> int:
	return _map.get_cell_atlas_coords(Layer.Light, p).x

func _set_light(p: Vector2i, light: int, test: bool) -> void:
	if not test or light > _get_light(p):
		_set_tile(Layer.Light, p, Tile.Light, Vector2(light, 0))

func is_explored(p: Vector2i) -> bool:
	return _get_light(p) == _light_explored

func is_lit(p: Vector2i) -> bool:
	return _get_light(p) > _light_explored

#endregion

#region Edge

func _random_edge_outside(d: Direction) -> int:
	match d:
		Direction.N:
			return Edge.Top if Random.next_bool() else Edge.TopFlip
		Direction.E:
			return Edge.Right if Random.next_bool() else Edge.RightFlip
		Direction.S:
			return Edge.Bottom if Random.next_bool() else Edge.BottomFlip
		Direction.W:
			return Edge.Left if Random.next_bool() else Edge.LeftFlip
	return INVALID

func _random_edge_inside(d: Direction) -> int:
	match d:
		Direction.N:
			return Edge.Top if Random.next_bool() else Edge.TopFlip
		Direction.E:
			return Edge.Right if Random.next_bool() else Edge.RightFlip
		Direction.S:
			return Edge.Bottom if Random.next_bool() else Edge.BottomFlip
		Direction.W:
			return Edge.Left if Random.next_bool() else Edge.LeftFlip
	return INVALID

func _random_edge_inside_corner(d: Direction) -> int:
	match d:
		Direction.NW:
			return EdgeInsideCorner.TopLeft if Random.next_bool() else EdgeInsideCorner.TopLeftFlip
		Direction.NE:
			return EdgeInsideCorner.TopRight if Random.next_bool() else EdgeInsideCorner.TopRightFlip
		Direction.SW:
			return EdgeInsideCorner.BottomLeft if Random.next_bool() else EdgeInsideCorner.BottomLeftFlip
		Direction.SE:
			return EdgeInsideCorner.BottomRight if Random.next_bool() else EdgeInsideCorner.BottomRightFlip
	return INVALID

func _draw_edge() -> void:
	var rect := tile_rect()
	if rect.size == Vector2i.ZERO:
		return
	var min_y := -1
	var max_y := rect.end.y
	var min_x := -1
	var max_x := rect.end.x
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var p := Vector2i(x, y)
			if x == min_x or x == max_x or y == min_y or y == max_y:
				if x == min_x and y == min_y: # nw
					_set_random_tile_edge(p, Tile.EdgeOutsideCorner, EdgeOutsideCorner.TopLeft)
				elif x == min_x and y == max_y: # sw
					_set_random_tile_edge(p, Tile.EdgeOutsideCorner, EdgeOutsideCorner.BottomLeft)
				elif x == max_x and y == min_y: # ne
					_set_random_tile_edge(p, Tile.EdgeOutsideCorner, EdgeOutsideCorner.TopRight)
				elif x == max_x and y == max_y: # se
					_set_random_tile_edge(p, Tile.EdgeOutsideCorner, EdgeOutsideCorner.BottomRight)
				elif x == min_x: # w
					_set_random_tile_edge(p, Tile.EdgeOutside, INVALID, _random_edge_outside(Direction.W))
				elif x == max_x: # e
					_set_random_tile_edge(p, Tile.EdgeOutside, INVALID, _random_edge_outside(Direction.E))
				elif y == min_y: # n
					_set_random_tile_edge(p, Tile.EdgeOutside, INVALID, _random_edge_outside(Direction.N))
				elif y == max_y: # s
					_set_random_tile_edge(p, Tile.EdgeOutside, INVALID, _random_edge_outside(Direction.S))
			elif (x == min_x + 1) or (x == max_x - 1) or (y == min_y + 1) or (y == max_y - 1):
				if x == min_x + 1 and y == min_y + 1: # nw
					_set_random_tile_edge(p, Tile.EdgeInsideCorner, EdgeInsideCorner.TopLeft, _random_edge_inside_corner(Direction.NW))
				elif x == min_x + 1 and y == max_y - 1: # sw
					_set_random_tile_edge(p, Tile.EdgeInsideCorner, EdgeInsideCorner.BottomLeft, _random_edge_inside_corner(Direction.SW))
				elif x == max_x - 1 and y == min_y + 1: # ne
					_set_random_tile_edge(p, Tile.EdgeInsideCorner, EdgeInsideCorner.TopRight, _random_edge_inside_corner(Direction.NE))
				elif x == max_x - 1 and y == max_y - 1: # se
					_set_random_tile_edge(p, Tile.EdgeInsideCorner, EdgeInsideCorner.BottomRight, _random_edge_inside_corner(Direction.SE))
				elif x == min_x + 1: # w
					_set_random_tile_edge(p, Tile.EdgeInside, INVALID, _random_edge_inside(Direction.W))
				elif x == max_x - 1: # e
					_set_random_tile_edge(p, Tile.EdgeInside, INVALID, _random_edge_inside(Direction.E))
				elif y == min_y + 1: # n
					_set_random_tile_edge(p, Tile.EdgeInside, INVALID, _random_edge_inside(Direction.N))
				elif y == max_y - 1: # s
					_set_random_tile_edge(p, Tile.EdgeInside, INVALID, _random_edge_inside(Direction.S))

#endregion

#endregion
