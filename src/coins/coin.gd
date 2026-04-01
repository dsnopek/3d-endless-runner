extends Area3D

@onready var model: MeshInstance3D = $Model


func _process(p_delta: float) -> void:
	rotate_y(5 * p_delta)

