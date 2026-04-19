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
	super._init(offset_x, stride_x)
	self.trigger_start = offset_x - 0.1 * stride_x
	self.trigger_end = offset_x + 0.1 * stride_x
	self._set_time_serie(stride_x)
	self.expected_combos = [Combo.UP]

func _handle_combo(combo: Combo, current_x: float) -> Combo_state:
#	Implement your combo logic here.
	if combo == self.expected_combos[combo_idx]:
		#print(current_x)
		if current_x < self.trigger_start:
			print("TOO_SOON")
			return Combo_state.TOO_SOON
		elif current_x > self.trigger_end:
			print("TOO_LATE")
			return Combo_state.TOO_LATE
		else:
			print("GOOD")
			self.combo_idx += 1
			return Combo_state.GOOD
	else:
		print("BAD")
		return Combo_state.BAD

func get_trigger_end() -> float:
	return self.trigger_end + 0.5 * stride_x
