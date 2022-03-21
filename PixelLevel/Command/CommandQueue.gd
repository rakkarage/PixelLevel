extends Node
class_name CommandQueue

var _list: Array
var _index := 0
signal changed

func execute(c: Command) -> void:
	if not c: return
	if not _atEnd():
		_list.resize(_index)
	_list.append(c)
	_index += 1
	c.execute()
	emit_signal("changed")

func undo() -> void:
	if _index > 0:
		_list[_index].undo()
		_index -= 1
		emit_signal("changed")

func redo() -> void:
	if _index < _list.size():
		_list[_index].redo()
		_index += 1
		emit_signal("changed")

func _atEnd() -> bool:
	return _index + 1 == _list.size()

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
