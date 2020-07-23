extends Control

onready var _attack := $Panel/HBox/Attack
onready var _walk := $Panel/HBox/Walk
onready var _turn := $Panel/HBox/Turn
onready var _sprite := $Sprite
onready var _player: AnimationPlayer = $Sprite/AnimationPlayer
onready var _tree: AnimationTree = $Sprite/AnimationTree
onready var _machine: AnimationNodeStateMachinePlayback = _tree.get("parameters/playback")

func _ready() -> void:
	_machine.start("Idle")
	Utility.ok(_attack.connect("pressed", self, "_attackPressed"))
	Utility.ok(_walk.connect("pressed", self, "_walkPressed"))
	Utility.ok(_turn.connect("pressed", self, "_turnPressed"))

func _attackPressed() -> void:
	_machine.travel("Attack")

func _walkPressed() -> void:
	_machine.travel("Walk")

func _turnPressed() -> void:
	_sprite.scale = Vector2(-_sprite.scale.x, _sprite.scale.y)

const _key := "parameters/Idle/BlendSpace1D/blend_position"

func _randomIdle() -> void:
	_tree[_key] = -1.0 + Random.next(3)
