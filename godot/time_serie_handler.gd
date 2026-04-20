@tool

class_name Game
extends Node

signal set_pause

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

const SUCCEED = 0
const FAILED = 1
const PENDING = 2

@export var xy_scale = Vector2(1.0,1)

var bpm = 129

var bps = bpm / 60 # bpm but per seconds
var stride_x = 200

var velocity_x : float = stride_x * bps

var path_pixels_ref = 7839.0
var current_time = 0.0

var time_serie = []
var triggers = []
var trigger_miss = false
var current_trigger

class PushTrigger:
	var position_index : Array[int]
	var expected_actions = ["ui_button0"]
	func _init(index):
		position_index = [index]
	func has_succeed() :
		var input_valid_nb = 0
		for required_action in self.expected_actions:
			if Input.is_action_just_pressed(required_action) :
				input_valid_nb += 1
				continue
		if input_valid_nb == self.expected_actions.size():
			return SUCCEED

class SlideTrigger:
	var position_index : Array[int]
	var expected_actions = ["ui_button0"]
	func _init(index, index2):
		position_index = [index, index2]
	func has_succeed() :
		var input_valid_nb = 0
		for required_action in self.expected_actions:
			if Input.is_action_just_released(required_action) :
				input_valid_nb += 1
				continue
		return input_valid_nb == self.expected_actions.size()
	
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
	inject_pulse(pulse, [PushTrigger.new(time_serie.size()-1)])

func add_regular_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, BASELINE_H), Vector2(offset_x + stride_x * 0.2, HIGH_H), Vector2(offset_x + stride_x * 0.4, 1.0 - HIGH_H), Vector2(offset_x + stride_x * 0.6, MEDIUM_H), Vector2(offset_x + stride_x * 1.0, 0.5)]
	inject_pulse(pulse, [PushTrigger.new(time_serie.size()-1)])
	
func add_slice_up_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, BASELINE_H), Vector2(offset_x + stride_x * 0.6, HIGH_H), Vector2(offset_x + stride_x * 0.7, BASELINE_H), Vector2(offset_x + stride_x * 1.0, BASELINE_H)]
	inject_pulse(pulse, [SlideTrigger.new(time_serie.size()-1, time_serie.size()+1)])
		
func _ready() -> void:
	xy_scale.y = get_viewport().get_visible_rect().size.y
	
	var content = FileAccess.open("res://partition.txt", FileAccess.READ).get_as_text().strip_edges().split(",")
	var pulses_types = []
	for pulse_type in content:
		pulses_types.append(int(pulse_type))
	
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
		var str = str(index)
		$TextureButton.text = str
		$TextureButton.position.x = index * stride_x
		var tb = $TextureButton.duplicate()
		self.add_child(tb)
		index += 1
		
	$Line2D.points = time_serie

	for i in triggers.size():
		var column = $Column.duplicate()
		var texture_width = column.texture.width
		column.position.x = time_serie[triggers[i].position_index[0]].x - texture_width * 0.5
		column.trigger = triggers[i]
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
	
	var minutes = int(current_time) / 60
	var seconds = int(current_time) % 60
 
	$Camera2D/Label.text = str("time: ", str(minutes), "m ", str(seconds), "s")
	
	current_time += delta
	var current_position = _get_path_current_position(current_time)
	
	$Camera2D.position.x = current_position.x
	$Circle.position = current_position
	$CircleRythm1.position.x = current_position.x
	
	if Input.is_action_just_pressed("pause"):
		$Camera2D/PauseMenu.visible = true
		emit_signal("set_pause")
	
	if trigger_miss :
		trigger_miss = false
		print("MISS")
		$AnimationPlayer.play("slower")
	
	# if current_trigger == null and Input.is_action_just_pressed("ui_button0"):
	#   print("BAD")
	#   $AnimationPlayer.play("slower")

	if current_trigger :
		var status = current_trigger.has_succeed()
		if status == SUCCEED:
			print("GOOD")
			current_trigger = null
			$AnimationPlayer.play("success")
		elif status == FAILED:
			print("BAD")
			$AnimationPlayer.play("slower")
		elif status == PENDING:
			print("PENDING")

func _on_trigger_area_entered(column) -> void:
	current_trigger = column.trigger

func _on_area_2d_area_exited(area: Area2D) -> void:
	if current_trigger:
		trigger_miss = true
	current_trigger = null
	
func active_wave():
	$Wave.position = $Circle.global_position


func _on_rythm_1_kick_succeed() -> void:
	$AnimationPlayer.play("kick_success")
