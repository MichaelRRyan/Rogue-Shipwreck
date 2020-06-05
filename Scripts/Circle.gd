extends Control

var position = Vector2(0, 0)
var radius = 0
var color = Color(0, 0, 0)

func init(t_position, t_radius, t_color):
	position = t_position
	radius = t_radius
	color = t_color
	update()

func _draw():
	draw_circle(position, radius, color)