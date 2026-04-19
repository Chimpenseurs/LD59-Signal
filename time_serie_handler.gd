@tool

class_name Game
extends Node

signal set_pause

# constants
var baseline_h = 0.5
var medium_h = 0.3
var high_h = 0.1

var current_time = 0.0
@export var xy_scale = Vector2(1.0,1)
@export var velocity_x : float = 10.0 # m/s

var path_pixels_ref = 7839.0

var time_serie = []
var triggers = []

var next_trigger_point_id = 1
var previous_point_id = 0

var valid_control = false

func get_serie() -> Array[Vector2]:
	return time_serie

func inject_pulse(pulse, i_triggers):
	scale_pulse(pulse)
	var path = pulse.slice(1,pulse.size())
	triggers.append_array(i_triggers)
	time_serie.append_array(path)
	
func scale_pulse(pulse):
	for i in pulse.size():
		pulse[i] *= xy_scale

func length_pulse(pulse) -> float :
	var length = 0
	for i in pulse.size()-1:
		length += pulse[i].distance_to(pulse[i+1])
	return length

func add_flat_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, baseline_h), Vector2(offset_x + stride_x, baseline_h)]
	inject_pulse(pulse, [])
	
func add_simple_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, baseline_h), Vector2(offset_x + stride_x * 0.2, medium_h), Vector2(offset_x + stride_x * 0.4, baseline_h), Vector2(offset_x + stride_x * 1.0, baseline_h)]
	inject_pulse(pulse, [time_serie.size()-1])

func add_regular_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, baseline_h), Vector2(offset_x + stride_x * 0.2, high_h), Vector2(offset_x + stride_x * 0.4, 1.0 - high_h), Vector2(offset_x + stride_x * 0.6, medium_h), Vector2(offset_x + stride_x * 1.0, 0.5)]
	inject_pulse(pulse, [time_serie.size()-1])
		
func _ready() -> void:
	xy_scale.y = get_viewport().get_visible_rect().size.y
	var stride_x = 200
	
	var content = FileAccess.open("res://partition.txt", FileAccess.READ).get_as_text().strip_edges().split(",")
	var pulses_types = []
	for pulse_type in content:
		pulses_types.append(int(pulse_type))
	
	var index = 0
	time_serie.append(Vector2(0,baseline_h))
	for pulse_type in pulses_types:
		if pulse_type == 0:
			add_flat_pulse(index * stride_x, stride_x)
		if pulse_type == 1:
			add_simple_pulse(index * stride_x, stride_x)
		elif pulse_type == 2:
			add_regular_pulse(index * stride_x, stride_x)
		var str = str(index)
		$TextureButton.text = str
		$TextureButton.position.x = index * stride_x
		var tb = $TextureButton.duplicate()
		self.add_child(tb)
		index += 1
		
	$Line2D.points = time_serie

	for i in triggers.size():
		var column = $Column.duplicate()
		var texture : GradientTexture2D = column.texture
		var texture_width = texture.width
		column.position.x = time_serie[triggers[i]].x - texture_width * 0.5
		$Line2D.add_child(column)
	
func _get_path_current_position(time):
	var pos_x = time * velocity_x
	for i in time_serie.size():
		if time_serie[i].x < pos_x:
			continue
		assert(i > 0)
		var seg : Vector2 = (time_serie[i] - time_serie[i-1]).normalized()
		var vertical_x = Vector2(pos_x, 0);
		var pt = Geometry2D.line_intersects_line(vertical_x, Vector2.DOWN, time_serie[i-1], seg)
		assert(pt != null)
		return pt
			
	assert(false)
	
func _process(delta: float) -> void:

	if  Engine.is_editor_hint():
		return

	var player_pos = $Circle.global_position
	if time_serie[previous_point_id+1].x < player_pos.x:
		previous_point_id += 1
		
	var next_trigger_point = time_serie[triggers[next_trigger_point_id]]
	var distance_to_next_point = player_pos.distance_to(next_trigger_point)
	
	current_time += delta
	var current_position = _get_path_current_position(current_time)
	
	$Camera2D.position.x = current_position.x
	$Circle.position = current_position
	#$Path2D/PathFollow2D.set_progress_ratio(current_time)
		
	var has_pressed = false
	if Input.is_action_just_pressed("pause"):
		$Camera2D/PauseMenu.visible = true
		emit_signal("set_pause")
		
	if Input.is_action_just_pressed("ui_up") :
		has_pressed = true
		print(distance_to_next_point)
		if valid_control:
			print("GOOD")
			$AnimationPlayer.play("success")
			self.next_trigger_point_id+=1
		else :
			print("BAD")
			$AnimationPlayer.play("slower")
			
	if player_pos.x > next_trigger_point.x:
		if not has_pressed:
			print("MISSED")
			$AnimationPlayer.play("slower")
		self.next_trigger_point_id+=1

func _on_trigger_area_entered(area: Area2D) -> void:
	valid_control = true

func _on_area_2d_area_exited(area: Area2D) -> void:
	valid_control = false
	
func active_wave():
	$Wave.position = $Circle.global_position
