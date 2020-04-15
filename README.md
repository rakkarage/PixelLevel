# PixelLevel

Pixel-perfect dungeon and environment sprites.

- <https://godotmarketplace.com/publisher/henry-software/>
- <https://bitbucket.org/henrysoftware/pixellevel/issues>

## Shader Description

uniform

- frames: how many frames
- fps: how many frames to show per second
- start: where the first frame starts (X) (eg. 0.6555)
- step: how big each frame (eg. 16 pixels or 0.0345)

fragment

- calculate frame
  - calculate the length of a frame by dividing 1 by the fps
  - calculate the length of the animation by multiplying frames by length
  - mod time by animation length and divide by frame length then ceil to get current frame
- calculate offset frame
  - subtract start from uv then divide by step then ceil to get offset frame
- add current frame and offset frame and mod by frames to get actual frame
- calculate uv
  - uv - (current frame \* step) + (actual frame \* step)
