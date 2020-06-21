extends Node

onready var _textureRect : TextureRect = $Fore/Viewport/MiniMap
onready var _level : Level = $Level/Viewport
onready var _imageTexture := ImageTexture.new()
onready var _image := Image.new()
const _max := Vector2(64, 64)

# TODO: handle resize!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

func _ready() -> void:
	_textureRect.texture = _imageTexture
	print(_image.get_size())
	_update(Vector2.ZERO)

func _update(at: Vector2) -> void:
	var original := _level.getMapRect().size
	var size := original
	var offset := Vector2.ZERO
	if size.x > _max.x:
		size.x = _max.x
		offset.x = at.x - size.x / 2.0
		if offset.x < 0: offset.x = 0
		if offset.x > original.x - size.x: offset.x = original.x - size.x
	if size.y > _max.y:
		size.y = _max.y
		offset.y = at.y - size.y / 2.0
		if offset.y < 0: offset.y = 0
		if offset.y > original.y - size.y: offset.y = original.y - size.y
	# TODO: draw screen from bounds!!!!!!!!!!!!!!!!!!!!!!!!!!!
	# var bounds = _level.mapBounds()
	var screen = false
	_image.create(int(size.x), int(size.y), false, Image.FORMAT_RGB8)
	_image.lock()
	for y in range(size.y):
		for x in range(size.x):
			var actualX = x + offset.x
			var actualY = y + offset.y
			_image.set_pixel(x, y, _level.getMapColor(actualX, actualY, screen))
	_image.unlock()
	_image.expand_x2_hq2x()
	_image.expand_x2_hq2x()
	_imageTexture.create_from_image(_image)

# public Texture2D GetMiniMap(Vector2 center)
# {
# 	var tileMap = Manager.Instance.TileMap;
# 	var oWidth = tileMap.State.Width;
# 	var oHeight = tileMap.State.Height;
# 	var width = oWidth;
# 	var height = oHeight;
# 	var offsetX = 0;
# 	var offsetY = 0;
# 	if (width > _max)
# 	{
# 		width = _max;
# 		var halfWidth = width / 2;
# 		offsetX = (int)center.x - halfWidth;
# 		if (offsetX < 0) offsetX = 0;
# 		if (offsetX > oWidth - width) offsetX = oWidth - width;
# 	}
# 	if (height > _max)
# 	{
# 		height = _max;
# 		var halfHeight = height / 2;
# 		offsetY = (int)center.y - halfHeight;
# 		if (offsetY < 0) offsetY = 0;
# 		if (offsetY > oHeight - height) offsetY = oHeight - height;
# 	}
# 	var bounds = Manager.Instance.GameCamera.OrthographicBounds();
# 	var minX = Mathf.RoundToInt(bounds.min.x);
# 	var maxX = Mathf.RoundToInt(bounds.max.x);
# 	var minY = Mathf.RoundToInt(bounds.min.y);
# 	var maxY = Mathf.RoundToInt(bounds.max.y);
# 	var texture = new Texture2D(width, height, TextureFormat.RGBA32, false);
# 	for (var y = 0; y < height; y++)
# 	{
# 		for (var x = 0; x < width; x++)
# 		{
# 			var actualX = x + offsetX;
# 			var actualY = y + offsetY;
# 			var p = new Vector2(actualX, actualY);
# 			var character = Manager.Instance.Character.At(p);
# 			var screen =
# 				(
# 					((actualX >= minX) && (actualX <= maxX)) &&
# 					((actualY == minY) || (actualY == maxY))
# 				) ||
# 				(
# 					((actualY >= minY) && (actualY <= maxY)) &&
# 					((actualX == minX) || (actualX == maxX))
# 				);
# 			var color = character ? Colors.GreenLight :
# 				tileMap.GetMapColor(actualX, actualY, screen);
# 			texture.SetPixel(x, y, color);
# 		}
# 	}
# 	texture.filterMode = FilterMode.Point;
# 	texture.Apply();
# 	return texture;
# }
# public static Bounds OrthographicBounds(this Camera camera)
# {
# 	var ratio = (float)Screen.width / (float)Screen.height;
# 	var height = camera.orthographicSize * 2f;
# 	var p = camera.transform.localPosition;
# 	return new Bounds(new Vector3(p.x, p.y, 0f), new Vector3(height * ratio, height, 2f));
# }
