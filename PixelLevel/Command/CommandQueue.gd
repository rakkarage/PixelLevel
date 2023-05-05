extends Node
class_name CommandQueue

var _list: Array
var index := -1
signal changed

func execute(c: Command) -> void:
	if not c: return
	c.execute()
	if not c.valid: return
	if index < _list.size():
		_list.resize(index + 1)
	_list.append(c)
	index += 1
	emit_signal("changed")

func undo() -> void:
	if index + 1 > 0:
		_list[index].undo()
		index -= 1
		emit_signal("changed")

func redo() -> void:
	if index + 1 < _list.size():
		index += 1
		_list[index].redo()
		emit_signal("changed")

#region iterator

var _i := 0

func _continue():
	return _i < _list.size()

func _iter_init(_what):
	_i = 0
	return _continue()

func _iter_next(_the):
	_i += 1
	return _continue()

func _iter_get(_fuck):
	return _list[_i]

#endregion
