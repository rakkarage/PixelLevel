## Disjoint Set
## A data structure that keeps track of a set of elements partitioned into a number of disjoint (non-overlapping) subsets.
## [method split] can be used to split the DisjointSet into separate sets.
extends Object
class_name DisjointSet

const _initialRank := 0
const _increment := 1

var _parent: Array[int] = []
var _rank: Array[int] = []
var _width: int
var _height: int
var _count: int

## Initializes the DisjointSet with the specified [param count] of nodes and [param width] of the grid.
## If [param map] is provided, calls [method union] only for connected 'floor' nodes.
## Otherwise, calls [method make_set] for each node.
func _init(width: int, height: int, map: Array[bool] = []) -> void:
	_width = width
	_height = height
	_count = _width * _height
	_parent.resize(_count)
	_rank.resize(_count)
	for i in _count:
		make_set(i)
	if map.size() == _count:
		for i in _count:
			if map[i]:
				continue
			var position := Utility.unflatten(i, _width)
			for x in range(-1, 2):
				for y in range(-1, 2):
					var neighbor := Vector2i(position.x + x, position.y + y)
					if x == 0 and y == 0:
						continue
					elif neighbor.x < 0 or neighbor.x >= _width or neighbor.y < 0 or neighbor.y >= _height:
						continue
					var neighborIndex := Utility.flatten(neighbor, _width)
					if not map[neighborIndex]:
						union(i, neighborIndex)

## Creates a new set with the given [param node].
## Sets the parent of the node to itself and the rank to 0.
func make_set(node: int) -> void:
	_parent[node] = node
	_rank[node] = _initialRank

## Finds and returns the root of the set that the given [param node] belongs to.
## Performs path compression to optimize future find operations.
func find(node: int) -> int:
	var path := [] # list to store the nodes in the path to the root
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
	var root1 := find(node1) # find the root of the set that node1 belongs to
	var root2 := find(node2) # find the root of the set that node2 belongs to
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
	var sets: Array[Array] = [] # list to store the sets
	var roots: Array[int] = [] # list to store the roots of each node
	for i in _parent.size():
		var root := find(i) # find the root of the set that i belongs to
		if root == i: # if just a single node, skip
			continue
		if not roots.has(root):
			roots.append(root) # add the root to the list of roots
			sets.append([]) # create a new set for the root
		sets[roots.find(root)].append(i) # add i to the set with the same root
	return sets # return a list of the sets
