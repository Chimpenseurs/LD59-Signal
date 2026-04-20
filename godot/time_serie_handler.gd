@tool

class_name Game
extends Node

signal set_pause
signal end_game(score)

# constants
const LOW_H = 0.9
const DOWN_MEDIUM_H = 0.7
const BASELINE_H = 0.5
const MEDIUM_H = 0.3
const HIGH_H = 0.1

const PULSE_FLAT = 0
const PULSE_BEAT = 1
const PULSE_CHORD = 2
const PULSE_SLICE_UP = 3
const BOUING_BOUING = 4
const RESSORT = 5

const NONE = 0
const SUCCEED = 1
const FAILED = 2
const PENDING = 3
const WAITING = 4
const TOO_SOON = 5
const TOO_LATE = 6
const UNEXPECTED = 7
@export var xy_scale = Vector2(1.0,1)

var Partition = preload("res://partition.gd")

var bpm = 120

var bps = bpm / 60 # bpm but per seconds
var stride_x = 200
var velocity_x : float = 400

var path_pixels_ref = 7839.0
var current_time = 0.0

var time_serie = []
var triggers = []
var trigger_miss = false
var current_trigger_idx = 0

var score = 0
var combo = 0

# Game feel variables
var start_scale_size = 0.8
var combo_scale_factor = 0.1
var max_scale_size = 1.8
var max_particules_amount = 2000
var line_thickness_max = 0.1

func player_visual(intensity: int):
	var scale_size = start_scale_size + max(intensity, max_scale_size) * combo_scale_factor
	$Circle.scale.x = min(max_scale_size, scale_size)
	$Circle.scale.y = min(max_scale_size, scale_size)

	$Circle/GPUParticles2D.amount = min(intensity * 10, max_particules_amount)
	$Circle/GPUParticles2D.emitting = intensity > 0
	
	
	
	var thickness_scale_size = min(intensity / 50.0, 0.1)
	if intensity == 0:
		$Line2D.material.set_shader_parameter("thickness", 0.015)
		$Line2D.material.set_shader_parameter("outline_thickness", 0.015)
	else:
		$Line2D.material.set_shader_parameter("thickness", thickness_scale_size)
		$Line2D.material.set_shader_parameter("outline_thickness", thickness_scale_size)


class PushTrigger:
	var position_index : Array[int]
	var expected_actions = ["ui_button0"]
	var start_trigger: float
	var end_trigger: float
	var stride_x: float
	var state: int

	func _init(index, start_x, stride_x_):
		position_index = [index]
		self.stride_x = stride_x_
		self.start_trigger = start_x - (0.1 * stride_x)
		self.end_trigger = start_x + (0.1 * stride_x)
		self.state = PENDING
		
	func create_column(column: Node) -> Array[Node]:
		var column_1 = column.duplicate()
		column_1.scale /= 1.8
		column_1.position.x = start_trigger + (end_trigger - start_trigger) * 0.5
		return [column_1]

	# The idea is: if the current x position of the player is higher than
	# get_next_trigger_x, we go to the next Trigger object.
	func get_next_trigger_x() -> float:
		return self.end_trigger + (self.stride_x * 0.5)

	func has_succeed(current_x: float):
		for required_action in self.expected_actions:
			if Input.is_action_just_pressed(required_action):
				if self.state != PENDING:
					return UNEXPECTED
				if current_x > self.end_trigger:
					self.state = TOO_LATE
				elif current_x < self.start_trigger:
					self.state = TOO_SOON
				else:
					self.state = SUCCEED
				return self.state
		return NONE

class SlideTrigger:
	var position_index : Array[int]
	var expected_actions = ["ui_button0"]
	var state = PENDING
	var start_trigger: float
	var end_trigger: float

	func _init(index, index2, start_x, stride_x):
		position_index = [index, index2]
		start_trigger = start_x
		end_trigger = start_x + stride_x

	func create_column(column: Node) -> Array[Node]:
		var range_slide = end_trigger - start_trigger
		var stride = range_slide * 0.4
		var column_start = column.duplicate()
		var column_end = column.duplicate()
		var column_between = column.duplicate()
		column_start.scale /= 2
		column_end.scale /= 2
		column_between.scale /= 2
		column_start.position.x = start_trigger + stride * 0.5
		column_end.position.x = end_trigger - stride  + stride * 0.5
		column_between.position.x = start_trigger + stride
		column_between.modulate = Color(1.0, 0.843, 0.0, 1.0)
		return [column_start, column_between, column_end]
		
	func get_next_trigger_x() -> float:
		return self.end_trigger

	func has_succeed(current_x):
		var begin = start_trigger
		var end = end_trigger
		var range_slide = (end - begin)
		var stride = range_slide * 0.4

#		When the Trigger is over, or if the start in not reached.
		if state in [SUCCEED, FAILED] || current_x < begin:
			for action in self.expected_actions:
				if Input.is_action_just_pressed(action):
					return UNEXPECTED

#		When the Trigger has the button pressed.
		elif state == WAITING:
			for action in self.expected_actions:
				if Input.is_action_just_released(action):
					if current_x >= end_trigger - stride:
						state = SUCCEED
						return SUCCEED
					else:
						state = FAILED
						return FAILED

#		When the Trigger wait the just press action.
		elif current_x >= begin && current_x <= begin + stride:
			for action in self.expected_actions:
				if state == PENDING && Input.is_action_just_pressed(action):
					state = WAITING
					return state
			
		return NONE
					
			#var input_valid_nb = 0
			#for required_action in self.expected_actions:    
				#if Input.is_action_pressed(required_action):
					#input_valid_nb += 1
					#continue
			##if input_valid_nb == self.expected_actions.size():
				#state = PENDING
				#return PENDING
				#
		#elif current_x < end - stride:
			#if state == WAITING:
				#return FAILED
			#var input_valid_nb = 0
			#for required_action in self.expected_actions:
				#if Input.is_action_pressed(required_action) :
					#input_valid_nb += 1
					#continue
			#if input_valid_nb == self.expected_actions.size():
				#return PENDING
			#else : 
				#return FAILED
		#elif current_x >= end - stride:
			#var input_valid_nb = 0
			#for required_action in self.expected_actions:
				#if Input.is_action_just_released(required_action) :
					#input_valid_nb += 1
					#continue
			#if input_valid_nb == self.expected_actions.size():
				#return SUCCEED
	#
func get_serie() -> Array[Vector2]:
	return time_serie

func inject_pulse(pulse, i_triggers):
	for i in pulse.size():
		pulse[i] *= xy_scale
	var path = pulse.slice(1,pulse.size())
	triggers.append_array(i_triggers)
	time_serie.append_array(path)

func add_flat_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, BASELINE_H), Vector2(offset_x + stride_x, BASELINE_H)]
	inject_pulse(pulse, [])
	
func add_simple_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, BASELINE_H), Vector2(offset_x + stride_x * 0.2, MEDIUM_H), Vector2(offset_x + stride_x * 0.4, DOWN_MEDIUM_H), Vector2(offset_x + stride_x * 0.6, BASELINE_H), Vector2(offset_x + stride_x * 1.0, BASELINE_H)]
	inject_pulse(pulse, [PushTrigger.new(time_serie.size()-1, offset_x, stride_x)])

func add_regular_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, BASELINE_H), Vector2(offset_x + stride_x * 0.2, HIGH_H), Vector2(offset_x + stride_x * 0.4, 1.0 - HIGH_H), Vector2(offset_x + stride_x * 0.6, MEDIUM_H), Vector2(offset_x + stride_x * 1.0, 0.5)]
	inject_pulse(pulse, [PushTrigger.new(time_serie.size()-1, offset_x, stride_x)])

func add_slice_up_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, BASELINE_H), Vector2(offset_x + stride_x * 0.6, HIGH_H), Vector2(offset_x + stride_x * 0.7, BASELINE_H), Vector2(offset_x + stride_x * 1.0, BASELINE_H)]
	inject_pulse(pulse, [SlideTrigger.new(time_serie.size()-1, time_serie.size(), offset_x, stride_x)])
	
func add_bouingbouing_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, BASELINE_H), Vector2(offset_x + stride_x * 0.05, 0.9), Vector2(offset_x + stride_x * 0.35, 0.15), Vector2(offset_x + stride_x * 0.5, 0.7), Vector2(offset_x + stride_x * 0.7, 0.4), Vector2(offset_x + stride_x * 0.95, 0.55),Vector2(offset_x + stride_x * 1.0, BASELINE_H)]
	inject_pulse(pulse, [PushTrigger.new(time_serie.size()-1, offset_x, stride_x)])
	
func add_ressort_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, BASELINE_H), Vector2(offset_x + stride_x * 0.2, 0.8), Vector2(offset_x + stride_x * 0.4, 0.2), Vector2(offset_x + stride_x * 0.6, 0.8), Vector2(offset_x + stride_x * 0.8, 0.2), Vector2(offset_x + stride_x, 0.8), Vector2(offset_x + stride_x * 1.2, 0.2), Vector2(offset_x + stride_x * 1.4, 0.8), Vector2(offset_x + stride_x * 1.6, 0.2), Vector2(offset_x + stride_x * 1.8, 0.8), Vector2(offset_x + stride_x * 2.0, BASELINE_H)]
	inject_pulse(pulse, [SlideTrigger.new(time_serie.size()-1, time_serie.size(), offset_x, stride_x * 2)])

func _ready() -> void:
	xy_scale.y = get_viewport().get_visible_rect().size.y
	
	
	var content = Partition.new().partition.strip_edges().split(",") # FileAccess.open("res://partition.txt", FileAccess.READ).get_as_text().strip_edges().split(",")
	var pulses_types = []
	for pulse_type in content:
		pulses_types.append(int(pulse_type))
	
	# Init the number of particules
	player_visual(0)

	var index = 0
	time_serie.append(Vector2(0,BASELINE_H))
	for pulse_type in pulses_types:
		if pulse_type == PULSE_FLAT:
			add_flat_pulse(index * stride_x, stride_x)
		if pulse_type == PULSE_BEAT:
			add_simple_pulse(index * stride_x, stride_x)
		elif pulse_type == PULSE_CHORD:
			add_regular_pulse(index * stride_x, stride_x)
		elif pulse_type == PULSE_SLICE_UP:
			add_slice_up_pulse(index * stride_x, stride_x)
		elif pulse_type == BOUING_BOUING:
			add_bouingbouing_pulse(index * stride_x, stride_x)
		elif pulse_type == RESSORT:
			add_ressort_pulse(index * stride_x, stride_x)
			index += 1
		var str = str(index)
		$TextureButton.text = str
		$TextureButton.position.x = index * stride_x
		var tb = $TextureButton.duplicate()
		self.add_child(tb)
		index += 1
		
	$Line2D.points = time_serie

	for trigger in triggers:
		var columns = trigger.create_column($TriggerPush)
		for column in columns:
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
			
	return null
	
func _process(delta: float) -> void:
	if  Engine.is_editor_hint():
		return
	
	# Easy mode for score 
	player_visual(combo)
	
	current_time += delta
	
	$Camera2D/LabelScore.text = "score: " + str(score) + " combo: " + str(combo)
	
	var minutes = int(current_time) / 60
	var seconds = int(current_time) % 60
	var decimal : float = current_time - int(current_time)
	if decimal < 0.5:
		decimal = 0
	else:
		decimal = 0.5
 
	var a = 1       if decimal == 0.5 else 0
	$Camera2D/Label.text = str("time: ", str(minutes), "m ", str(seconds), "s ", str(decimal), " b ", str((minutes * 60 + seconds) * 2 + a))
	
	var current_position = _get_path_current_position(current_time)
	
	if current_position == null:
		end_game.emit(score)
	else:
		$Camera2D.position.x = current_position.x
		$Circle.position = current_position
		$CircleRythm1.position.x = current_position.x
		$CircleRythm2.position.x = current_position.x
		
		if Input.is_action_just_pressed("pause"):
			$Camera2D/PauseMenu.visible = true
			emit_signal("set_pause")
		
		if trigger_miss :
			trigger_miss = false
			# print("MISS")
			# $AnimationPlayer.play("slower")
		
		if (current_position.x > triggers[current_trigger_idx].get_next_trigger_x()) && (current_trigger_idx < (triggers.size() - 1)):
			if triggers[current_trigger_idx].state in [PENDING, WAITING]:
				pass
				# print("MISS")
				# $AnimationPlayer.play("slower")
			current_trigger_idx += 1
		
		if current_trigger_idx < triggers.size():
			var current_trigger = triggers[current_trigger_idx]
		
			var status = current_trigger.has_succeed(current_position.x)
			match status:	
				SUCCEED:
					print("GOOD")
					current_trigger = null
					$AnimationPlayer.play("success")
					score += 1
					combo += 1
				FAILED:
					print("BAD")
					current_trigger = null
					# $AnimationPlayer.play("slower")
					combo = 0
				PENDING:
					print("PENDING")
					combo = 0
				WAITING:
					print("WAITING")
					combo = 0
				UNEXPECTED:
					print("UNEXPECTED")
					combo = 0
					# $AnimationPlayer.play("slower")
				TOO_LATE:
					print("TOO_LATE")
					combo = 0
					# $AnimationPlayer.play("slower")
				TOO_SOON:
					print("TOO_SOON")
					combo = 0
					# $AnimationPlayer.play("slower")
				_:
					pass

func active_wave():
	$Wave.position = $Circle.global_position

func _on_rythm_1_kick_succeed() -> void:
	score += 2
	$AnimationPlayer.play("kick_success")


func _on_rythm_2_kick_succeed() -> void:
	score += 5
	$AnimationPlayer.play("clap_success")
