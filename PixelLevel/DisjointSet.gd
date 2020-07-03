extends Object
class_name DisjointSet

var _parent : PoolIntArray
var _rank : PoolIntArray

func _init(count: int) -> void:
	_parent = _range(0, count)
	_rank = _repeat(0, count)

func find(i: int) -> int:
	if _parent[i] == i:
		return i
	else:
		var result := find(_parent[i])
		_parent[i] = result
		return result

func union(i: int, j: int) -> void:
	var fi = find(i)
	var fj = find(j)
	var ri = _rank[fi]
	var rj = _rank[fj]
	if fi == fj: return
	if ri < rj: _parent[fi] = fj
	elif ri > rj: _parent[fj] = fi
	else:
		_parent[fj] = fi
		_rank[fi] += 1

func split(list: PoolIntArray) -> Dictionary:
	var groups : Dictionary = {}
	for i in range(_parent.size()):
		if list[i]:
			var root := find(i)
			if not groups.keys().find(root):
				groups[root] = []
			groups[root].append(i)
	return groups

static func _range(value: int, count: int) -> PoolIntArray:
	var array : PoolIntArray = []
	for i in range(count):
		array.append(value + i)
	return array

static func _repeat(value: int, count: int) -> PoolIntArray:
	var array : PoolIntArray = []
	for _i in range(count):
		array.append(value)
	return array
