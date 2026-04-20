@tool

extends Line2D

var time_serie = []
var triggers = []
var trigger_miss = false
var current_trigger

var xy_scale = Vector2(1.0,1)

var bpm = 129

var bps = bpm / 60 # bpm but per seconds
var stride_x = 200

var velocity_x : float = stride_x * bps

const BASELINE_H = 0.5

func create_kit(pos: Vector2) -> Line2D:
	var kit = Line2D.new()
	kit.default_color = Color("00c300")
	kit.add_point(Vector2(pos.x, pos.y-5.0))
	kit.add_point(Vector2(pos.x, pos.y+5.0))
	
	return kit

func inject_pulse(pulse, i_triggers):
	for i in pulse.size():
		pulse[i] *= xy_scale
	var path = pulse.slice(1,pulse.size())
	triggers.append_array(i_triggers)
	time_serie.append_array(path)

func add_flat_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, BASELINE_H), Vector2(offset_x + stride_x, BASELINE_H)]
	inject_pulse(pulse, [])

func add_kit_pulse(offset_x, stride_x):
	var pulse = [Vector2(offset_x, BASELINE_H), Vector2(offset_x + stride_x, BASELINE_H)]
	
	var kit = Line2D.new()
	kit.width = 2.0
	kit.points = [Vector2(offset_x-offset_x/2.0, BASELINE_H-15.0), Vector2(offset_x-offset_x/2.0, BASELINE_H+15.0)]
	kit.default_color = Color("00c300")
	
	self.add_child(kit)
	
	var kit2 = Line2D.new()
	kit2.width = 2.0
	kit2.points = [Vector2(offset_x+offset_x/2.0, BASELINE_H-15.0), Vector2(offset_x+offset_x/2.0, BASELINE_H+15.0)]
	kit2.default_color = Color("00c300")
	self.add_child(kit2)
	
	inject_pulse(pulse, [])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var stride_x = 200
	var content = FileAccess.open("res://partition_rythm1.txt", FileAccess.READ).get_as_text().strip_edges().split(",")
	time_serie.append(Vector2(0,0.5)) # BASELINE
	var pulses_types = []
	for i in range(0, len(content)):
		if int(content[i]) == 0: # flat
			add_flat_pulse(i * stride_x, stride_x)
		elif int(content[i]) == 1: # kit
			add_kit_pulse(i * stride_x, stride_x)
	
	self.points = time_serie


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
