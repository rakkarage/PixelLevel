class_name Command

var _mob: Mob

func _init(mob: Mob) -> void:
	_mob = mob

func execute() -> void: pass

func undo() -> void: pass

func redo() -> void: pass
