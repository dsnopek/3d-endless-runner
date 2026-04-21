extends "res://src/main/main.gd"

const Stencilizer = preload("res://src/xrconv/stencilizer.gd")

@onready var xr_origin: XROrigin3D = $XROrigin3D
@onready var camera: XRCamera3D = %XRCamera3D
@onready var ui_layer: Node3D = %UILayer
@onready var flat_portal: MeshInstance3D = $FlatPortal
@onready var cube_portal: MeshInstance3D = $CubePortal
@onready var cube_depth: MeshInstance3D = $CubeDepth
@onready var game_parent: Node3D = $GameParent
@onready var world_environment: WorldEnvironment = $GameParent/Level/WorldEnvironment

const UI_LAYER_MIN_SCALE := 0.25

enum XRMode {
	IMMERSIVE,
	PORTAL,
	VOLUME,
	SPATIAL_CONTAINER,
}

var stencilizer: Stencilizer = Stencilizer.new(1)
var xr_mode: XRMode = XRMode.IMMERSIVE

func _ready() -> void:
	super._ready()

	var spatial_container_ext = Engine.get_singleton("OpenXRSpatialContainerExtension")
	if spatial_container_ext and spatial_container_ext.is_enabled():
		set_xr_mode(XRMode.SPATIAL_CONTAINER)
		spatial_container_ext.spatial_container_bounds_changed.connect(_on_spatial_container_bounds_changed)
		spatial_container_ext.spatial_container_interactability_changed.connect(_on_spatial_container_interactability_changed)

	stencilizer.setup_portal_material(flat_portal)
	stencilizer.setup_portal_material(cube_portal)

	level.object_spawned.connect(_on_level_object_spawned)


func _on_level_object_spawned(obj: Node3D) -> void:
	if xr_mode >= XRMode.PORTAL:
		stencilizer.setup_object_materials(obj)


func _on_ui_xr_mode_changed(p_index: int) -> void:
	set_xr_mode(p_index)


func _process(_delta: float) -> void:
	if xr_mode == XRMode.SPATIAL_CONTAINER:
		ui_layer.global_transform = %SpatialContainerUIMarker.global_transform
		if ui_layer.scale.x < UI_LAYER_MIN_SCALE:
			ui_layer.scale = Vector3.ONE * UI_LAYER_MIN_SCALE
		ui_layer.look_at(camera.global_transform.origin, Vector3.UP, true)


func set_xr_mode(p_index: XRMode) -> void:
	xr_mode = p_index

	var openxr_interface: OpenXRInterface = XRServer.find_interface("OpenXR")
	if not openxr_interface or not openxr_interface.is_initialized():
		return

	var faux_sky_box: MeshInstance3D = level.get_node("FauxSkyBox") as MeshInstance3D
	var plain: MeshInstance3D = level.get_node("Plain") as MeshInstance3D

	if xr_mode == XRMode.IMMERSIVE:
		openxr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_OPAQUE
		world_environment.environment.background_mode = Environment.BG_SKY
		get_viewport().transparent_bg = false
		stencilizer.restore_object_materials(player)
		stencilizer.restore_object_materials(level)
		xr_origin.position = %VROriginMarker.position
		game_parent.position = Vector3.ZERO
		game_parent.scale = Vector3.ONE
		faux_sky_box.visible = true
		plain.visible = true
		flat_portal.visible = false
		cube_portal.visible = false
		cube_depth.visible = false

	elif xr_mode in [XRMode.PORTAL, XRMode.VOLUME]:
		openxr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND
		world_environment.environment.background_mode = Environment.BG_COLOR
		world_environment.environment.background_color = Color(0.0, 0.0, 0.0, 0.0)
		get_viewport().transparent_bg = true
		stencilizer.setup_object_materials(player)
		stencilizer.setup_object_materials(level)

		if xr_mode == 1:
			xr_origin.position = %PortalOriginMarker.position
			game_parent.position = Vector3.ZERO
			game_parent.scale = Vector3.ONE
			faux_sky_box.visible = true
			plain.visible = true
			flat_portal.visible = true
			cube_portal.visible = false
			cube_depth.visible = false
		elif xr_mode == 2:
			xr_origin.position = %VolumeOriginMarker.position
			game_parent.position = %VolumeGameMarker.position
			game_parent.scale = Vector3(0.1, 0.1, 0.1)
			faux_sky_box.visible = false
			plain.visible = false
			flat_portal.visible = false
			cube_portal.visible = true
			cube_depth.visible = true

	elif xr_mode == XRMode.SPATIAL_CONTAINER:
		openxr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND
		world_environment.environment.background_mode = Environment.BG_COLOR
		world_environment.environment.background_color = Color(0.0, 0.0, 0.0, 0.0)
		get_viewport().transparent_bg = true
		stencilizer.setup_object_materials(player)
		stencilizer.setup_object_materials(level)

		xr_origin.position = Vector3.ZERO
		game_parent.position = Vector3.ZERO
		game_parent.scale = Vector3(0.1, 0.1, 0.1)
		faux_sky_box.visible = false
		plain.visible = false
		flat_portal.visible = false
		cube_portal.visible = true
		cube_portal.position = Vector3.ZERO
		cube_depth.visible = true
		cube_depth.position = Vector3.ZERO


func _on_spatial_container_bounds_changed(_spatial_container_rid: RID, p_updated_bounds: Vector3) -> void:
	var min_dimension: float = min(p_updated_bounds.x, min(p_updated_bounds.y, p_updated_bounds.z))
	if min_dimension <= 0.0:
		print("Invalid spatial container bounds received: ", p_updated_bounds)
		return

	cube_depth.mesh.size = p_updated_bounds * 0.99
	print("Cube depth size: ", cube_depth.mesh.size)

	game_parent.scale = Vector3.ONE * (min_dimension / 20.0)
	game_parent.position.y = (-p_updated_bounds.y / 2.0) + 0.001
	game_parent.position.z = (p_updated_bounds.z  / 2.0) - (game_parent.scale.z * 1.0)

	print("Updated bounds: ", p_updated_bounds, " | New scale: ", game_parent.scale)


func _on_spatial_container_interactability_changed(_spatial_container_rid: RID, p_interactability: OpenXRSpatialContainerState.Interactability) -> void:
	print("Interactability changed to " + str(p_interactability))
