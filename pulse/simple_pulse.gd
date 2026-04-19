class_name SimplePulse

extends PulseBase

func _set_time_serie(stride_x: float):
	self.time_serie = [
		Vector2(offset_x, BASELINE_H),
		Vector2(offset_x + stride_x * 0.5, MEDIUM_H),
		Vector2(offset_x + stride_x * 0.9, BASELINE_H),
		Vector2(offset_x + stride_x * 1.0, BASELINE_H)
	]

func _init(offset_x: float, stride_x: float):
	super._init(offset_x)
	self.trigger_start = offset_x - 5
	self.trigger_end = offset_x + 5
	self._set_time_serie(stride_x)

func get_pulse() -> Array[Vector2]:
	return self.time_serie
	
func get_end_combo_trigger() -> float:
	return self.trigger_end

func send_user_input(input: Input, current_x: float) -> Combo_state:
	if self.state == Combo_state.WAITING_NEXT:
#	Implement your combo logic here.
		if input.is_action_just_pressed("ui_up"):
			#print(current_x)
			if current_x < self.trigger_start:
				print("TOO_SOON")
				return Combo_state.TOO_SOON
			elif current_x > self.trigger_end:
				print("TOO_LATE")
				return Combo_state.TOO_LATE
			else:
				print("GOOD")
				return Combo_state.GOOD
		else:
			print("BAD")
			return Combo_state.BAD
	else:
		return self.state
