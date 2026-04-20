extends Line2D

signal kick_succeed

var current_trigger = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_trigger :
		if Input.is_action_just_pressed("ui_left"):
			print("GOOD KICK")
			emit_signal("kick_succeed")


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "Area2DRythm1":
		current_trigger = area


func _on_area_2d_area_exited(area: Area2D) -> void:
	if current_trigger and area.name == "Area2DRythm1":
		current_trigger = null
