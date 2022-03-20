extends Node
class_name CommandQueue

var _list: Array
var _index: int = 0
signal changed

func execute(c: Command) -> void:
	if not c: return
	if not _atEnd():
		_list.resize(_index)
	_list.append(c)
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
	return _list.size() == _index
