extends Node2D

const TILE_SIZE = 16

const LEVEL_SIZES = [
	Vector2(30, 30),
	Vector2(35, 35),
	Vector2(40, 40),
	Vector2(45, 45),
	Vector2(50, 50),
]

const LEVEL_ROOM_COUNTS = [ 5, 7, 9, 12, 15 ]
const LEVEL_ENEMY_COUNTS = [ 5, 8, 12, 18, 26 ]
const LEVEL_ITEM_COUNTS = [ 3, 6, 12, 15, 20 ]

const EnemyScene = preload("res://Scenes/Enemy.tscn")

# Current level -----------------------------------------------

var level_num = 0
var enemies = []
var enemy_pathfinding

# Node refs ---------------------------------------------------

onready var level = $Level
onready var player = $Player
onready var visibility_map = $VisibilityMap

# Game State --------------------------------------------------

var game_paused = false

func _ready():
	randomize() # Randomize the random seed
	next_level() # Start the first level
	player.init(level, enemies, $CanvasLayer/BottomBar) # Initialise the player with a reference to the level

func _input(event):
	if !game_paused:
		if event.is_action_pressed("pause_game"):
			game_paused = true
			$CanvasLayer/PauseMenu.appear()
			return
		
		player.handle_input(event)

func next_level():
	
	# Build a new level
	level.build_level(LEVEL_SIZES[level_num], LEVEL_ROOM_COUNTS[level_num], LEVEL_ENEMY_COUNTS[level_num], LEVEL_ITEM_COUNTS[level_num])
	
	# Reset the visibility map
	for x in range(LEVEL_SIZES[level_num].x):
		for y in range(LEVEL_SIZES[level_num].y):
			visibility_map.set_cell(x, y, 0)
	
	# Clear the enemies collection
	for enemy in enemies:
		enemy.queue_free()
	enemies.clear()
	
	enemy_pathfinding = level.enemy_pathfinding
	
	# Place player
	player.set_tile(level.get_player_spawn_point())
	
	# Place enemies
	var enemy_spawns = level.get_enemy_spawn_points()
	
	for position in enemy_spawns:
		var enemy = EnemyScene.instance()
		enemy.init(randi() % 2, position)
		add_child(enemy)
		enemies.append(enemy)
	
	$CanvasLayer/Level.text = "Level: " + str(level_num)
	
	call_deferred("update_visuals")

func update_visuals():
	
	var player_center = tile_to_pixel_center(player.tile.x, player.tile.y)
	var space_state = get_world_2d().direct_space_state
	for x in range(level.level_size.x):
		for y in range(level.level_size.y):
			if visibility_map.get_cell(x, y) == 0:
				var x_dir = 1 if x < player.tile.x else -1
				var y_dir = 1 if y < player.tile.y else -1
				var test_point = tile_to_pixel_center(x, y) + Vector2(x_dir, y_dir) * TILE_SIZE / 2

				var occlusion = space_state.intersect_ray(player_center, test_point)
				if !occlusion || (occlusion.position - test_point).length() < 1:
					visibility_map.set_cell(x, y, -1)

	for enemy in enemies:
		if !enemy.visible:
			var enemy_center = tile_to_pixel_center(enemy.tile.x, enemy.tile.y)
			var occlusion = space_state.intersect_ray(player_center, enemy_center)
			if !occlusion:
				enemy.visible = true

	for item in level.items:
		if !item.visible:
			var item_center = tile_to_pixel_center(item.tile.x, item.tile.y)
			var occlusion = space_state.intersect_ray(player_center, item_center)
			if !occlusion:
				item.visible = true
	
	$CanvasLayer/HP.text = "HP: " + str(player.hp)
	$CanvasLayer/Score.text = "Score: " + str(player.score)

func tile_to_pixel_center(x, y):
	return Vector2((x + 0.5) * TILE_SIZE, (y + 0.5) * TILE_SIZE)

func _on_Player_action_taken():
	var removal_queue = []
	
	for enemy in enemies:
		enemy.act(enemy_pathfinding, enemies, player)
		if enemy.dead:
			removal_queue.append(enemy)
			player.score += 10 * enemy.full_hp
			
			# Drop items
			var random = randi() % 3
			if random > 0:
				level.add_new_random_item(enemy.tile.x, enemy.tile.y)
	
	for enemy in removal_queue:
		enemies.erase(enemy)
		enemy.queue_free()
	
	call_deferred("update_visuals")

func _on_Player_reached_stairs():
	level_num += 1
	player.score += 20
	
	if level_num < LEVEL_SIZES.size():
		next_level()
	else:
		player.score += 1000
		$CanvasLayer/EndScreen.visible = true
		$CanvasLayer/EndScreen/Score.text = "Score: " + str(player.score)
		$CanvasLayer/EndScreen/StatusText.text = "You Won!"
		$CanvasLayer/EndScreen/Button.grab_focus()
		game_paused = true

func restart_game():
	level_num = 0
	player.score = 0
	next_level()
	player.restart()
	game_paused = false
	
	$CanvasLayer/EndScreen.visible = false
	$CanvasLayer/BottomBar/Blindness.visible = false
	$CanvasLayer/BottomBar/Healing.visible = false
	$CanvasLayer/BottomBar/Poisoned.visible = false

func _on_Button_pressed():
	restart_game()

func _on_Player_died():
	$CanvasLayer/EndScreen.visible = true
	$CanvasLayer/EndScreen/Score.text = "Score: " + str(player.score)
	$CanvasLayer/EndScreen/StatusText.text = "You Died..."
	$CanvasLayer/EndScreen/Button.grab_focus()
	game_paused = true

func _on_PauseMenu_restarted():
	restart_game()

func _on_PauseMenu_unpaused():
	game_paused = false

func _on_Exit_pressed():
	get_tree().change_scene("res://Scenes/TitleScene.tscn")