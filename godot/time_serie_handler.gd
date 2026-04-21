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
var combo_max = 0

# Game feel variables
var start_scale_size = 0.8
var combo_scale_factor = 0.1
var max_scale_size = 1.8
var max_particules_amount = 2000
var line_thickness_max = 0.1

var old_intensity = 0

var animation_stacker = []
var animation_looping = false

func player_visual(intensity: int):
	if intensity > combo_max:
		combo_max = intensity
	var scale_size = start_scale_size + max(intensity, max_scale_size) * combo_scale_factor
	$Circle.scale.x = min(max_scale_size, scale_size)
	$Circle.scale.y = min(max_scale_size, scale_size)

	$Circle/GPUParticles2D.amount_ratio = max(intensity / 10.0, 0.1)
	$Circle/GPUParticles2D.emitting = intensity > 0
	
	if intensity >= 10:
		var p = intensity - 10
		$Camera2D/GPUParticles2D.amount_ratio = max(p / 10.0, 0.1)
		$Camera2D/GPUParticles2D.amount = 600 if p > 0 else 1
	else:
		$Camera2D/GPUParticles2D.amount = 1
	
	if intensity == 0:
		$Camera2D/GPUParticles2D.visible = false
		$Circle/GPUParticles2D.visible = false
	else :
		$Camera2D/GPUParticles2D.visible = true
		$Circle/GPUParticles2D.visible = true

	
	var thickness_scale_size = min(intensity / 50.0, 0.1)
	if intensity == 0:
		$Line2D.material.set_shader_parameter("thickness", 0.015)
		$Line2D.material.set_shader_parameter("outline_thickness", 0.015)
	else:
		$Line2D.material.set_shader_parameter("thickness", thickness_scale_size)
		$Line2D.material.set_shader_parameter("outline_thickness", thickness_scale_size)
	
	var start_vibration = 15
	if intensity > start_vibration:
		var intens = intensity - start_vibration
		var val = max(intens / 15.0, 3)
		$Circle.offset.x = randf_range(-val, val)
		$Circle.offset.y = randf_range(-val, val)
	else:
		$Circle.offset.x = 0.0
		$Circle.offset.y = 0.0
		
	if intensity == 50 and old_intensity != 50:
		var triggers = $Line2D.get_children()
		for i in triggers:
			if i.name.contains("Push"):
				i.visible = false
	elif intensity < 50 and old_intensity >= 50:
		var triggers = $Line2D.get_children()
		for i in triggers:
			if i.name.contains("Push"):
				i.visible = true
	
	if intensity == 40 and old_intensity != 40:
		animation_stacker.append(["SupportMotherPlaying", true])
	elif intensity < 40 and old_intensity >= 40:
		animation_stacker.append(["SupportMotherStop", true])
		
	if intensity == 35  and old_intensity != 35:
		animation_stacker.append(["SupportMother", true])
	elif intensity < 35 and old_intensity >= 35:
		animation_stacker.append(["SupportMother", false])
		
	if intensity == 30 and old_intensity != 30:
		animation_stacker.append(["Support2", true])
	elif intensity < 30 and old_intensity >= 30:
		animation_stacker.append(["Support2", false])

	if intensity == 25 and old_intensity != 25:
		animation_stacker.append(["Support1", true])
	elif intensity < 25 and old_intensity >= 25:
		animation_stacker.append(["Support1", false])
		
	if intensity == 20 and old_intensity != 20:
		animation_stacker.append(["Support0", true])
	elif intensity < 20 and old_intensity >= 20:
		animation_stacker.append(["Support0", false])
	
		
	var a = not $Camera2D/Supports.is_playing()
	var b = ($Camera2D/Supports.is_playing() and animation_looping)
	var c = not animation_stacker.is_empty()
	if (not $Camera2D/Supports.is_playing() or ($Camera2D/Supports.is_playing() and animation_looping)) and not animation_stacker.is_empty():
		if animation_looping:
			$Camera2D/Supports.stop()
		if animation_stacker[0][1]:
			$Camera2D/Supports.play(animation_stacker[0][0])
		else:
			$Camera2D/Supports.play(animation_stacker[0][0], -1, -3.0, true)
			
		if animation_stacker[0][0] == "SupportMotherPlaying":
			animation_looping = true
		else:
			animation_looping = false
				
		animation_stacker.pop_front()

	old_intensity = intensity
		


func play_hot_line(trigger, active):
	if active:
		var subline = time_serie.slice(trigger.position_index[0], trigger.position_index[1])
		subline[-1] = _get_path_position(subline[-1].x - 10)
		#$HotLine.material.set_shader_parameter("thickness", $Line2D.material.get_shader_parameter("thickness") * 8)
		#$HotLine.material.set_shader_parameter("outline_thickness", $Line2D.material.get_shader_parameter("outline_thickness") * 8)
		$HotLine.points = subline
		$HotLine.visible = true
	else:
		$HotLine.visible = false

class PushTrigger:
	var position_index : Array[int]
	var expected_actions = ["ui_button0"]
	var stride_x: float
	var offset
	var state: int

	func _init(index, stride_x_):
		position_index = [index]
		self.stride_x = stride_x_
		offset = stride_x * 0.5
		self.state = PENDING
		
	func create_column(triggers, root):
		var trigger_x = root.time_serie[position_index[0]].x
		var trigger = triggers[0].duplicate()
		root.find_child("Line2D").add_child(trigger)
		trigger.set_name("Push")
		trigger.scale /= 1.8
		trigger.position = root._get_path_position(trigger_x)

	# The idea is: if the current x position of the player is higher than
	# get_next_trigger_x, we go to the next Trigger object.
	func get_next_trigger_x(root) -> float:
		return root.time_serie[position_index[0]].x + offset

	func has_succeed(current_x: float, root):
		var trigger_x = root.time_serie[position_index[0]].x
		var trigger_range = [trigger_x - offset, trigger_x + offset]
		for required_action in self.expected_actions:
			if Input.is_action_just_pressed(required_action):
				if self.state != PENDING:
					return UNEXPECTED
				if current_x > trigger_range[1]:
					self.state = TOO_LATE
				elif current_x < trigger_range[0]:
					self.state = TOO_SOON
				else:
					self.state = SUCCEED
				return self.state
		return NONE

class SlideTrigger:
	var position_index : Array[int]
	var expected_actions = ["ui_button0"]
	var state = PENDING
	var offset
	var stride_x = 0

	func _init(index, index2, i_stride_x):
		position_index = [index, index2]
		stride_x = i_stride_x
		offset = stride_x * 0.5

	func create_column(triggers, root) -> Array[Node]:
		# first trigger
		var trigger_x = root.time_serie[position_index[0]].x
		var trigger = triggers[1].duplicate()
		root.find_child("Line2D").add_child(trigger)
		trigger.scale = Vector2(0.4,0.4)
		trigger.modulate = Color(1.0, 0.843, 0.0, 1.0)
		trigger.position = root._get_path_position(trigger_x)
		
		# second trigger
		trigger_x = root.time_serie[position_index[1]].x
		var trigger2 = trigger.duplicate()
		root.find_child("Line2D").add_child(trigger2)
		trigger2.position = root._get_path_position(trigger_x)
		return [trigger, trigger2]
		
	func get_next_trigger_x(root) -> float:
		return root.time_serie[position_index[1]].x + offset

	func has_succeed(current_x, root):
		var first_trigger_x = root.time_serie[position_index[0]].x
		var second_trigger_x = root.time_serie[position_index[1]].x
		var first_trigger_range = [first_trigger_x - offset, first_trigger_x + offset]
		var second_trigger_range = [second_trigger_x - offset, second_trigger_x + offset]
		
#		When the Trigger is over, or if the start in not reached.
		if state in [SUCCEED, FAILED] || current_x < first_trigger_range[0]:
			for action in self.expected_actions:
				if Input.is_action_just_pressed(action):
					return UNEXPECTED

#		When the Trigger has the button pressed.
		elif state == WAITING:
			for action in self.expected_actions:
				if Input.is_action_just_released(action):
					if current_x >= first_trigger_range[0]:
						state = SUCCEED
						return SUCCEED
					else:
						state = FAILED
						return FAILED

#		When the Trigger wait the just press action.
		elif current_x >= first_trigger_range[0] && current_x <= first_trigger_range[1]:
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
	inject_pulse(pulse, [PushTrigger.new(time_serie.size()-1, stride_x)])

func add_regular_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, BASELINE_H), Vector2(offset_x + stride_x * 0.2, HIGH_H), Vector2(offset_x + stride_x * 0.4, 1.0 - HIGH_H), Vector2(offset_x + stride_x * 0.6, MEDIUM_H), Vector2(offset_x + stride_x * 1.0, 0.5)]
	inject_pulse(pulse, [PushTrigger.new(time_serie.size()-1, stride_x)])

func add_slice_up_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, BASELINE_H), Vector2(offset_x + stride_x * 0.6, HIGH_H), Vector2(offset_x + stride_x * 0.8, BASELINE_H), Vector2(offset_x + stride_x * 1.0, BASELINE_H)]
	inject_pulse(pulse, [SlideTrigger.new(time_serie.size()-1, time_serie.size() - 2 + pulse.size() - 2, stride_x)])
	
func add_bouingbouing_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, BASELINE_H), Vector2(offset_x + stride_x * 0.05, 0.9), Vector2(offset_x + stride_x * 0.35, 0.15), Vector2(offset_x + stride_x * 0.5, 0.7), Vector2(offset_x + stride_x * 0.7, 0.4), Vector2(offset_x + stride_x * 0.95, 0.55),Vector2(offset_x + stride_x * 1.0, BASELINE_H)]
	inject_pulse(pulse, [SlideTrigger.new(time_serie.size()-1, time_serie.size() - 2 + pulse.size(), stride_x * 2)])
	
func add_ressort_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, BASELINE_H), Vector2(offset_x + stride_x * 0.2, 0.8), Vector2(offset_x + stride_x * 0.4, 0.2), Vector2(offset_x + stride_x * 0.6, 0.8), Vector2(offset_x + stride_x * 0.8, 0.2), Vector2(offset_x + stride_x, 0.8), Vector2(offset_x + stride_x * 1.2, 0.2), Vector2(offset_x + stride_x * 1.4, 0.8), Vector2(offset_x + stride_x * 1.6, 0.2), Vector2(offset_x + stride_x * 1.8, 0.8), Vector2(offset_x + stride_x * 2.0, BASELINE_H)]
	inject_pulse(pulse, [SlideTrigger.new(time_serie.size()-1, time_serie.size() - 2 + pulse.size(), stride_x * 2)])

func _ready() -> void:
	xy_scale.y = get_viewport().get_visible_rect().size.y
	
	var content = Partition.new().partition.strip_edges().split(",") # FileAccess.open("res://partition.txt", FileAccess.READ).get_as_text().strip_edges().split(",")
	var pulses_types = []
	for pulse_type in content:
		pulses_types.append(int(pulse_type))
	
	# Init the number of particules
	player_visual(0)

	var index = 0
	time_serie.append(Vector2(0,BASELINE_H) * xy_scale)
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
		trigger.create_column([$TriggerPush, $TriggerHold], self)

	
func _get_path_position(pos_x):
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
	
func _get_path_current_position(time : float):
	var pos_x = time * velocity_x
	return _get_path_position(pos_x)
	
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
		end_game.emit(score, combo_max)
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
		
		if (current_position.x > triggers[current_trigger_idx].get_next_trigger_x(self)) && (current_trigger_idx < (triggers.size() - 1)):
			if triggers[current_trigger_idx].state in [PENDING, WAITING]:
				pass
			if triggers[current_trigger_idx].state != SUCCEED:
				combo = 0
			current_trigger_idx += 1
		
		if current_trigger_idx < triggers.size():
			var current_trigger = triggers[current_trigger_idx]
		
			var status = current_trigger.has_succeed(current_position.x, self)
			match status:	
				SUCCEED:
					print("GOOD")
					$AnimationPlayer.play("success")
					if current_trigger is SlideTrigger :
						score += 2
						combo += 2
					else:
						score += 1
						combo += 1
					play_hot_line(current_trigger, false)
					current_trigger = null
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
					play_hot_line(current_trigger, true)
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
