extends Node

onready var _level : Level = $Viewport
onready var _generators := $Generate.get_children()

var _g := {}

func _ready() -> void:
	Utility.ok(_level.connect("generate", self, "_generate"))
	for i in _generators:
		i.setup(_level)
		_g[funcref(i, "generate")] = i.priority

func _generate() -> void:
	Utility.priority(_g).call_func()

# func _generateTemplate() -> void:
# 	_fill(false, true)
# 	if _stream:
# 		_generateStreams()
# 	_stairs()
# 	_level.generated()

# func _generateTemplateCrossroad() -> void:
# 	_fill(false, true)
# 	if _stream:
# 		_generateStreams()
# 	_stairs()
# 	_level.generated()

# func _generateTemplateCastle() -> void:
# 	_fill(false, true)
# 	if _stream:
# 		_generateStreams()
# 	_stairs()
# 	_level.generated()

