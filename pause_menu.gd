extends Control

signal restart
signal back_to_menu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_continue_mouse_entered() -> void:
	$AudioStreamPlayer.play()

func _on_restart_mouse_entered() -> void:
	$AudioStreamPlayer.play()

func _on_main_menu_mouse_entered() -> void:
	$AudioStreamPlayer.play()

func _on_main_set_pause() -> void:
	self.visible = true

func _on_continue_pressed() -> void:
	self.visible = false
	get_tree().paused = false

func _on_restart_pressed() -> void:
	emit_signal("restart")

func _on_main_menu_pressed() -> void:
	emit_signal("back_to_menu")
