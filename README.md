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

### Lighting

Lighting combines these two algorithms using sets of 32 gradient light tiles.

- <http://www.roguebasin.com/index.php?title=FOV_using_recursive_shadowcasting>
- <https://web.archive.org/web/20120626205857/http://doryen.eptalys.net/2011/03/ramblings-on-lights-in-full-color-roguelikes/>

## TODO

- test and fix light!!!!!!!!!!!!!!!!!
  - test without fog of war / explored
  - draw numbers on light tiles again to verify
- make base that does not know about Tiles.Light etc and extend it so less code per file and more expandable!?
- need to fix mob animation states!? and use walk animation
- level generation and loading tmx
