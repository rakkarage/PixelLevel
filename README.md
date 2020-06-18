# PixelLevel

Pixel-perfect dungeon and environment sprites.

- <https://godotmarketplace.com/publisher/henry-software/>
- <https://bitbucket.org/rakkarage/pixellevel/issues>
- <https://github.com/rakkarage/pixellevel/issues>

## Submodules

To include submodules, clone with the --recursive flag:

`git clone --recursive https://bitbucket.org/rakkarage/PixelLevel.git`

or download a zip from bitbucket (bitbucket-pipelines.yml) which includes all submodules.

<https://bitbucket.org/rakkarage/pixellevel/downloads/>

## Tilemap Animation Shader Description

Animates an atlas in a cycle offset by frame so each instance is not, necessarily, in sync. Can select priority paint to let godot tilemap editor pick a random tile animation for you.

uniform

- frames: eg. 6
- frameDuration: eg. 0.25 (4 fps)
- frameWidth: eg. 0.034482759 (1 / 29)
- startX: eg. 0.5

fragment

- calculate currentFrame
  - calculate animationDuration by multiplying frames by frameDuration
  - mod time by animationDuration and divide by frameDuration and floor to get currentFrame
- calculate offsetFrame
  - divide uv.x - startX by frameWidth and floor to get offsetFrame
- calculate actualFrame
  - add current frame and offset frame and mod by frames to get actualFrame
- offset uv to actualFrame
  - uv = uv + ((actualFrame - offsetFrame) * frameWidth)

## TODO

- need to fix mob animation states!? and use walk animation
- level generation and loading tmx
