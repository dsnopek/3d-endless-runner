extends RefCounted

var _value := 1
var _materials: Dictionary[StandardMaterial3D, StandardMaterial3D] = {}
var _materials_inverse: Dictionary[StandardMaterial3D, StandardMaterial3D] = {}


func _init(p_value: int) -> void:
	_value = p_value


func setup_object_materials(p_parent: Node3D) -> void:
	if p_parent is MeshInstance3D:
		_update_object(p_parent)
	for child in p_parent.find_children("*", "MeshInstance3D", true, false):
		_update_object(child)


func _update_object(p_mesh: MeshInstance3D) -> void:
	var surface_count := p_mesh.mesh.get_surface_count()
	for i in range(surface_count):
		_update_object_material(p_mesh, i)


func _update_object_material(p_mesh: MeshInstance3D, i: int) -> void:
	var mat := p_mesh.get_active_material(i)
	if not mat:
		return
	if _materials_inverse.has(mat):
		return

	if mat and mat is StandardMaterial3D:
		if _materials.has(mat):
			p_mesh.set_surface_override_material(i, _materials[mat as StandardMaterial3D])
		else:
			var new_mat: StandardMaterial3D = mat.duplicate()
			new_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			new_mat.cull_mode = BaseMaterial3D.CULL_BACK
			new_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
			new_mat.stencil_mode = BaseMaterial3D.STENCIL_MODE_CUSTOM
			new_mat.stencil_flags = BaseMaterial3D.STENCIL_FLAG_READ
			new_mat.stencil_compare = BaseMaterial3D.STENCIL_COMPARE_EQUAL
			new_mat.stencil_reference = _value

			p_mesh.set_surface_override_material(i, new_mat)

			_materials[mat as StandardMaterial3D] = new_mat
			_materials_inverse[new_mat] = mat as StandardMaterial3D


func restore_object_materials(p_parent: Node3D) -> void:
	if p_parent is MeshInstance3D:
		_restore_object(p_parent)
	for child in p_parent.find_children("*", "MeshInstance3D", true, false):
		_restore_object(child)


func _restore_object(p_mesh: MeshInstance3D) -> void:
	var surface_count := p_mesh.mesh.get_surface_count()
	for i in range(surface_count):
		var mat := p_mesh.get_surface_override_material(i)
		if mat and _materials_inverse.has(mat):
			p_mesh.set_surface_override_material(i, _materials_inverse[mat as StandardMaterial3D])


func setup_portal_material(p_portal: MeshInstance3D) -> void:
	var mat := p_portal.get_active_material(0)
	if not mat:
		mat = StandardMaterial3D.new()

	if mat and mat is StandardMaterial3D:
		var new_mat: StandardMaterial3D = mat.duplicate()
		new_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		new_mat.stencil_mode = BaseMaterial3D.STENCIL_MODE_CUSTOM
		new_mat.stencil_flags = BaseMaterial3D.STENCIL_FLAG_WRITE
		new_mat.stencil_compare = BaseMaterial3D.STENCIL_COMPARE_ALWAYS
		new_mat.stencil_reference = _value
		new_mat.render_priority = -50
		p_portal.set_surface_override_material(0, new_mat)
