## Disjoint Set
## A data structure that keeps track of a set of elements partitioned into a number of disjoint (non-overlapping) subsets.
## [method split] can be used to split the DisjointSet into separate sets.
extends Object
class_name DisjointSet

const _initialRank := 0 ## the initial rank of each node
const _increment := 1 ## the amount to increment the rank of a set when merging

var _parent: Array[int] = [] ## list to store the parent of each node
var _rank: Array[int] = [] ## list to store the rank of each node
var _count: int ## the number of nodes in the DisjointSet
var _width: int ## the width of the grid
var _height: int ## the width of the grid

## Initializes the DisjointSet with the specified [param count] of nodes and [param width] of the grid.
## Sets up the parent and rank lists and calls make_set for each node.
## If [param map] is provided, calls make_set only for 'floor' nodes.
func _init(width: int, height: int, map: Array[bool] = []) -> void:
	_count = width * height
	_width = width
	_height = height
	_parent.resize(_count)
	_rank.resize(_count)
	if map.size() == _count:
		for i in _count:
			if not map[i]:
				make_set(i)
	else:
		for i in _count:
			make_set(i)

## Creates a new set with the given [param node].
## Sets the parent of the node to itself and the rank to 0.
func make_set(node: int) -> void:
	_parent[node] = node # set the parent of the node to itself
	_rank[node] = _initialRank # set the rank of the node to 0

## Finds and returns the root of the set that the given [param node] belongs to.
## Performs path compression to optimize future find operations.
func find(node: int) -> int:
	var path := [] ## list to store the nodes in the path to the root
	while _parent[node] != node: # while the node is not its own parent (i.e., not the root)
		path.append(node) # add the node to the path
		node = _parent[node] # move up to the parent
	for p in path: # for each node in the path
		_parent[p] = node # set its parent to the root
	return node

## Unites the sets that contain the given [param node1] and [param node2].
## Finds the roots of both nodes and merges the smaller set into the larger set.
## Updates the parent and rank lists accordingly.
func union(node1: int, node2: int) -> void:
	var root1 := find(node1) ## find the root of the set that node1 belongs to
	var root2 := find(node2) ## find the root of the set that node2 belongs to
	if root1 != root2: # if the roots are different, the sets are not already merged
		if _rank[root1] > _rank[root2]: # merge the smaller set into the larger set
			_parent[root2] = root1
		else:
			_parent[root1] = root2
			if _rank[root1] == _rank[root2]: # if the ranks are equal, increment the rank of the new root
				_rank[root2] += _increment

## Splits the DisjointSet into separate sets and returns them.
## Iterates through each node, finds its root, and assigns nodes with the same root to the same set.
## Returns a list of sets, where each set is represented as a list of nodes.
func split() -> Array[Array]:
	var sets: Array[Array] = [] ## list to store the sets
	var roots: Array[int] = [] ## list to store the roots of each node
	for i in _parent.size():
		var root := find(i) ## find the root of the set that i belongs to
		if not roots.has(root):
			roots.append(root) # add the root to the list of roots
			sets.append([]) # create a new set for the root
		sets[roots.find(root)].append(i) # add i to the set with the same root
	return sets # return a list of the sets
