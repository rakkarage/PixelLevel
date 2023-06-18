## Cellular automaton generator.
## This script is used to generate a 2D grid of boolean values using a cellular automaton algorithm.
## Intended for creating caves, forests, patches of grass or flowers, or lakes.
## I use 1 (alive/true) for wall and 0 (dead/false) for floor, but you can use whatever you want.
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

const _steps := 10 ## Default number of steps to simulate. Randomized.
const _chance := 0.2 ## Default half offset chance of a cell being alive at the start.
const _birth := 4 ## Default number of neighbors required for a dead cell to become alive.
const _death := 3 ## Default number of neighbors required for a live cell to die.

var _width := 0
var _height := 0
var _count := 0

## Initialize the generator with the specified [param width] and [param height] of the grid.
func _init(width: int, height: int) -> void:
	_width = width
	_height = height
	_count = width * height

## Generate a 2D grid of boolean values using a cellular automaton algorithm.
## [param width] and [param height] define the size of the grid.
## [param steps] defines the number of steps to simulate.
## [param chance] defines the chance of a cell being alive at the start.
## [param birth] defines the number of neighbors required for a dead cell to become alive.
## [param death] defines the number of neighbors required for a live cell to die.
## Return the generated grid.
## See [method simulate], [method Random.next], [method Random.nextFloat].
func generate(steps := Random.next(_steps), chance := Random.nextRangeFloat(0.5 - _chance, 0.5 + _chance), birth := _birth, death := _death) -> Array[bool]:
	if _width <= 0 or _height <= 0:
		return []
	var grid: Array[bool] = []
	for i in _count:
		grid.append(Random.nextFloat() < chance)
	for i in steps:
		grid = _simulate(grid, birth, death)
	if OS.is_debug_build():
		print("Steps: ", steps, ", Chance: ", chance, ", Birth: ", birth, ", Death: ", death)
		_print(grid)
	return grid

## Simulate a single step of a cellular automaton algorithm.
## [param oldGrid] defines the grid to simulate.
## [param width] and [param height] define the size of the grid.
## [param birth] defines the number of neighbors required for a dead cell to become alive.
## [param death] defines the number of neighbors required for a live cell to die.
## Return the simulated grid.
## See [method _count], [method Utility.unflatten].
func _simulate(oldGrid: Array[bool], birth: int, death: int) -> Array[bool]:
	var grid: Array[bool] = []
	for i in _count:
		var position := Utility.unflatten(i, _width)
		var count := _countNeighbors(oldGrid, position)
		grid.append((oldGrid[i] and count >= death) or (not oldGrid[i] and count > birth))
	return grid

## Count the number of live neighbors of a cell.
## [param map] defines the grid to count neighbors in.
## [param p] define the position of the cell.
## [param width] and [param height] define the size of the grid.
## Return the number of live neighbors.
## See [method Utility.flatten].
func _countNeighbors(grid: Array[bool], position: Vector2i) -> int:
	var count := 0
	for i in range(-1, 2):
		for j in range(-1, 2):
			var neighbor_x := position.x + i
			var neighbor_y := position.y + j
			if i == 0 and j == 0:
				continue
			elif neighbor_x < 0 or neighbor_y < 0 or neighbor_x >= _width or neighbor_y >= _height:
				count += 1
			elif grid[Utility.flatten(Vector2i(neighbor_x, neighbor_y), _width)]:
				count += 1
	return count

## [param grid] defines the grid to check.
## [param width] and [param height] define the size of the grid.
## Return the biggest `floor` set as array of indices so can check size etc.
## See [class DisjointSet], [method Utility.flatten], [method Utility.unflatten].
func findBiggest(grid: Array[bool]) -> Array:
	var disjointSet := DisjointSet.new(_width, _height, grid)
	var arrays := disjointSet.split()
	if arrays.size() == 0: return []
	if arrays.size() == 1: return arrays[0]
	var maxSize := 0
	var result := []
	for array in arrays:
		if array.size() > maxSize:
			maxSize = array.size()
			result = array
	return result

## [param biggest] defines the set of indices to map to a grid
## [param width] and [param height] define the size of the grid.
## Returns map sized array of bools so can replace old grid with biggest etc.
func mapBiggest(biggest: Array) -> Array[bool]:
	var map: Array[bool] = []
	for i in _count:
		map.append(i not in biggest)
	if OS.is_debug_build():
		print("mapBiggest")
		_print(map)
	return map

## [param array1] and [param array2] define the grids to combine.
## [param width] and [param height] define the size of the grids.
## Return the combined grid.
func combine(array1: Array[bool], array2: Array[bool]) -> Array[bool]:
	var result: Array[bool] = []
	for i in _count:
		result.append(array1[i] and array2[i])
	if OS.is_debug_build():
		print("combine")
		_print(result)
	return result

## Print a grid to the console.
## The [param grid] parameter defines the grid to print.
## The [param width] and [param height] parameters define the size of the grid.
## See [method Utility.flatten].
func _print(grid: Array[bool]) -> void:
	var output := ""
	for y in _height:
		for x in _width:
			output += "1" if grid[Utility.flatten(Vector2i(x, y), _width)] else "0"
		output += "\n"
	output += "\r"
	print(output)
