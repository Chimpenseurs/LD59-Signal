class_name Game
extends Node

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

var pulses: Array[PulseBase] = []
var pulse_idx = 0
var serie = []
var triggers = []
var velocities_scales = []

var next_trigger_point_id = 1
var previous_point_id = 0

var valid_control = false

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
func get_serie() -> Array[Vector2]:
	var construct: Array[Vector2] = []
	for p in pulses:
		construct.append_array(p.get_pulse())
	return construct

func inject_pulse(pulse: PulseBase, velocity_scale):
	pulses.append(pulse)
	for i in pulse.size()-1:
		velocities_scales.append(velocity_scale)
	velocities_scales.append(1.0)
	
func scale_pulse(pulse: PulseBase):
	for i in pulse.size():
		pulse.time_serie[i] *= xy_scale

func length_pulse(pulse: PulseBase) -> float :
	var length = 0
	for i in pulse.size()-1:
		length += pulse.time_serie[i].distance_to(pulse.time_serie[i+1])
	return length

func add_simple_pulse(offset_x, stride_x):
	var pulse = SimplePulse.new(offset_x, stride_x)
	scale_pulse(pulse)
	var velocity_scale = stride_x / length_pulse(pulse)
	inject_pulse(pulse, velocity_scale)

func add_regular_pulse(offset_x, stride_x):
	var pulse = RegularPulse.new(offset_x, stride_x)
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
		
	serie = get_serie()
		
	$Line2D.points = serie
	
	var curve = Curve2D.new()
	for i in serie.size():
		curve.add_point(serie[i])
	$Path2D.curve = curve

	previous_position = $Path2D/PathFollow2D/Circle.global_position
	
	# this allows to get the total number of pixels in the path, we need it for the speed scale
	$Path2D/PathFollow2D.progress_ratio = 1.0
	time_scale *= (path_pixels_ref / float($Path2D/PathFollow2D.progress))
	time_scale_init = time_scale
	$Path2D/PathFollow2D.progress_ratio = 0.0
	
	for p in pulses:
		var start = p.trigger_start
		var end = p.trigger_end
		var column: Sprite2D = $Column.duplicate()
		#column.scale.x *= xy_scale.x
		var texture: GradientTexture2D = column.texture
		texture.width = end - start
		column.position.x = (end + start) / 2
		$Line2D.add_child(column)
	
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
	var player_pos = $Path2D/PathFollow2D/Circle.global_position
	if serie[previous_point_id+1].x < player_pos.x:
		previous_point_id += 1
		
	var velocity_scale = velocities_scales[previous_point_id]
	#var next_trigger_point = serie[triggers[next_trigger_point_id]]
	#var distance_to_next_point = player_pos.distance_to(next_trigger_point)

	current_time += delta * (time_scale / velocity_scale)

	var current_x = _get_path_current_position().x
	$Camera2D.position.x = current_x
	$Path2D/PathFollow2D.set_progress_ratio(current_time)

	if self.pulse_idx < self.pulses.size():
		var pulse = self.pulses[pulse_idx]
		var state = pulse.handle_input(current_x)
		if state != PulseBase.Combo_state.GOOD && state != PulseBase.Combo_state.NONE:
			$AnimationPlayer.play("slower")
	
		if current_x > pulse.get_trigger_end():
			if pulse.get_state() == PulseBase.Combo_state.WAITING_NEXT_TRIGGER:
				print("MISSED")
				$AnimationPlayer.play("slower")
			self.pulse_idx += 1
		#$Ld59SignalProto.pitch_scale /= slow_coef
		#time_scale = slow_time_scale
		#derivation_vec = (player_pos - previous_position).normalized()
		#derivation_vec_coef = initial_derivation_vec_coef
		#derivation_timeleft = initial_derivation_timeleft

	previous_position = player_pos

func _on_trigger_area_entered(area: Area2D) -> void:
	valid_control = true

func _on_area_2d_area_exited(area: Area2D) -> void:
	valid_control = false
