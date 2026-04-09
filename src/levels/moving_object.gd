class_name MovingObject
extends Node3D

const XRConvUtils = preload("res://src/xrconv/utils.gd")

const SPEED := 15.0
const MAX_Z := 30.0


func _process(p_delta: float) -> void:
	if not GameState.running:
		return

	var parent = get_parent()
	if not parent or not parent is Node3D:
		return

	if XRConvUtils.get_relative_position(parent, GameState.current_level).z > MAX_Z:
		parent.queue_free()
		return

	parent.position.z += SPEED * p_delta
