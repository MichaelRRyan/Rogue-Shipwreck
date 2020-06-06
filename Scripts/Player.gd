extends KinematicBody2D

signal moved
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
	position = tile * 16 + Vector2(8, 8)

# -------------------------------------------------------------
func _input(event):
	if event.is_action_pressed("mouse_click"):
		var overlapping_bodies = $Sprite/AttackArea.get_overlapping_bodies()
		if overlapping_bodies:
			for body in overlapping_bodies:
				if body != self:
					if body.is_in_group("Enemy"):
						body.take_damage(1)

# -------------------------------------------------------------
func _physics_process(delta):
	var speed = 150
	var velocity = Vector2.ZERO

	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	
	if velocity.length_squared() != 0:
		velocity = velocity.normalized() * speed
	
		velocity = move_and_slide(velocity)
		
		emit_signal("moved")
		
	$Sprite.look_at(get_global_mouse_position())
	
	if impaired_turns > 0:
		impaired_turns -= delta
		if impaired_turns <= 0:
			status_bar_ref.get_node("Blindness").visible = false
			$Impairment.visible = false

	if healing_turns > 0:
		healing_turns -= delta
		hp += 2 * delta
		if healing_turns <= 0:
			status_bar_ref.get_node("Healing").visible = false

	if poison_turns > 0:
		poison_turns -= delta
		damage(1 * delta)
		if poison_turns <= 0:
			status_bar_ref.get_node("Poisoned").visible = false
	
	check_level_collisions()

# -------------------------------------------------------------
func check_level_collisions():
	tile = Vector2(int(position.x / 16), int(position.y / 16))
	var x = tile.x
	var y = tile.y

	var tile_type = level_ref.get_tile(x, y)

	match tile_type:
		TileType.Ground:
			pickup_items()

		TileType.Door:
			level_ref.set_tile(x, y, TileType.Ground)

		TileType.Stairs:
			emit_signal("reached_stairs")

	if Input.is_action_just_pressed("mouse_click"):
		var mouse_tile = Vector2(int(get_global_mouse_position().x / 16), int(get_global_mouse_position().y / 16))
		if level_ref.get_tile(mouse_tile.x, mouse_tile.y) == TileType.Door:
			level_ref.set_tile(mouse_tile.x, mouse_tile.y, TileType.Ground)

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