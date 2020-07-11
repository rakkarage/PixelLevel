extends Generate
class_name GenerateBasic

func _init(level: Level).(level) -> void: pass

func generate() -> void:
	.generate()
	assert(_level != null)
	_fill(false, Random.nextBool())
	_stairs()
	if _stream:
		_generateStreams()
	_level.generated()
