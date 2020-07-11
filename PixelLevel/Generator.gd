extends Node

onready var _level : Level = $Viewport
onready var _generators := $Generate.get_children()

var _g := {}

# TODO: if all generate have class_name then can use that to instance
# with no nodes? just objects? no hierarchy no get children just new?
func _ready() -> void:
	Utility.ok(_level.connect("generate", self, "_generate"))
	for i in _generators:
		i.setup(_level)
		_g[funcref(i, "generate")] = i.priority

func _generate() -> void:
	Random.priority(_g).call_func()
