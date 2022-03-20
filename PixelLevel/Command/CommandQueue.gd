extends Node
class_name CommandQueue

var list: Array

func queue(c: Command) -> void:
	list.append(c)

func execute() -> void:
	pass

func undo() -> void:
	pass

func redo() -> void:
	pass
