extends Sprite

onready var _tree: AnimationTree = $AnimationTree
onready var _machine: AnimationNodeStateMachinePlayback = _tree.get("parameters/playback")
const _key := "parameters/Idle/BlendSpace1D/blend_position"
const _idleAnimationPriority := {
	-1: 100,
	0: 20,
	1: 1
}

func _ready():
	idle()

func randomIdle() -> void:
	_tree[_key] = Random.priority(_idleAnimationPriority)

func idle():
	_machine.start("Idle")

func walk():
	_machine.start("Walk")

func attack():
	_machine.start("Attack")
