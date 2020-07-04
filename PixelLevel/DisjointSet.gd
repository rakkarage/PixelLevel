extends Object
class_name DisjointSet

var _parent : Array
var _rank : Array

func _init(count: int) -> void:
	_parent = Utility.range(0, count)
	_rank = Utility.repeat(0, count)

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

# TODO: test and fix! using _parent instead of list? wtf?
# does this need to be in here?
func split(list: Array) -> Dictionary:
	var groups : Dictionary = {}
	for i in range(_parent.size()):
		if list[i]:
			var root := find(i)
			if not groups.keys().find(root):
				groups[root] = []
			groups[root].append(i)
	return groups
