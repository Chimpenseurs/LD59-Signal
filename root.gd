extends Node

var game_scene = preload("res://main.tscn")
var main_menu_scene = preload("res://main_menu.tscn")

var main_menu
var game

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_menu = main_menu_scene.instantiate()
	add_child(main_menu)
	main_menu.launch_game.connect(_on_play)
	
func _on_play() -> void:
	if game != null:
		game.queue_free()
		
	if main_menu != null:
		main_menu.queue_free()
	
	game = game_scene.instantiate()
	#game.replay.connect(_on_play)
	#game.gotomainmenu.connect(_on_main_menu)
	
	add_child(game)
	get_tree().paused = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
