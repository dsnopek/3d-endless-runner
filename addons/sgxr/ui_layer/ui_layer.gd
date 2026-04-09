@tool
extends Node3D

const OPENXR_LAYER_CLASS = "OpenXRCompositionLayerQuad"

const NO_INTERSECTION = Vector2(-1.0, -1.0)
const CURSOR_DISTANCE = 0.005
const DOUBLE_CLICK_TIME = 400
const DOUBLE_CLICK_DIST = 5.0

@export var quad_size: Vector2 = Vector2(1.0, 1.0):
	set = set_quad_size
@export var layer_viewport: SubViewport:
	set = set_layer_viewport
@export var layer_sort_order := -1:
	set = set_layer_sort_order
@export var transparent_bg := false:
	set = set_transparent_bg
@export var force_fallback := false:
	set = set_force_fallback

@export var forward_keyboard_input := true
@export var forward_joypad_input := true

@onready var _cursor: MeshInstance3D = $Cursor
@onready var _quad: MeshInstance3D = $Quad

var _openxr_layer

var _pointer: Node3D
var _pointer_pressed := false
var _prev_intersection: Vector2 = NO_INTERSECTION
var _prev_pressed_pos: Vector2
var _prev_pressed_time: int = 0


func set_quad_size(p_quad_size: Vector2) -> void:
	quad_size = p_quad_size
	if _quad:
		_quad.mesh.size = quad_size
	if _openxr_layer:
		_openxr_layer.quad_size = quad_size


func set_layer_viewport(p_layer_viewport: SubViewport) -> void:
	layer_viewport = p_layer_viewport
	if layer_viewport:
		if _quad:
			_quad.mesh.material.albedo_texture = layer_viewport.get_texture()
		if _openxr_layer:
			_openxr_layer.layer_viewport = layer_viewport


func set_layer_sort_order(p_layer_sort_order: int) -> void:
	layer_sort_order = p_layer_sort_order
	if _openxr_layer:
		_openxr_layer.sort_order = layer_sort_order


func set_force_fallback(p_force_fallback: bool) -> void:
	if force_fallback == p_force_fallback:
		return
	force_fallback = p_force_fallback
	if _quad or _openxr_layer:
		_recreate_layer()


func set_transparent_bg(p_transparent_bg: bool) -> void:
	if transparent_bg == p_transparent_bg:
		return
	transparent_bg = p_transparent_bg
	if _quad:
		_quad.mesh.material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if transparent_bg else BaseMaterial3D.TRANSPARENCY_DISABLED

	# Swap the default values.
	if transparent_bg and layer_sort_order == -1:
		layer_sort_order = 1
	elif not transparent_bg and layer_sort_order == 1:
		layer_sort_order = -1

	_update_openxr_layer()


func _get_xr_origin() -> XROrigin3D:
	var parent: Node = get_parent()
	while parent:
		if parent is XROrigin3D:
			return parent
		parent = parent.get_parent()
	return null


func _get_configuration_warnings() -> PackedStringArray:
	var ret := PackedStringArray()
	if _get_xr_origin() == null:
		ret.push_back("UILayer must be a descendent of XROrigin3D")
	return ret


func _ready() -> void:
	_recreate_layer()


func _should_use_openxr_layer() -> bool:
	# If this build has OpenXRCompositionLayerQuad, we can use it, and even if we don't
	# use OpenXR or the OpenXR runtime doesn't support it, then it will provide a fallback.
	return not force_fallback and ClassDB.class_exists(OPENXR_LAYER_CLASS) and _get_xr_origin() != null


func _recreate_layer() -> void:
	if _openxr_layer:
		_openxr_layer.queue_free()
		_openxr_layer = null

	var xr_origin: XROrigin3D = _get_xr_origin()

	if _should_use_openxr_layer():
		_openxr_layer = ClassDB.instantiate(OPENXR_LAYER_CLASS)
		_openxr_layer.layer_viewport = layer_viewport
		_openxr_layer.visible = visible
		_update_openxr_layer()

		_quad.visible = false
		var f = func():
			xr_origin.add_child(_openxr_layer)
		f.call_deferred()
	else:
		_quad.visible = true
		_quad.mesh.size = quad_size
		if layer_viewport:
			_quad.mesh.material.albedo_texture = layer_viewport.get_texture()
		_quad.mesh.material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if transparent_bg else BaseMaterial3D.TRANSPARENCY_DISABLED


func _update_openxr_layer() -> void:
	if _openxr_layer:
		_openxr_layer.quad_size = quad_size
		_openxr_layer.alpha_blend = transparent_bg
		_openxr_layer.sort_order = layer_sort_order
		_openxr_layer.enable_hole_punch = not transparent_bg


func _process(_delta: float) -> void:
	if _openxr_layer:
		_openxr_layer.global_transform = global_transform


func _notification(p_what: int) -> void:
	match p_what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if _openxr_layer:
				_openxr_layer.visible = visible


func _intersect_to_global_pos(p_intersection: Vector2, p_distance: float = 0.0) -> Vector3:
	if p_intersection != NO_INTERSECTION:
		var local_pos : Vector2 = (p_intersection - Vector2(0.5, 0.5)) * quad_size
		return global_transform * Vector3(local_pos.x, -local_pos.y, p_distance)

	return Vector3()


func _intersect_to_viewport_pos(p_intersection: Vector2) -> Vector2:
	if layer_viewport and p_intersection != NO_INTERSECTION:
		var pos : Vector2 = p_intersection * Vector2(layer_viewport.size)
		return Vector2(pos)

	return NO_INTERSECTION


## Returns a normalized point (UV) in 2D space.
func intersects_ray(p_origin: Vector3, p_direction: Vector3) -> Vector2:
	if not visible:
		return NO_INTERSECTION
	if _openxr_layer:
		return _openxr_layer.intersects_ray(p_origin, p_direction)

	var quad_transform: Transform3D = get_global_transform()
	var quad_normal: Vector3 = quad_transform.basis.z

	var denom: float = quad_normal.dot(p_direction)
	if denom < -0.0001:
		var vector: Vector3 = quad_transform.origin - p_origin
		var t: float = vector.dot(quad_normal) / denom
		if t < 0.0:
			return NO_INTERSECTION

		var intersection: Vector3 = p_origin + p_direction * t

		var relative_point: Vector3 = intersection - quad_transform.origin
		var projected_point := Vector2(
			relative_point.dot(quad_transform.basis.x),
			relative_point.dot(quad_transform.basis.y))

		if absf(projected_point.x) > quad_size.x / 2.0:
			return NO_INTERSECTION
		if absf(projected_point.y) > quad_size.y / 2.0:
			return NO_INTERSECTION

		var u: float = 0.5 + (projected_point.x / quad_size.x)
		var v: float = 1.0 - (0.5 + (projected_point.y / quad_size.y))

		return Vector2(u, v)

	return NO_INTERSECTION


func pointer_intersects(p_pointer: Node3D) -> bool:
	var pt := p_pointer.global_transform
	var intersection := intersects_ray(pt.origin, -pt.basis.z)
	if intersection != NO_INTERSECTION:
		# If there was no current pointer, let's take this one.
		if _pointer == null:
			_pointer = p_pointer
			_cursor.visible = true

		var cursor_position = _intersect_to_global_pos(intersection, CURSOR_DISTANCE)
		if p_pointer.has_method("_update_pointer_length_for_intersection"):
				p_pointer._update_pointer_length_for_intersection(cursor_position)

		# If this pointer is the current pointer, then the cursor and mouse events move with it.
		if p_pointer == _pointer:
			_cursor.global_position = cursor_position

			if layer_viewport and _prev_intersection:
				var event := InputEventMouseMotion.new()
				var from := _intersect_to_viewport_pos(_prev_intersection)
				var to := _intersect_to_viewport_pos(intersection)
				if _pointer_pressed:
					event.button_mask = MOUSE_BUTTON_MASK_LEFT
				event.relative = to - from
				event.position = to
				layer_viewport.push_input(event)

			_prev_intersection = intersection

		return true

	# If this pointer is the current pointer, but there was no intersection, then that pointer
	# should leave.
	if p_pointer == _pointer:
		# Except if it's pressed - we'll hang on to it until it's released.
		if _pointer_pressed:
			return true
		pointer_leave(p_pointer)

	return false


func _send_mouse_button_event(p_pressed: bool) -> void:
	if not layer_viewport:
		return

	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.pressed = p_pressed
	event.position = _intersect_to_viewport_pos(_prev_intersection)

	if p_pressed:
		var time := Time.get_ticks_msec()
		#print("Click time: ", time - _prev_pressed_time)
		#print("Click dist: ", (event.position - _prev_pressed_pos).length())
		if time - _prev_pressed_time < DOUBLE_CLICK_TIME and (event.position - _prev_pressed_pos).length() < DOUBLE_CLICK_DIST:
			event.double_click = true

		_prev_pressed_time = time
		_prev_pressed_pos = event.position

	layer_viewport.push_input(event)


func pointer_leave(p_pointer: Node3D) -> void:
	# We only need to do anything, if the pointer leaving is the current pointer.
	if _pointer == p_pointer:
		# If the pointer was pressed, then send the mouse event to release the button.
		if _pointer_pressed and _prev_intersection != NO_INTERSECTION:
			_send_mouse_button_event(false)

		# And clear everything out.
		_pointer = null
		_pointer_pressed = false
		_cursor.visible = false
		_prev_intersection = NO_INTERSECTION
		_prev_pressed_time = 0


func pointer_set_pressed(p_pointer: Node3D, p_pressed: bool) -> void:
	if p_pointer == _pointer:
		# If this is the current pointer, then update our pressed state and send the mouse
		# events, if this is a change in state.
		if p_pressed != _pointer_pressed:
			_pointer_pressed = p_pressed
			_send_mouse_button_event(p_pressed)
	elif p_pressed:
		# If another pointer presses, then allow it to take over.
		if _pointer:
			# The current pointer leaves (this will send the mouse up event).
			pointer_leave(_pointer)
		if pointer_intersects(p_pointer):
			_pointer_pressed = true
			_prev_pressed_time = 0
			_send_mouse_button_event(true)


func _input(p_event: InputEvent) -> void:
	if layer_viewport:
		if forward_keyboard_input and (p_event is InputEventKey or p_event is InputEventShortcut):
			layer_viewport.push_input(p_event)
		elif forward_joypad_input and (p_event is InputEventJoypadButton or p_event is InputEventJoypadMotion):
			layer_viewport.push_input(p_event)
