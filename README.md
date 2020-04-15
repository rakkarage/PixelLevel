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
  - calculate the uv width of a frame by divide 1 / frames
  - subtract start from uv then divide by step then ceil to get offset frame
- calculate actual frame
  - add current frame and offset frame and mod by frames to get actual frame
- calculate uv
  - uv - (offset frame \* step) to reset to 'start' then + (actual frame \* step) to offset to real frame

wtf

- TODO: don't need to mult twice!? do it after add!!!
- TODO: there is a better way to calc this? it could be a constant!? like start?
- but it does not work when i make it a constant vector .6555, .0345, 0? like uv?
- both problems solved by constant start?
- but it does not work when i make it a constant vector .6555, .0345, 0? like uv?
- start was passed in? use it instead of calculating start each pixel you dolt!?
- no i guess it is not constant? it is the tile start pixel start not?
- but it shakes and wobbles!? have to do something...
- test it with smaller numbers to see if shader rounding errors!!!
  
frame width = image size / frames?

- calculate frame
  - calculate the length of a frame by dividing 1 by the fps
  - calculate the length of the animation by multiplying frames by length
  - mod time by animation length and divide by frame length then ceil to get current frame
- calculate offset frame
  - subtract start from uv then divide by step then ceil to get offset frame
- calculate actual frame
  - add current frame and offset frame and mod by frames to get actual frame
- calculate uv
  - uv - (offset frame \* step) to reset to 'start' then + (actual frame \* step) to offset to real frame
