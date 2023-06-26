## Cellular automaton generator.
## Used to generate a 2D grid of boolean values using a cellular automaton algorithm.
## Intended for creating caves, forests, patches of grass or flowers, or lakes.
## I use 1 (alive/true) for wall and 0 (dead/false) for floor.
## Example output for a 10x10 grid with default parameters:
## 1111111111 1111111111 1111111111 1111111111 1111111111
## 1111111111 1111110011 1111110111 1110111111 1111100111
## 1111111111 1111100001 1111101001 1100011111 1111100011
## 1100001111 1111100001 1111000001 1110000011 1111110011
## 1000000011 1111110001 1111000011 1111000001 1111110011
## 1000000001 1111111001 1110000111 1111000001 1100100011
## 1000000001 1111111001 1110000111 1111100001 1000000011
## 1000000001 1111111001 1110000001 1111110011 1100000111
## 1000000011 1111111111 1110000001 1111111111 1111001111
## 1100111111 1111111111 1111000011 1111111111 1111111111
extends Object
class_name CellularAutomaton

const _steps := 10 # default number of steps to simulate (randomized)
const _chance := 0.2 # default half offset chance of a cell being alive at the start (randomized)
const _birth := 4 # default number of neighbors required for a dead cell to become alive
const _death := 3 # default number of neighbors required for a live cell to die
var _width := 0
var _height := 0
var _count := 0

## Initialize the generator with the specified [param width] and [param height] of the grid.
func _init(width: int, height: int) -> void:
	_width = width
	_height = height
	_count = width * height

## Return a 2D grid of bools using a cellular automaton algorithm.
## [param steps] defines the number of steps to simulate.
## [param chance] defines the chance of a cell being alive at the start.
## [param birth] defines the number of neighbors required for a dead cell to become alive.
## [param death] defines the number of neighbors required for a live cell to die.
## See [method simulate], [method Random.next], [method Random.next_float].
func generate(steps := Random.next(_steps), chance := Random.next_range_float(0.5 - _chance, 0.5 + _chance), birth := _birth, death := _death) -> Array[bool]:
	if _width <= 0 or _height <= 0:
		return []
	var grid: Array[bool] = []
	for i in _count:
		grid.append(Random.next_float() < chance)
	for i in steps:
		grid = _simulate(grid, birth, death)
	# if OS.is_debug_build():
	# 	print("Steps: ", steps, ", Chance: ", chance, ", Birth: ", birth, ", Death: ", death)
	# 	_print(grid)
	return grid

## Return a step of cellular automaton algorithm using the specified [param old_grid] and [param birth] and [param death] parameters.
## See [method _count], [method Utility.unflatten].
func _simulate(old_grid: Array[bool], birth: int, death: int) -> Array[bool]:
	var grid: Array[bool] = []
	for i in _count:
		var position := Utility.unflatten(i, _width)
		var count := _count_neighbors(old_grid, position)
		grid.append((old_grid[i] and count >= death) or (not old_grid[i] and count > birth))
	return grid

## Return the number of live neighbors of a [param position] in a [param grid]. See [method Utility.flatten].
func _count_neighbors(grid: Array[bool], position: Vector2i) -> int:
	var count := 0
	for x in range(-1, 2):
		for y in range(-1, 2):
			var neighbor := position + Vector2i(x, y)
			if x == 0 and y == 0:
				continue
			elif neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= _width or neighbor.y >= _height:
				count += 1
			elif grid[Utility.flatten(neighbor, _width)]:
				count += 1
	return count

## Return the biggest `floor` set in [param grid] as array of indices.
## See [DisjointSet], [method Utility.flatten], [method Utility.unflatten].
func find_biggest(grid: Array[bool]) -> Array:
	var arrays := DisjointSet.new(_width, _height, grid).split()
	if arrays.size() == 0: return []
	if arrays.size() == 1: return arrays[0]
	var maxSize := 0
	var result := []
	for array in arrays:
		if array.size() > maxSize:
			maxSize = array.size()
			result = array
	return result

## Return the [param biggest] set of indices as a map sized array of bools.
func map_biggest(biggest: Array) -> Array[bool]:
	var map: Array[bool] = []
	for i in _count:
		map.append(i not in biggest)
	# if OS.is_debug_build():
	# 	print("mapBiggest")
	# 	_print(map)
	return map

## Return a combination of [param grid_1] and [param grid_2].
func combine(grid_1: Array[bool], grid_2: Array[bool]) -> Array[bool]:
	var result: Array[bool] = []
	for i in _count:
		result.append(grid_1[i] and grid_2[i])
	# if OS.is_debug_build():
	# 	print("combine")
	# 	_print(result)
	return result

## Print [param grid] to the console.
## See [method Utility.flatten].
func _print(grid: Array[bool]) -> void:
	var output := ""
	for y in _height:
		for x in _width:
			output += "1" if grid[Utility.flatten(Vector2i(x, y), _width)] else "0"
		output += "\n"
	output += "\r"
	print(output)
