extends Generate
class_name GenerateBasic

func _init(level: LevelBase) -> void:
	super(level)

func generate(delta: int = 1) -> void:
	super.generate(delta)
	_fill(false, Random.nextBool())
	_stairs()
	if _stream:
		_generateStreams()
	_level.generated()
