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
extends Node
class_name CellularAutomaton

const _steps := 10 ## Default number of steps to simulate. Randomized.
const _chance := 0.2 ## Default half offset chance of a cell being alive at the start.
const _birth := 4 ## Default number of neighbors required for a dead cell to become alive.
const _death := 3 ## Default number of neighbors required for a live cell to die.

## Generate a 2D grid of boolean values using a cellular automaton algorithm.
## The size of the grid is defined by the [param width] and [param height].
## The [param steps] parameter defines the number of steps to simulate.
## The [param chance] parameter defines the chance of a cell being alive at the start.
## The [param birth] parameter defines the number of neighbors required for a dead cell to become alive.
## The [param death] parameter defines the number of neighbors required for a live cell to die.
## Return the generated grid.
## See [method simulate], [method Random.next], [method Random.nextFloat].
static func generate(width: int, height: int, steps := Random.next(_steps), chance := Random.nextRangeFloat(0.5 - _chance, 0.5 + _chance), birth := _birth, death := _death) -> Array[bool]:
	if width <= 0 or height <= 0:
		return []
	var grid: Array[bool] = []
	for i in width * height:
		grid.append(Random.nextFloat() < chance)
	for i in steps:
		grid = CellularAutomaton._simulate(grid, width, height, birth, death)
	if OS.is_debug_build():
		print("Steps: ", steps, ", Chance: ", chance, ", Birth: ", birth, ", Death: ", death)
		CellularAutomaton._print(grid, width, height)
	return grid

## Simulate a single step of a cellular automaton algorithm.
## The [param oldGrid] parameter defines the grid to simulate.
## The [param width] and [param height] parameters define the size of the grid.
## The [param birth] parameter defines the number of neighbors required for a dead cell to become alive.
## The [param death] parameter defines the number of neighbors required for a live cell to die.
## Return the simulated grid.
## See [method _count], [method Utility.unflatten].
static func _simulate(oldGrid: Array[bool], width: int, height: int, birth: int, death: int) -> Array[bool]:
	var grid: Array[bool] = []
	for i in width * height:
		var position := Utility.unflatten(i, width)
		var count := CellularAutomaton._count(oldGrid, position.x, position.y, width, height)
		grid.append((oldGrid[i] and count >= death) or (not oldGrid[i] and count > birth))
	return grid

## Count the number of live neighbors of a cell.
## The [param map] parameter defines the grid to count neighbors in.
## The [param x] and [param y] parameters define the position of the cell.
## The [param width] and [param height] parameters define the size of the grid.
## Return the number of live neighbors.
## See [method Utility.flatten].
static func _count(grid: Array[bool], x: int, y: int, width: int, height: int) -> int:
	var count := 0
	for i in range(-1, 2):
		for j in range(-1, 2):
			var neighbor_x := x + i
			var neighbor_y := y + j
			if i == 0 and j == 0:
				continue
			elif neighbor_x < 0 or neighbor_y < 0 or neighbor_x >= width or neighbor_y >= height:
				count += 1
			elif grid[Utility.flatten(Vector2i(neighbor_x, neighbor_y), width)]:
				count += 1
	return count

## Print a grid to the console.
## The [param grid] parameter defines the grid to print.
## The [param width] and [param height] parameters define the size of the grid.
## See [method Utility.flatten].
static func _print(grid: Array[bool], width, height) -> void:
	var output := ""
	for y in height:
		for x in width:
			output += "1" if grid[Utility.flatten(Vector2i(x, y), width)] else "0"
		output += "\n"
	output += "\r"
	print(output)
