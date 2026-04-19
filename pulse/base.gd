class_name PulseBase

enum Combo_state { TOO_SOON, GOOD, BAD, MISSED, WAITING_NEXT }

var total_time: float
var state: Combo_state
var offset_t: float
var time_serie: Array[Vector2]
var trigger_start: float
var trigger_end: float

func _init(start: float):
	offset_t = start
	state = Combo_state.WAITING_NEXT

func get_pulse() -> Array[Vector2]:
	assert(false, "Abstract class method cannot be called")
	return []
	
func get_end_combo_trigger() -> float:
	assert(false, "Abstract class method cannot be called")
	return 0
	
func send_user_input(input: Input, t: float) -> Combo_state:
	assert(false, "Abstract class method cannot be called")
	return Combo_state.GOOD
