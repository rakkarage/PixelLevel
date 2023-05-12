extends Node

@onready var _bump: AudioStreamPlayer = $Bump
@onready var _click: AudioStreamPlayer = $Click
@onready var _error: AudioStreamPlayer = $Error
@onready var _success: AudioStreamPlayer = $Success

func bump() -> void:
	_bump.play()

func click() -> void:
	_click.play()

func error() -> void:
	_error.play()

func success() -> void:
	_success.play()
