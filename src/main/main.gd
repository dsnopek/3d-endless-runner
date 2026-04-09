extends Node3D

@export var level: Node3D
@export var player: Node3D
@export var ui: Control

var coin_count: int = 0

func _ready() -> void:
	randomize()

	if not player:
		push_error("Player node not assigned in Main scene.")
		return

	if not level:
		push_error("Level node not assigned in Main scene.")
		return

	if not ui:
		push_error("UI node not assigned in Main scene.")
		return

	GameState.current_level = level

	player.coin_collected.connect(_on_player_coin_collected)
	player.player_died.connect(_on_player_player_died)

	ui.play_pressed.connect(_on_ui_play_pressed)
	ui.quit_pressed.connect(_on_ui_quit_pressed)
	ui.pause_pressed.connect(_on_ui_pause_pressed)
	ui.resume_pressed.connect(_on_ui_resume_pressed)
	ui.return_to_menu_pressed.connect(_on_ui_return_to_menu_pressed)
	ui.retry_pressed.connect(_on_ui_retry_pressed)

	ui.set_hud_visibility(false)


func _on_player_coin_collected() -> void:
	coin_count += 1
	ui.set_coin_count(coin_count)


func _on_player_player_died() -> void:
	level.stop_level()
	GameState.running = false
	ui.show_menu("GameOverMenu")


func _on_ui_play_pressed() -> void:
	ui.set_hud_visibility(true)
	ui.hide_menu()

	level.start_level()
	GameState.running = true


func _on_ui_quit_pressed() -> void:
	get_tree().quit()


func _on_ui_pause_pressed() -> void:
	if not GameState.running:
		return

	if get_tree().paused:
		ui.hide_menu()
		get_tree().paused = false
	else:
		ui.show_menu("PauseMenu")
		get_tree().paused = true


func _on_ui_resume_pressed() -> void:
	# It's like a pause button that only works when already paused.
	if get_tree().paused:
		_on_ui_pause_pressed()


func _on_ui_return_to_menu_pressed() -> void:
	get_tree().paused = false
	GameState.reset_state()
	level.reset_level()
	player.reset_player()
	ui.set_hud_visibility(false)
	ui.show_menu("MainMenu")


func _on_ui_retry_pressed() -> void:
	_on_ui_return_to_menu_pressed()
	_on_ui_play_pressed()
