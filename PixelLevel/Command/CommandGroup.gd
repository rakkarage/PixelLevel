extends Command
class_name CommandGroup

var _list: Array

func _init(list: Array) -> void:
	_list = list

func execute() -> void:
	for i in _list:
		i.execute()

func undo() -> void:
	for i in _list:
		i.undo()

func redo() -> void:
	for i in _list:
		i.redo()
