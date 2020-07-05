extends Object
class_name DisjointSet

var _parent : Array

func _init(count: int) -> void:
	_parent = Utility.repeat(-1, count)

func find(i: int) -> int:
	if _parent[i] < 0:
		return i
	else:
		var parent := find(_parent[i])
		_parent[i] = parent
		return parent

func union(i: int, j: int) -> void:
	var pi = find(i)
	var pj = find(j)
	if pi < pj:
		_parent[pi] -= 1
		_parent[pj] = pi
	elif pi > pj:
		_parent[pi] = pj
		_parent[pj] -= 1

func split(list: Array) -> Dictionary:
	var groups : Dictionary = {}
	for i in range(_parent.size()):
		if list[i]:
			var root := find(i)
			if not groups.keys().find(root):
				groups[root] = []
			groups[root].append(i)
	return groups
