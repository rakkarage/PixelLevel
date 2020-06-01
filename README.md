# PixelLevel

Pixel-perfect dungeon and environment sprites.

- <https://godotmarketplace.com/publisher/henry-software/>
- <https://bitbucket.org/rakkarage/pixellevel/issues>

## Tilemap Animation Shader Description

Animates an atlas in a cycle offset by frame so each instance is not, necessarily, in sync. Can select priority paint to let godot tilemap editor pick a random tile animation for you.

uniform

- frames: eg. 6
- frameDuration: eg. 0.25 (4 fps)
- frameWidth: eg. 0.034482759 (1 / 29)

fragment

- calculate currentFrame
  - calculate animationDuration by multiplying frames by frameDuration
  - mod time by animationDuration and divide by frameDuration and floor to get currentFrame
- calculate offsetFrame
  - divide uv by frameWidth and floor to get offsetFrame
- calculate actualFrame
  - add current frame and offset frame and mod by frames to get actualFrame
- offset uv to actualFrame
  - uv = uv + ((actualFrame - offsetFrame) * frameWidth)
