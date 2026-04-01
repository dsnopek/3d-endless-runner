class_name MovingObject
extends Node3D

const SPEED := 15.0
const MAX_Z := 30.0


func _process(p_delta: float) -> void:
	if not GameState.running:
		return

	var parent = get_parent()
	if not parent or not parent is Node3D:
		return

	if parent.global_transform.origin.z > MAX_Z:
		parent.queue_free()
		return

	parent.global_translate(Vector3(0.0, 0.0, SPEED * p_delta))
