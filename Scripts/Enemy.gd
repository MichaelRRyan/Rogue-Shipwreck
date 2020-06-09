extends KinematicBody2D

signal died

const TILE_SIZE = 32

var tile
var full_hp = 0
var hp = 0
var dead = 0
var pathfinding_ref
var player_ref
var circles = []
var attack_cooldown = 0
const ATTACK_TIME = 1

onready var Circle = preload("res://Scenes/Circle.tscn")
	
func init(enemy_level, tile_pos, pathfinding, player):
		full_hp = 1 + enemy_level * 2
		hp = full_hp
		tile = tile_pos
		#$Sprite.frame = enemy_level
		position = tile * TILE_SIZE + Vector2(16, 16)
		pathfinding_ref = pathfinding
		player_ref = player

func take_damage(dmg):
	if dead:
		return

	hp = max(0, hp - dmg)
	$HPBar.rect_size.x = TILE_SIZE * hp / full_hp
	$HitEffect.emitting = true

	if hp == 0:
		dead = true
		emit_signal("died")

func _physics_process(delta):
	if !visible || dead:
		return
	
	if attack_cooldown > 0:
		attack_cooldown -= delta
		if attack_cooldown < 0:
			attack_cooldown = 0
	
	var my_point = pathfinding_ref.get_closest_point(Vector3(tile.x, tile.y, 0))
	var player_point = pathfinding_ref.get_closest_point(Vector3(player_ref.tile.x, player_ref.tile.y, 0))
	var path = pathfinding_ref.get_point_path(my_point, player_point)
	
	if path:
		if path.size() > 2:
			var target_point = Vector2(path[1].x * TILE_SIZE, path[1].y * TILE_SIZE) + Vector2(16, 16)
			var velocity = (target_point - position).normalized() * 80
			
			if velocity.x < 0:
				$Sprite.flip_h = true
			else:
				$Sprite.flip_h = false
			
			velocity = move_and_slide(velocity)
			tile = Vector2(int(position.x / TILE_SIZE), int(position.y / TILE_SIZE))
			
			#draw_path()
		else:
			if attack_cooldown == 0:
				var vector_to_player = player_ref.position - position
				if vector_to_player.length() < 32:
					player_ref.damage(1)
					attack_cooldown = ATTACK_TIME
				else:
					vector_to_player = move_and_slide(vector_to_player.normalized() * 80)

func draw_path(path):
	for circle in circles:
		circle.queue_free()
	circles.clear()

	for step in path:
		var step_pos =  Vector2(step.x * TILE_SIZE + 16, step.y * TILE_SIZE + 16) - position

		var new_circle = Circle.instance()
		new_circle.init(step_pos, 1, Color(255, 0, 0))
		add_child(new_circle)
		circles.append(new_circle)