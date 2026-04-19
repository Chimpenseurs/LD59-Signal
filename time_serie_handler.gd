class_name Game
extends Node

var current_time = 0.0
var total_time = 10.0
@export var xy_scale = Vector2(1.0,1)
@export var time_scale = 1.0
#@export var initial_derivation_vec_coef = 1.0
#@export var initial_derivation_timeleft = 0.5
@export var dist_offset_threshold = 100

var slow_coef = 0.1
var slow_time_scale = time_scale * slow_coef

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

var next_point_id = 1

#func _lerp(pt1: Vector2, pt2: Vector2, lerp: float) -> Vector2:
	#return Vector2(
		#(pt2.x - pt1.x) * lerp,
		#(pt2.y - pt1.y) * lerp
	#)
#
#func _get_first_point() -> Vector2:
	#var point_before = (t - (fmod(t, INTERVAL_SIZE))) / INTERVAL_SIZE
	#var lerp_val = (fmod(t, INTERVAL_SIZE)) / INTERVAL_SIZE
#
	#if point_before + 1 < len(time_serie):
		#return _lerp(
			#time_serie[point_before],
			#time_serie[point_before + 1],
			#lerp_val)
	#
##	Return null point at end of game.
	#return Vector2(0, 0)
#
#func _get_last_point() -> Vector2:
	#var t_right = t + display_size.x
	#var point_after = ((t_right - fmod(t_right, INTERVAL_SIZE)) / INTERVAL_SIZE) + 1
	#point_after = min(point_after, len(time_serie) - 1)
	#var lerp_val = (fmod(t, INTERVAL_SIZE)) / INTERVAL_SIZE
#
	#return _lerp(time_serie[point_after - 1], time_serie[point_after], lerp_val)
#
#func incr_y_by(n: int) -> void:
	#y += n
#
#func decr_y_by(n: int) -> void:
	#y -= n
#
#func get_y() -> int:
	#return y
	#
func get_serie() -> Array[Vector2]:
	return time_serie
#
#func get_serie_interval() -> Array:
##	Get the point of the left border of the screen.
	#var first_point = _get_first_point()
#
##	Get the point of the right border of the screen.
	#var last_point = _get_last_point()
#
##	Get the points in the time serie included in the screen.
	#var points = self.time_serie.slice(
		#((t - fmod(t, INTERVAL_SIZE)) / INTERVAL_SIZE) + 1,
		#max(
			#(t + 100 - fmod(t, INTERVAL_SIZE)) / INTERVAL_SIZE,
			#len(time_serie) - 1
		#)
	#)
	#
##	Add the points of the border of the screen.
	#points.push_front(first_point)
	#points.push_back(last_point)
	#return points
	
var baseline_h = 0.5
var medium_h = 0.3
var high_h = 0.1

func inject_pulse(pulse, velocity_scale):
	triggers.append(time_serie.size())
	scale_pulse(pulse)
	time_serie.append_array(pulse)
	for i in pulse.size()-1:
		velocities_scales.append(velocity_scale)
	velocities_scales.append(1)

func scale_pulse(pulse):
	for i in pulse.size():
		pulse[i] *= xy_scale

func length_pulse(pulse) -> float :
	var length = 0
	for i in pulse.size()-1:
		length += pulse[i].distance_to(pulse[i+1])
	return length

func add_simple_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, baseline_h), Vector2(offset_x + stride_x * 0.5, medium_h), Vector2(offset_x + stride_x * 0.9, baseline_h)]
	var velocity_scale = stride_x / length_pulse(pulse)
	inject_pulse(pulse, velocity_scale)

func add_regular_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, baseline_h), Vector2(offset_x + stride_x * 0.2, high_h), Vector2(offset_x + stride_x * 0.4, 1.0 - high_h), Vector2(offset_x + stride_x * 0.6, medium_h), Vector2(offset_x + stride_x * 0.9, 0.5)]
	var velocity_scale = stride_x / length_pulse(pulse)
	inject_pulse(pulse, velocity_scale)
	
func _ready() -> void:
	xy_scale.y = get_viewport().get_visible_rect().size.y
	var stride_x = 200
	for i in range(30):
		var is_even = i % 2
		var bound_y = 0.3 if is_even else 0.7
		if i == 24:
			add_regular_pulse(i * stride_x, stride_x)
		elif is_even:
			add_simple_pulse(i * stride_x, stride_x)
		
	$Line2D.points = time_serie
	
	#time_serie = $Line2D.points
	var curve = Curve2D.new()
	for i in time_serie.size():
		time_serie[i]
		curve.add_point(time_serie[i])
	$Path2D.curve = curve
	
	for i in triggers.size():
		var column = $Column.duplicate()
		column.scale.x *= xy_scale.x
		column.position.x = time_serie[triggers[i]].x-45
		$Line2D.add_child(column)
	
	previous_position = $Path2D/PathFollow2D/Circle.global_position
	$Path2D/PathFollow2D/Circle.material = load("res://materials/blooming_player.tres")

#func _get_segment_points(path2D : Path2D) -> Array[Vector2]:
	#for pt_i in time_serie.size():
		#var pos = path2D.curve.get_point_position(pt_i)
		#if pos.x > $Path2D/PathFollow2D/Icon.position.x:
			#return [path2D.curve.get_point_position(pt_i-1), path2D.curve.get_point_position(pt_i)]
		#else:
			#continue
	#return []
	
func _get_path_current_position():
	return $Path2D.curve.sample_baked($Path2D/PathFollow2D.progress)
	
func _get_path_next_position():
	return $Path2D.curve.sample_baked($Path2D/PathFollow2D.progress + 10)
	
func _process(delta: float) -> void:
	
	var velocity_scale = velocities_scales[triggers[next_point_id]]
	var player_pos = $Path2D/PathFollow2D/Circle.global_position
	var next_point = time_serie[triggers[next_point_id]]
	var distance_to_next_point = player_pos.distance_to(next_point)
	
	current_time += delta * (time_scale * velocity_scale)
	
	$Camera2D.position.x = _get_path_current_position().x
	$Path2D/PathFollow2D.set_progress_ratio(current_time)
	
	#if distance_to_next_point < dist_offset_threshold:
		#$Path2D/PathFollow2D/Circle.material = load("res://materials/blooming_player.tres")
		#$Path2D/PathFollow2D/Circle.scale = Vector2(1.5,1.5)
	#else:
		#$Path2D/PathFollow2D/Circle.material = null
		#$Path2D/PathFollow2D/Circle.scale = Vector2(0.5,0.5)
		
	var has_pressed = false
	if Input.is_action_just_pressed("ui_up"):
		has_pressed = true
		print(distance_to_next_point)
		if distance_to_next_point < dist_offset_threshold:
			print("GOOD")
			self.next_point_id+=1
		else :
			print("BAD")
			$AnimationPlayer.play("slower")
			
	if player_pos.x > next_point.x:
		if not has_pressed:
			print("MISSED")
			$AnimationPlayer.play("slower")
			#$Ld59SignalProto.pitch_scale /= slow_coef
			#time_scale = slow_time_scale
			#derivation_vec = (player_pos - previous_position).normalized()
			#derivation_vec_coef = initial_derivation_vec_coef
			#derivation_timeleft = initial_derivation_timeleft
		self.next_point_id+=1
		
	previous_position = player_pos

	#if derivation_vec_coef > 0:
		#var delta_next_pos = - player_pos.normalized()
		#$Path2D/PathFollow2D/Circle.position += lerp(derivation_vec * delta, delta_next_pos * delta, 1-derivation_vec_coef)
		##derivation_vec_coef = max(0, derivation_vec_coef -  0.1)
		#derivation_timeleft = max(0, derivation_timeleft - delta)
		#print(1.0-Tween.interpolate_value(0, 1.0, 0.5 - derivation_timeleft, 0.5, Tween.TRANS_EXPO, Tween.EASE_IN))
		#var t = 1.0-Tween.interpolate_value(0, 1.0, 0.5 - derivation_timeleft, 0.5, Tween.TRANS_EXPO, Tween.EASE_IN)
		#print(t)
		#derivation_vec_coef = t
