extends Node
class_name CommandQueue

var _list: Array
var index := -1
signal changed

func execute(c: Command) -> void:
	if not c: return
	if not _atEnd():
		_list.resize(index)
	_list.append(c)
	index += 1
	c.execute()
	emit_signal("changed")

func undo() -> void:
	if index > 0:
		_list[index].undo()
		index -= 1
		emit_signal("changed")

func redo() -> void:
	if index < _list.size():
		_list[index].redo()
		index += 1
		emit_signal("changed")

func _atEnd() -> bool:
	return index + 1 == _list.size()

var _i: int

func should_continue():
	return (_i < _list.size())

func _iter_init(_arg):
	_i = 0
	return should_continue()

func _iter_next(_arg):
	_i += 1
	return should_continue()

func _iter_get(_arg):
	return _list[_i]
