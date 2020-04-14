# PixelLevel

Pixel-perfect dungeon and environment sprites.

- <https://godotmarketplace.com/publisher/henry-software/>
- <https://bitbucket.org/henrysoftware/pixellevel/issues>

## TODO

- random rotation and flip tiles?
- random tile animation start frame? offset time?
  - you dont need offset if you use the offset built into atlas tiles!!!

step: .0345
start: .6555

test uv 0: .6555
test uv 1: .6555+.0345 = .69
test uv 2: .6555+.0345+.0345 = .7245

uv 0 - start = 0
(uv 1 - start) / step = 1
(uv 2 - start) / step = 2

now i know step how can i use that to fix anim offset?
offset it backwards no then they would all be the same...
just need to wrap it with mod!!!

wrap what?

once you know offset use it to make a uv from start instead of current!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

if on frame 0 and offset is 0 then 0
if on frame 1 and offset is 0 then 1
...
if on frame 5 and offset is 0 then 5

if on frame 0 and offset is 1 then 1
if on frame 1 and offset is 1 then 2
...
if on frame 5 and offset is 1 then 0

so need to add and then modulate!?!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
then start from start instead of current!



woo!

and add params
start, step

uv 0: frame 0: 0
uv 1: frame 0: 1
