extends Store

func _init() -> void:
	_default = {
		"main": { "depth": 0, "position": Vector2i(0, 0), "time": 0.0, "turns": 0, "width": 0, "height": 0 },
		"level": { }
	}
	super._init()
