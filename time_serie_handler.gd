class_name Game
extends Node

var current_time = 0.0
var total_time = 10.0
@export var xy_scale = Vector2(10,2)
@export var time_scale = 1.0

# Let suppose an interval between 2 points is 20
# If t = 33, the point before t is time_serie[1] and
# we need to lerp at 13/20 from time_serie[1] to time_serie[2]
var time_serie = [
	Vector2(0, 10),
	Vector2(10, 90),
	Vector2(15, 50),
	Vector2(30, 60),
	Vector2(40, 20),
	Vector2(42, 50),
	Vector2(48, 10),
	Vector2(55, 90),
	Vector2(59, 60),
	Vector2(70, 70),
	Vector2(82, 10),
	Vector2(100, 30),
]

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
#func _get_last_point() -> Vector2:
	#var t_right = t + display_size.x
	#var point_after = ((t_right - fmod(t_right, INTERVAL_SIZE)) / INTERVAL_SIZE) + 1
	#point_after = min(point_after, len(time_serie) - 1)
	#var lerp_val = (fmod(t, INTERVAL_SIZE)) / INTERVAL_SIZE
#
	#return _lerp(time_serie[point_after - 1], time_serie[point_after], lerp_val)
#
#func incr_y_by(n: int) -> void:
	#y += n
#
#func decr_y_by(n: int) -> void:
	#y -= n
#
#func get_y() -> int:
	#return y
	#
func get_serie() -> Array[Vector2]:
	return time_serie
#
#func get_serie_interval() -> Array:
##	Get the point of the left border of the screen.
	#var first_point = _get_first_point()
#
##	Get the point of the right border of the screen.
	#var last_point = _get_last_point()
#
##	Get the points in the time serie included in the screen.
	#var points = self.time_serie.slice(
		#((t - fmod(t, INTERVAL_SIZE)) / INTERVAL_SIZE) + 1,
		#max(
			#(t + 100 - fmod(t, INTERVAL_SIZE)) / INTERVAL_SIZE,
			#len(time_serie) - 1
		#)
	#)
	#
##	Add the points of the border of the screen.
	#points.push_front(first_point)
	#points.push_back(last_point)
	#return points

func _ready() -> void:
	var curve = Curve2D.new()
	for i in time_serie.size():
		time_serie[i] *= xy_scale
		curve.add_point(time_serie[i])
	$Line2D.points = time_serie
	$Path2D.curve = curve


func _process(delta: float) -> void:
	current_time += delta
	$Path2D/PathFollow2D.set_progress_ratio(current_time * time_scale)
	pass
