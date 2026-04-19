@tool

class_name Game
extends Node

signal set_pause

var current_time = 0.0
var total_time = 10.0
@export var xy_scale = Vector2(1.0,1)
@export var time_scale = 1.0
var time_scale_init = time_scale
#@export var initial_derivation_vec_coef = 1.0
#@export var initial_derivation_timeleft = 0.5
@export var dist_offset_threshold = 100

var slow_coef = 0.1
var slow_time_scale = time_scale * slow_coef

var path_pixels_ref = 7839.0

var previous_position : Vector2
var derivation_vec : Vector2
var derivation_vec_coef = 0.0
var derivation_timeleft = 0.0

# Let suppose an interval between 2 points is 20
# If t = 33, the point before t is time_serie[1] and
# we need to lerp at 13/20 from time_serie[1] to time_serie[2]
var time_serie = []
var triggers = []
var velocities_scales = []

var next_trigger_point_id = 1
var previous_point_id = 0

var valid_control = false

func get_serie() -> Array[Vector2]:
	return time_serie

var baseline_h = 0.5
var medium_h = 0.3
var high_h = 0.1

func inject_pulse(pulse, velocity_scale):
	triggers.append(time_serie.size())
	time_serie.append_array(pulse)
	for i in pulse.size()-1:
		velocities_scales.append(velocity_scale)
	velocities_scales.append(1.0)
	
func scale_pulse(pulse):
	for i in pulse.size():
		pulse[i] *= xy_scale

func length_pulse(pulse) -> float :
	var length = 0
	for i in pulse.size()-1:
		length += pulse[i].distance_to(pulse[i+1])
	return length

func add_simple_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, baseline_h), Vector2(offset_x + stride_x * 0.2, medium_h), Vector2(offset_x + stride_x * 0.4, baseline_h), Vector2(offset_x + stride_x * 1.0, baseline_h)]
	scale_pulse(pulse)
	var velocity_scale = stride_x / length_pulse(pulse)
	inject_pulse(pulse, velocity_scale)

func add_regular_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, baseline_h), Vector2(offset_x + stride_x * 0.2, high_h), Vector2(offset_x + stride_x * 0.4, 1.0 - high_h), Vector2(offset_x + stride_x * 0.6, medium_h), Vector2(offset_x + stride_x * 1.0, 0.5)]
	scale_pulse(pulse)
	var velocity_scale = stride_x / length_pulse(pulse)
	inject_pulse(pulse, velocity_scale)
		
func _ready() -> void:
	xy_scale.y = get_viewport().get_visible_rect().size.y
	var stride_x = 200
	
	var file = FileAccess.open("res://partition.txt", FileAccess.READ)
	var content = file.get_as_text()
	content = content.strip_edges()
	var content_array = content.split(",")
	var pulses_types = []
	for pulse_type in content_array:
		pulses_types.append(int(pulse_type))
	
	var index = 0
	for pulse_type in pulses_types:
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
	
	var curve = Curve2D.new()
	for i in time_serie.size():
		curve.add_point(time_serie[i])
	$Path2D.curve = curve

	for i in triggers.size():
		var column = $Column.duplicate()
		column.scale.x *= xy_scale.x
		column.position.x = time_serie[triggers[i]].x-45
		$Line2D.add_child(column)

	previous_position = $Path2D/PathFollow2D/Circle.global_position
	
	# this allows to get the total number of pixels in the path, we need it for the speed scale
	$Path2D/PathFollow2D.progress_ratio = 1.0
	time_scale *= (path_pixels_ref / float($Path2D/PathFollow2D.progress))
	time_scale_init = time_scale
	$Path2D/PathFollow2D.progress_ratio = 0.0
	
	if not Engine.is_editor_hint():
		var animation = $AnimationPlayer.get_animation("slower")
		var track_id = animation.find_track(".:time_scale", Animation.TYPE_VALUE)

		animation.track_set_key_value(track_id, 0, time_scale_init)
		animation.track_set_key_value(track_id, 1, time_scale_init * 0.1)
		animation.track_set_key_value(track_id, 2, time_scale_init)
	
	
func _get_path_current_position():
	return $Path2D.curve.sample_baked($Path2D/PathFollow2D.progress)
	
func _get_path_next_position():
	return $Path2D.curve.sample_baked($Path2D/PathFollow2D.progress + 10)
	
func _process(delta: float) -> void:

	if  Engine.is_editor_hint():
		return

	var player_pos = $Path2D/PathFollow2D/Circle.global_position
	if time_serie[previous_point_id+1].x < player_pos.x:
		previous_point_id += 1
		
	var velocity_scale = velocities_scales[previous_point_id]
	var next_trigger_point = time_serie[triggers[next_trigger_point_id]]
	var distance_to_next_point = player_pos.distance_to(next_trigger_point)
	
	current_time += delta * (time_scale / velocity_scale)
	
	$Camera2D.position.x = _get_path_current_position().x
	$Path2D/PathFollow2D.set_progress_ratio(current_time)
		
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
		
	previous_position = player_pos

func _on_trigger_area_entered(area: Area2D) -> void:
	valid_control = true

func _on_area_2d_area_exited(area: Area2D) -> void:
	valid_control = false
	
func active_wave():
	$Wave.position = $Path2D/PathFollow2D/Circle.global_position
