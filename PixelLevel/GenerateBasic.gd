extends Generate
class_name GenerateBasic

func _init(level: Level) -> void:
	super(level)

func generate(delta: int = 1) -> void:
	super.generate(delta)
	_fill(false, Random.next_bool())
	_stairs()
	if not _cliff and _stream:
		_generate_streams()
	_level.generated()
