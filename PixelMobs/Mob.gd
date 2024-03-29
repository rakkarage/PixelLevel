class_name Mob
extends Sprite2D

@onready var _tree: AnimationTree = $Tree
@onready var _machine: AnimationNodeStateMachinePlayback = _tree.get("parameters/playback")
const _key := "parameters/Idle/blend_position"
const _idleAnimationPriority := {
	-1: 100,
	0: 20,
	1: 1
}

func _ready():
	_machine.start("Idle")

func randomIdle() -> void:
	_tree[_key] = Random.probability(_idleAnimationPriority)

func idle():
	_machine.travel("Idle")

func walk():
	_machine.travel("Walk")

func attack():
	_machine.travel("Attack")
