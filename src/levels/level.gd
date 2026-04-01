extends Node3D

@export var coin_scene: PackedScene
@export var rock_scene: PackedScene
@export var road_scene: PackedScene
@export var road_length: float = 27.75
@export var initial_road_count: int = 4

const START_Z: float = -50.0
const ROAD_SPAWN_X: Array = [-2, 0, 2]

@onready var spawned_parent: Node3D = $Spawned
@onready var spawn_road_timer: Timer = $SpawnRoadTimer
@onready var spawn_coin_timer: Timer = $SpawnCoinTimer
@onready var spawn_obstacle_timer: Timer = $SpawnObstacleTimer

var _last_road: Node3D = null

func _ready() -> void:
	reset_level()


func reset_level() -> void:
	stop_level()

	for child in spawned_parent.get_children():
		child.queue_free()

	# Spawn initial roads
	for i in range(initial_road_count):
		var offset: float = road_length * i
		_last_road = _spawn_road(-offset)


func start_level() -> void:
	spawn_road_timer.start()
	spawn_coin_timer.start()
	spawn_obstacle_timer.start()


func stop_level() -> void:
	_last_road = null
	spawn_road_timer.stop()
	spawn_coin_timer.stop()
	spawn_obstacle_timer.stop()


func _spawn_road(p_z: float) -> Node3D:
	var road_asset = road_scene.instantiate()
	spawned_parent.add_child(road_asset)
	road_asset.global_transform.origin = Vector3(0, 0, p_z)
	return road_asset


func _on_spawn_road_timer_timeout() -> void:
	if _last_road:
		var z: float = _last_road.global_transform.origin.z - road_length
		_last_road = _spawn_road(z)


func _on_spawn_coin_timer_timeout() -> void:
	spawn_coin_timer.wait_time = randi() % 5 + 1

	var random_line_num: int = randi() % 3
	var prev_rand_line_num: int = -1

	var line_count: int = randi() % 4 + 1
	for i in line_count:
		while (prev_rand_line_num != -1 and prev_rand_line_num == random_line_num):
				random_line_num = randi() % 3
		prev_rand_line_num = random_line_num

		var coin_inst: Area3D = coin_scene.instantiate()
		spawned_parent.add_child(coin_inst)

		coin_inst.global_transform.origin = Vector3(
			ROAD_SPAWN_X[random_line_num],
			1.0,
			START_Z + i * 2.5 # set distance between coins
		)


func _on_spawn_obstacle_timer_timeout() -> void:
	spawn_obstacle_timer.wait_time = randi() % 5 + 1

	var random_line_num: int = randi() % 3
	var prev_rand_line_num: int = -1

	var line_count: int = randi() % 4 + 1
	for i in line_count:
		while (prev_rand_line_num != -1 and prev_rand_line_num == random_line_num):
				random_line_num = randi() % 3
		prev_rand_line_num = random_line_num

		var rock_inst = rock_scene.instantiate()
		spawned_parent.add_child(rock_inst)

		rock_inst.global_transform.origin = Vector3(ROAD_SPAWN_X[random_line_num], 0.0, START_Z)
		rock_inst.rotation_degrees.y = randf_range(0, 360)
