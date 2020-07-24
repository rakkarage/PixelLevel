extends Control

onready var _attack := $Panel/HBox/Attack
onready var _walk := $Panel/HBox/Walk
onready var _turn := $Panel/HBox/Turn
onready var _mob := $Slime

func _ready() -> void:
	Utility.ok(_attack.connect("pressed", self, "_attackPressed"))
	Utility.ok(_walk.connect("pressed", self, "_walkPressed"))
	Utility.ok(_turn.connect("pressed", self, "_turnPressed"))

func _attackPressed() -> void:
	_mob.attack()

func _walkPressed() -> void:
	_mob.walk()

func _turnPressed() -> void:
	_mob.flip_h = not _mob.flip_h
