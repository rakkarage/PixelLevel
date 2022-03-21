extends Command
class_name CommandGroup

var _list: Array

func _init(mob: Mob, list: Array).(mob) -> void:
	_list = list

func _execute() -> void:
	for i in _list:
		i.execute()

func _undo() -> void:
	for i in _list:
		i.undo()

func _redo() -> void:
	for i in _list:
		i.redo()
