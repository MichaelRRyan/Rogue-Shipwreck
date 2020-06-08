extends KinematicBody2D

signal died

var tile
var full_hp = 0
var hp = 0
var dead = 0
var pathfinding_ref
var player_ref
var circles = []

onready var Circle = preload("res://Scenes/Circle.tscn")
	
func init(enemy_level, tile_pos, pathfinding, player):
		full_hp = 1 + enemy_level * 2
		hp = full_hp
		tile = tile_pos
		$Sprite.frame = enemy_level
		position = tile * 16 + Vector2(8, 8)
		pathfinding_ref = pathfinding
		player_ref = player

func take_damage(dmg):
	if dead:
		return

	hp = max(0, hp - dmg)
	$HPBar.rect_size.x = 16 * hp / full_hp

	if hp == 0:
		dead = true
		emit_signal("died")

func _physics_process(_delta):
	if !visible || dead:
		return
	
	var my_point = pathfinding_ref.get_closest_point(Vector3(tile.x, tile.y, 0))
	var player_point = pathfinding_ref.get_closest_point(Vector3(player_ref.tile.x, player_ref.tile.y, 0))
	var path = pathfinding_ref.get_point_path(my_point, player_point)
	
	if path:
		if path.size() > 2:
			var target_point = Vector2(path[1].x * 16, path[1].y * 16) + Vector2(8, 8)
			var velocity = (target_point - position).normalized() * 80
			velocity = move_and_slide(velocity)
			tile = Vector2(int(position.x / 16), int(position.y / 16))
			
			#draw_path()

func draw_path(path):
	for circle in circles:
		circle.queue_free()
	circles.clear()

	for step in path:
		var step_pos =  Vector2(step.x * 16 + 8, step.y * 16 + 8) - position

		var new_circle = Circle.instance()
		new_circle.init(step_pos, 1, Color(255, 0, 0))
		add_child(new_circle)
		circles.append(new_circle)