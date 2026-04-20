extends Node

var game_scene = preload("res://main.tscn")
var main_menu_scene = preload("res://main_menu.tscn")
var control_menu_scene = preload("res://control_menu.tscn")

var main_menu
var control_menu
var game

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_on_back_to_main_menu()
	
func _on_play() -> void:
	if game != null:
		game.queue_free()
		
	if main_menu != null:
		main_menu.queue_free()
	
	game = game_scene.instantiate()
	game.get_node("Camera2D/PauseMenu").restart.connect(_on_play)
	game.get_node("Camera2D/PauseMenu").back_to_menu.connect(_on_back_to_main_menu)
	game.set_pause.connect(_on_game_pause)
	
	add_child(game)
	get_tree().paused = false

func _on_game_pause() -> void:
	get_tree().paused = true

func _on_control_menu() -> void:
	if control_menu != null:
		control_menu.queue_free()
	
	if main_menu != null:
		main_menu.queue_free()
	
	control_menu = control_menu_scene.instantiate()
	control_menu.back_to_menu.connect(_on_back_to_main_menu)
	
	add_child(control_menu)

func _on_back_to_main_menu() -> void:
	if main_menu != null:
		main_menu.queue_free()
	
	if control_menu != null:
		control_menu.queue_free()
	
	if game != null:
		game.queue_free()
	
	main_menu = main_menu_scene.instantiate()
	add_child(main_menu)
	main_menu.launch_game.connect(_on_play)
	main_menu.show_control_menu.connect(_on_control_menu)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
