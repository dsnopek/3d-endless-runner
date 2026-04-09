extends CharacterBody3D

@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer
@onready var coin_sound: AudioStreamPlayer = $CoinSound

const MOVE_SPEED: float = 8.0
const JUMP_VELOCITY: float = 8.0
const GRAVITY: float = 24.0
const LANES: Array = [-2.0, 0.0, 2.0]

const MIN_SWIPE_DISTANCE: float = 100.0
const MAX_SWIPE_TIME: float = 0.4

var starting_point: Vector3 = Vector3.ZERO
var current_lane: int = 1
var target_lane: int = 1

var is_jumping: bool = false
var is_dead: bool = false

var _touch_start_position: Vector2
var _touch_start_time: float
var _tracking_swipe: int = -1

signal coin_collected()
signal player_died()

func _ready() -> void:
	animation_player.play("Idle")


func _physics_process(p_delta: float) -> void:
	if not GameState.running or is_dead:
		return

	# Handle lane switching
	if Input.is_action_just_pressed("move_left") and target_lane > 0:
		target_lane -= 1
	if Input.is_action_just_pressed("move_right") and target_lane < LANES.size() - 1:
		target_lane += 1

	# Move towards the target lane
	position.x = lerpf(position.x, LANES[target_lane], MOVE_SPEED * p_delta)

	# Apply the parent's scale to velocity.
	var velocity_scale: float = get_parent().scale.x if get_parent() else 1.0

	# Apply gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * velocity_scale * p_delta
	else:
		velocity.y = 0  # Reset vertical velocity when on the floor

	# Jumping logic
	if is_on_floor() and Input.is_action_pressed("jump"):
		velocity.y = JUMP_VELOCITY * velocity_scale  # Apply jump velocity

	# Apply the velocity and move the character
	move_and_slide()

	# Play animations based on movement
	if not is_on_floor():
		animation_player.play("Jump")
	else:
		animation_player.play("Run")


func _input(p_event: InputEvent) -> void:
	if p_event is InputEventScreenTouch:
		if p_event.pressed:
			_touch_start_position = p_event.position
			_touch_start_time = Time.get_ticks_msec()
			_tracking_swipe = p_event.index
		elif _tracking_swipe == p_event.index:
			var swipe_vector: Vector2 = p_event.position - _touch_start_position
			var swipe_time: float = (Time.get_ticks_msec() - _touch_start_time) / 1000.0

			if swipe_time < MAX_SWIPE_TIME and swipe_vector.length() > MIN_SWIPE_DISTANCE:
				var action: String = ""

				var swipe_direction: Vector2 = swipe_vector.normalized()
				if swipe_direction.dot(Vector2.RIGHT) > 0.7:
					action = "move_right"
				elif swipe_direction.dot(Vector2.LEFT) > 0.7:
					action = "move_left"
				elif swipe_direction.dot(Vector2.UP) > 0.7:
					action = "jump"
				elif swipe_direction.dot(Vector2.DOWN) > 0.7:
					action = "slide"

				var new_event_pressed = InputEventAction.new()
				new_event_pressed.action = action
				new_event_pressed.pressed = true
				Input.parse_input_event(new_event_pressed)

				# Release after the next physics frame.
				var release_cb: Callable = func():
					var new_event_released = InputEventAction.new()
					new_event_released.action = action
					new_event_released.pressed = false
					Input.parse_input_event(new_event_released)
				get_tree().physics_frame.connect(release_cb, ConnectFlags.CONNECT_ONE_SHOT)

			_tracking_swipe = -1


func _on_collision_area_entered(p_area):
	if p_area.is_in_group("coins"):
		p_area.queue_free()
		coin_sound.play()
		coin_collected.emit()
	elif p_area.is_in_group("obstacles"):
		is_dead = true
		player_died.emit()


func reset_player() -> void:
	animation_player.play("Idle")
	is_dead = false
	is_jumping = false
	current_lane = 1
	target_lane = 1
	position = starting_point
