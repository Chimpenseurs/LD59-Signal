extends Control

signal launch_game
signal show_control_menu
signal end_game

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HBoxContainer/HSlider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_play_pressed() -> void:
	emit_signal("launch_game")

func _on_controls_pressed() -> void:
	emit_signal("show_control_menu")

func _on_credits_pressed() -> void:
	emit_signal("end_game")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_play_mouse_entered() -> void:
	$AudioStreamPlayer.play()

func _on_controls_mouse_entered() -> void:
	$AudioStreamPlayer.play()

func _on_quit_mouse_entered() -> void:
	$AudioStreamPlayer.play()

func _on_h_slider_mouse_entered() -> void:
	$AudioStreamPlayer.play()

func _on_h_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)
	$AudioStreamPlayer.play()


func _on_credits_mouse_entered() -> void:
	pass # Replace with function body.
