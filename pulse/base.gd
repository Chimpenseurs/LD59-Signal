class_name PulseBase

enum Combo {
	UP,
	DOWN,
}

enum Combo_state {
	# State when the player did the good input but too soon.
	TOO_SOON,
	
	# State when the player did the good input but slightly too late.
	TOO_LATE,
	
	# State when the player did the good input at time.
	GOOD,
	
	# State when the player pushed a wrong input.
	BAD,
	
	# State when the player didn't send a signal at all.
	MISSED,

	# State when the pulse expect a signal from the player.
	WAITING_NEXT_TRIGGER,

	# State when the player push input when the Pulse doesn't expect signal.
	UNEXPECTED_TRIGGER,
}

const BASELINE_H = 0.5
const MEDIUM_H = 0.3
const HIGH_H = 0.1

var total_time: float
var state: Combo_state
var offset_x: float
var time_serie: Array[Vector2]
var trigger_start: float
var trigger_end: float
var combo_idx: int
var expected_combos: Array[Combo]

func _init(offset_x: float):
	self.offset_x = offset_x
	self.state = Combo_state.WAITING_NEXT_TRIGGER

func get_pulse() -> Array[Vector2]:
	return self.time_serie

func get_trigger_end() -> float:
	return self.trigger_end

func _handle_combo(combo: Combo, current_x: float) -> Combo_state:
	assert(false, "Not implemented for PulseBase class.")
	return Combo_state.GOOD

func handle_input(input: Input, current_x: float) -> Combo_state:
	if input.is_action_just_pressed("ui_up"):
		if self.state == Combo_state.WAITING_NEXT_TRIGGER:
			return self._handle_combo(Combo.UP, current_x)
		return Combo_state.UNEXPECTED_TRIGGER

	if input.is_action_just_pressed("ui_down"):
		if self.state == Combo_state.WAITING_NEXT_TRIGGER:
			return self._handle_combo(Combo.DOWN, current_x)
		return Combo_state.UNEXPECTED_TRIGGER

	return self.Combo_state
