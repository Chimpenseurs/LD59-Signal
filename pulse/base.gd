class_name PulseBase

enum Combo_state { TOO_SOON, TOO_LATE, GOOD, BAD, MISSED, WAITING_NEXT }

const BASELINE_H = 0.5
const MEDIUM_H = 0.3
const HIGH_H = 0.1

var total_time: float
var state: Combo_state
var offset_x: float
var time_serie: Array[Vector2]
var trigger_start: float
var trigger_end: float

func _init(offset_x: float):
	self.offset_x = offset_x
	self.state = Combo_state.WAITING_NEXT

func get_pulse() -> Array[Vector2]:
	assert(false, "Abstract class method cannot be called")
	return []
	
func get_end_combo_trigger() -> float:
	assert(false, "Abstract class method cannot be called")
	return 0
	
func send_user_input(input: Input, t: float) -> Combo_state:
	assert(false, "Abstract class method cannot be called")
	return Combo_state.GOOD
