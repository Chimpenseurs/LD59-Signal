extends Control

signal restart
signal back_to_menu

func set_score(score: int) -> void:
	$Score.text = str(score)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if $Score.text == "0":
		# Assuming score is at zero when sent from the start menu
		$Score.visible = false
		$Label2.visible = false
		
		$VBoxContainer/restart.text = "Start"
		
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_quit_mouse_entered() -> void:
	$AudioStreamPlayer.play()

func _on_main_menu_mouse_entered() -> void:
	$AudioStreamPlayer.play()

func _on_restart_mouse_entered() -> void:
	$AudioStreamPlayer.play()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_restart_pressed() -> void:
	emit_signal("restart")

func _on_main_menu_pressed() -> void:
	emit_signal("back_to_menu")
