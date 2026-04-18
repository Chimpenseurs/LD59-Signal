class_name Game
extends Node2D

const DISPLAY_SIZE = 100
const INTERVAL_SIZE = 20

var y

var t = 0.0

# Let suppose an interval between 2 points is 20
# If t = 33, the point before t is time_serie[1] and
# we need to lerp at 13/20 from time_serie[1] to time_serie[2]
var time_serie = [
	Vector2(0, 0),
	Vector2(1, 1),
	Vector2(2, 0),
	Vector2(3, 1),
	Vector2(4, 0),
	Vector2(5, 2),
	Vector2(6, 0),
]

func _lerp(pt1: Vector2, pt2: Vector2, lerp: float) -> Vector2:
	return Vector2(
		(pt2.x - pt1.x) * lerp,
		(pt2.y - pt1.y) * lerp
	)

func _get_first_point() -> Vector2:
	var point_before = (t - (t % INTERVAL_SIZE)) / INTERVAL_SIZE
	var lerp_val = (t % INTERVAL_SIZE) / INTERVAL_SIZE

	if point_before + 1 < len(time_serie):
		return _lerp(
			time_serie[point_before],
			time_serie[point_before + 1],
			lerp_val)
	
#	Return null point at end of game.
	return Vector2(0, 0)

func _get_last_point() -> Vector2:
	var t_right = t + 100
	var point_after = ((t_right - t_right % INTERVAL_SIZE) / INTERVAL_SIZE) + 1
	var lerp_val = (t % INTERVAL_SIZE) / INTERVAL_SIZE

	return _lerp(point_after - 1, point_after, lerp_val)

func incr_y_by(n: int) -> void:
	y += n

func decr_y_by(n: int) -> void:
	y -= n

func get_y() -> int:
	return y
	
func get_serie() -> Array[Vector2]:
	return time_serie

func get_serie_interval() -> Array[Vector2]:
#	Get the point of the left border of the screen.
	var first_point = _get_first_point()

#	Get the point of the right border of the screen.
	var last_point = _get_last_point()

#	Get the points in the time serie included in the screen.
	var points = self.time_serie.slice(
		((t - t % INTERVAL_SIZE) / INTERVAL_SIZE) + 1,
		max(
			(t + 100 - t % INTERVAL_SIZE) / INTERVAL_SIZE,
			len(time_serie) - 1
		)
	)
	
#	Add the points of the border of the screen.
	points.push_front(first_point)
	points.push_back(last_point)
	return points

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	t += delta
	
	# position actuelle du joueur
	# position du dernier pic
	
	# si le joueur est en dehors du parcours du signal
	# et que le bon bouton est appuye
	# alors on va faire revenir le joueur sur la courbe du signal
	
	# si le joueur est sur le parcours du signal
	# et que le mauvais bouton est appuye
	# alors on va faire deriver le joueur sur la courbe du signal
		
	#if Input.is_action_pressed("ui_up"):
		#up(delta)
		
	pass
