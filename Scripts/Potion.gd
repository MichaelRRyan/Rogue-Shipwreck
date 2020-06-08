extends Node2D

var tile = Vector2()
var is_food = false

func init(x, y):
	tile = Vector2(x, y)
	position = tile * 32 + Vector2(8, 8)
	$Sprite.frame = randi() % $Sprite.hframes
	is_food = $Sprite.frame == 3

func get_type():
	return $Sprite.frame