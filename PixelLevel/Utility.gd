extends Object
class_name Utility

static func stfu(_ignore) -> void: pass

static func indexV(position: Vector2, width: int) -> int:
	return index(int(position.x), int(position.y), width)

static func index(x: int, y: int, width: int) -> int:
	return int(y * width + x)

static func position(index: int, width: int) -> Vector2:
	var y := int(index / float(width))
	var x := int(index - width * y)
	return Vector2(x, y)

static func range(value: int, count: int) -> Array:
	var array := []
	for i in range(count):
		array.append(value + i)
	return array

static func repeat(value, count: int) -> Array:
	var array := []
	for _i in range(count):
		array.append(value)
	return array

static func listFiles(path: String) -> Array:
	var list := []
	var dir := DirAccess.open(path)
	if dir && dir.list_dir_begin() == OK: # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var file := dir.get_next()
		while file != "":
			var newPath := path + "/" + file
			if dir.current_is_dir():
				list += listFiles(newPath)
			elif !file.begins_with(".") and !file.ends_with(".godot"):
				list.append(newPath)
			file = dir.get_next()
	return list
