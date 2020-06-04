extends Node2D

var tile
var full_hp = 0
var hp = 0
var dead = 0
	
func init(enemy_level, tile_pos):
		full_hp = 1 + enemy_level * 2
		hp = full_hp
		tile = tile_pos
		$Sprite.frame = enemy_level
		position = tile * 16

func take_damage(dmg):
	if dead:
		return

	hp = max(0, hp - dmg)
	$HPBar.rect_size.x = 16 * hp / full_hp

	if hp == 0:
		dead = true

func act(pathfinding, enemies, player):
	if !visible || dead:
		return

	var my_point = pathfinding.get_closest_point(Vector3(tile.x, tile.y, 0))
	var player_point = pathfinding.get_closest_point(Vector3(player.tile.x, player.tile.y, 0))
	var path = pathfinding.get_point_path(my_point, player_point)
	if path:
		assert(path.size() > 1)
		var move_tile = Vector2(path[1].x, path[1].y)

		if move_tile == player.tile:
			player.damage(1)
		else:
			var blocked = false
			for enemy in enemies:
				if enemy.tile == move_tile:
					blocked = true
					break

			if !blocked:
				tile = move_tile
				position = tile * 16