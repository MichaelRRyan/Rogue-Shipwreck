extends Node2D

signal action_taken
signal reached_stairs
signal died

const START_HP = 5

var tile
var level_ref
var enemies_ref
var status_bar_ref
var hp = START_HP
var score = 0

# Temp
const POTION_FUNCTIONS = ["impair_vision", "heal_over_time", "poison"]
var potion_types
var impaired_turns = 0
var healing_turns = 0
var poison_turns = 0

# -------------------------------------------------------------
func init(level, enemies, status_bar):
	level_ref = level
	enemies_ref = enemies
	status_bar_ref = status_bar
	
	restart()

# -------------------------------------------------------------
func restart():
	hp = START_HP
	impaired_turns = 0
	healing_turns = 0
	poison_turns = 0
	
	$Impairment.visible = false
	status_bar_ref.get_node("Blindness").visible = false
	status_bar_ref.get_node("Healing").visible = false
	status_bar_ref.get_node("Poisoned").visible = false
	
	# TEMP Randomise the potion effects
	potion_types = POTION_FUNCTIONS.duplicate()
	potion_types.shuffle()

# -------------------------------------------------------------
func set_tile(tile_pos):
	tile = tile_pos
	position = tile * 16

# -------------------------------------------------------------
func handle_input(event):
	if !event.is_pressed():
		return

	if event.is_action("move_left"):
		try_move(-1, 0)
	elif event.is_action("move_right"):
		try_move(1, 0)
	elif event.is_action("move_up"):
		try_move(0, -1)
	elif event.is_action("move_down"):
		try_move(0, 1)

# -------------------------------------------------------------
func try_move(dx, dy):
	var x = tile.x + dx
	var y = tile.y + dy

	var tile_type = TileType.Stone
	tile_type = level_ref.get_tile(x, y)

	match tile_type:
		TileType.Ground:
			var blocked = false
			for enemy in enemies_ref:
				if enemy.tile.x == x && enemy.tile.y == y:
					enemy.take_damage(1)
					blocked = true
					break

			if !blocked:
				set_tile(Vector2(x, y))
				pickup_items()

		TileType.Door:
			level_ref.set_tile(x, y, TileType.Ground)

		TileType.Stairs:
			emit_signal("reached_stairs")
	
	emit_signal("action_taken")
	if impaired_turns > 0:
		impaired_turns -= 1
		if impaired_turns == 0:
			status_bar_ref.get_node("Blindness").visible = false
			$Impairment.visible = false

	if healing_turns > 0:
		healing_turns -= 1
		hp += 2
		if healing_turns == 0:
			status_bar_ref.get_node("Healing").visible = false

	if poison_turns > 0:
		poison_turns -= 1
		damage(1)
		if poison_turns == 0:
			status_bar_ref.get_node("Poisoned").visible = false

# -------------------------------------------------------------
func pickup_items():
	
	var items = level_ref.get_items(tile)
	
	for item in items:
		if item.is_food:
			hp += 2
			score += 1
		else:
			call(potion_types[item.get_type()])

# -------------------------------------------------------------
func damage(dmg):
	hp = max(0, hp - dmg)
	if hp == 0:
		emit_signal("died")

# -------------------------------------------------------------
func impair_vision():
	impaired_turns = 10
	status_bar_ref.get_node("Blindness").visible = true
	$Impairment.visible = true

# -------------------------------------------------------------
func heal_over_time():
	healing_turns = 3
	status_bar_ref.get_node("Healing").visible = true

# -------------------------------------------------------------
func poison():
	poison_turns = 3
	status_bar_ref.get_node("Poisoned").visible = true