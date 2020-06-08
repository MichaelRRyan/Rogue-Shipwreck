extends Node2D

const TILE_SIZE = 32

const MIN_ROOM_DIMENSION = 5
const MAX_ROOM_DIMENSION = 8

const PotionScene = preload("res://Scenes/Potion.tscn")

# Current level -----------------------------------------------

var level_size
var map = []
var rooms = []
var items = []
var enemy_spawns = []
var player_spawn

# Node refs ---------------------------------------------------

onready var tile_map = $TileMap

# Game State --------------------------------------------------

var enemy_pathfinding

# Interface ---------------------------------------------------
func build_level(size, room_count, enemy_count, item_count):
	
	# Reset the map and collections
	rooms.clear()
	map.clear()
	tile_map.clear()
	
	for item in items:
		item.queue_free()
	items.clear()
	
	enemy_pathfinding = AStar.new()
	
	# Build the level 
	
	level_size = size
	for x in range(level_size.x):
		map.append([])
		for y in range(level_size.y):
			map[x].append(TileType.Stone)
			tile_map.set_cell(x, y, TileType.Stone)
	
	var free_regions = [Rect2(Vector2(2, 2), level_size - Vector2(4, 4))]
	var num_rooms = room_count
	for _i in range(num_rooms):
		add_room(free_regions)
		if free_regions.empty():
			break
	
	connect_rooms()
	
	# Place end stairs
	var end_room = rooms.back()
	var stairs_x = end_room.position.x + 1 + randi() % int(end_room.size.x - 2)
	var stairs_y = end_room.position.y + 1 + randi() % int(end_room.size.y - 2)
	set_tile(stairs_x, stairs_y, TileType.Stairs)
	
	# Place player
	set_player_spawn()
	
	# Place enemies
	enemy_spawns.clear()
	set_enemy_spawns(enemy_count)
	
	# Place items
	create_items(item_count)

# -------------------------------------------------------------
func get_player_spawn_point():
	return player_spawn

# -------------------------------------------------------------
func get_enemy_spawn_points():
	return enemy_spawns

# -------------------------------------------------------------
func get_tile(x, y):
	
	if x >= 0 && x < level_size.x && y >= 0 && y < level_size.y:
		return map[x][y]
	
	return TileType.Null

# -------------------------------------------------------------
func get_items(tile):
	
	# Create a collection to hold items at the specified location
	var located_items = []
	
	# Loop and save items with the same location to the collection
	for item in items:
		if item.tile == tile:
			located_items.append(item)
	
	# Duplicate the items found to another collection to be returned
	var items_found = located_items.duplicate()
	
	# Remove all the original items found
	for item in located_items:
		items.erase(item)
		item.queue_free()
	
	# Return the duplicated items
	return items_found

# -------------------------------------------------------------
func set_tile(x, y, type):
	map[x][y] = type
	tile_map.set_cell(x, y, type)
	
	if type == TileType.Ground:
		clear_path(Vector2(x, y))

# Backend -----------------------------------------------------
func set_player_spawn():
	var start_room = rooms.front()
	var player_x = start_room.position.x + 1 + randi() % int(start_room.size.x - 2)
	var player_y = start_room.position.y + 1 + randi() % int(start_room.size.y - 2)
	
	player_spawn = Vector2(player_x, player_y)

# -------------------------------------------------------------
func set_enemy_spawns(enemy_count):
	for _i in range(enemy_count):
		var room = rooms[1 + randi() % (rooms.size() - 1)]
		var x = room.position.x + 1 + randi() % int(room.size.x - 2)
		var y = room.position.y + 1 + randi() % int(room.size.y - 2)

		var blocked = false
		for enemy in enemy_spawns:
			if enemy.x == x && enemy.y == y:
				blocked = true
				break
		
		if player_spawn.x == x && player_spawn.y == y:
			blocked = true

		if !blocked:
			enemy_spawns.append(Vector2(x, y))

# -------------------------------------------------------------
func create_items(item_count):
	for _i in range(item_count):
		var room = rooms[randi() % (rooms.size())]
		var x = room.position.x + 1 + randi() % int(room.size.x - 2)
		var y = room.position.y + 1 + randi() % int(room.size.y - 2)
		
		var blocked = false
		for item in items:
			if item.tile.x == x && item.tile.y:
				blocked = true
				break
		
		if player_spawn.x == x && player_spawn.y == y:
			blocked = true
		
		if !blocked:
			add_new_random_item(x, y)
	
# -------------------------------------------------------------
func add_new_random_item(x, y):
	
	var item = PotionScene.instance()
	
	item.init(x, y)
	
	self.add_child(item)
	items.append(item)
	
# -------------------------------------------------------------
func clear_path(tile):
	var new_point = enemy_pathfinding.get_available_point_id()
	enemy_pathfinding.add_point(new_point, Vector3(tile.x, tile.y, 0))
	var points_to_connect = []
	
	if tile.x > 0 && map[tile.x - 1][tile.y] == TileType.Ground:
		points_to_connect.append(enemy_pathfinding.get_closest_point(Vector3(tile.x - 1, tile.y, 0)))
	if tile.y > 0 && map[tile.x][tile.y - 1] == TileType.Ground:
		points_to_connect.append(enemy_pathfinding.get_closest_point(Vector3(tile.x, tile.y - 1, 0)))
	if tile.x < level_size.x - 1 && map[tile.x + 1][tile.y] == TileType.Ground:
		points_to_connect.append(enemy_pathfinding.get_closest_point(Vector3(tile.x + 1, tile.y, 0)))
	if tile.y < level_size.y - 1 && map[tile.x][tile.y + 1] == TileType.Ground:
		points_to_connect.append(enemy_pathfinding.get_closest_point(Vector3(tile.x, tile.y + 1, 0)))
	
	for point in points_to_connect:
		enemy_pathfinding.connect_points(point, new_point)

# -------------------------------------------------------------
func connect_rooms():
	# Build an AStar graph of the area where corridors can be added
	
	var stone_graph = AStar.new()
	var point_id = 0
	for x in range(level_size.x):
		for y in range(level_size.y):
			if map[x][y] == TileType.Stone:
				stone_graph.add_point(point_id, Vector3(x, y, 0))
				
				# Conect to left if also stone
				if x > 0 && map[x -1][y] == TileType.Stone:
					var left_point = stone_graph.get_closest_point(Vector3(x - 1, y, 0))
					stone_graph.connect_points(point_id, left_point)
				
				if y > 0 && map[x][y - 1] == TileType.Stone:
					var above_point = stone_graph.get_closest_point(Vector3(x, y - 1, 0))
					stone_graph.connect_points(point_id, above_point)
				
				point_id += 1
	
	# Build an AStar graph of room connections
	
	var room_graph = AStar.new()
	point_id = 0
	for room in rooms:
		var room_center = room.position + room.size / 2
		room_graph.add_point(point_id, Vector3(room_center.x, room_center.y, 0))
		point_id += 1
	
	# Add random connections until everything is connected
	
	while !is_everything_connected(room_graph):
		add_random_connection(stone_graph, room_graph)

# -------------------------------------------------------------
func is_everything_connected(graph):
	var points = graph.get_points()
	var start = points.pop_back()
	for point in points:
		var path = graph.get_point_path(start, point)
		if !path:
			return false
	
	return true

# -------------------------------------------------------------
func add_random_connection(stone_graph, room_graph):
	# Pick rooms to connect
	
	var start_room_id = get_least_connected_point(room_graph)
	var end_room_id = get_nearest_unconnected_point(room_graph, start_room_id)
	
	# Pick door locations
	
	var start_position = pick_random_door_location(rooms[start_room_id])
	var end_position = pick_random_door_location(rooms[end_room_id])
	
	# Find a path to connect the doors to each other
	
	var closest_start_point = stone_graph.get_closest_point(start_position)
	var closest_end_point = stone_graph.get_closest_point(end_position)
	
	var path = stone_graph.get_point_path(closest_start_point, closest_end_point)
	assert(path)
	
	# Add path to map
	
	set_tile(start_position.x, start_position.y, TileType.Door)
	set_tile(end_position.x, end_position.y, TileType.Door)
	
	for position in path:
		set_tile(position.x, position.y, TileType.Ground)
	
	room_graph.connect_points(start_room_id, end_room_id)

# -------------------------------------------------------------
func get_least_connected_point(graph):
	var points_ids = graph.get_points()
	
	var least
	var tied_for_least = []
	
	for point in points_ids:
		var count = graph.get_point_connections(point).size()
		if !least || count < least:
			least = count
			tied_for_least = [point]
		elif count == least:
			tied_for_least.append(point)
	
	return tied_for_least[randi() % tied_for_least.size()]

# -------------------------------------------------------------
func get_nearest_unconnected_point(graph, target_point):
	var target_position = graph.get_point_position(target_point)
	var point_ids = graph.get_points()
	
	var nearest
	var tied_for_nearest = []
	
	for point in point_ids:
		if point == target_point:
			continue
		
		var path = graph.get_point_path(point, target_point)
		if path:
			continue
		
		var distance = (graph.get_point_position(point) - target_position).length()
		if !nearest || distance < nearest:
			nearest = distance
			tied_for_nearest = [point]
		elif distance == nearest:
			tied_for_nearest.append(point)
	
	return tied_for_nearest[randi() % tied_for_nearest.size()]

# -------------------------------------------------------------
func pick_random_door_location(room):
	var options = []
	
	# Top and bottom walls
	
	for x in range(room.position.x + 1, room.end.x - 2):
		options.append(Vector3(x, room.position.y, 0))
		options.append(Vector3(x, room.end.y - 1, 0))
	
	# Left and right walls
	
	for y in range(room.position.y + 1, room.end.y - 2):
		options.append(Vector3(room.position.x, y, 0))
		options.append(Vector3(room.end.x - 1, y, 0))
	
	return options[randi() % options.size()]

# -------------------------------------------------------------
func add_room(free_regions):
	var region = free_regions[randi() % free_regions.size()]
	
	var size_x = MIN_ROOM_DIMENSION
	if region.size.x > MIN_ROOM_DIMENSION:
		size_x += randi() % int(region.size.x - MIN_ROOM_DIMENSION)
	
	var size_y = MIN_ROOM_DIMENSION
	if region.size.y > MIN_ROOM_DIMENSION:
		size_y += randi() % int(region.size.y - MIN_ROOM_DIMENSION)
	
	size_x = min(size_x, MAX_ROOM_DIMENSION)
	size_y = min(size_y, MAX_ROOM_DIMENSION)
	
	var start_x = region.position.x
	if region.size.x > size_x:
		start_x += randi() % int(region.size.x - size_x)
	
	var start_y = region.position.y
	if region.size.y > size_y:
		start_y += randi() % int(region.size.y - size_y)
	
	var room = Rect2(start_x, start_y, size_x, size_y)
	rooms.append(room)
	
	for x in range(start_x, start_x + size_x):
		set_tile(x, start_y, TileType.Wall)
		set_tile(x, start_y + size_y - 1, TileType.Wall)
	
	for y in range(start_y + 1, start_y + size_y - 1):
		set_tile(start_x, y, TileType.Wall)
		set_tile(start_x + size_x - 1, y, TileType.Wall)
		
		for x in range(start_x + 1, start_x + size_x - 1):
			set_tile(x, y, TileType.Ground)
	
	cut_regions(free_regions, room)

# -------------------------------------------------------------
func cut_regions(free_regions, region_to_remove):
	var removal_queue = []
	var addition_queue = []
	
	for region in free_regions:
		if region.intersects(region_to_remove):
			removal_queue.append(region)
			
			var leftover_left = region_to_remove.position.x - region.position.x - 1
			var leftover_right = region.end.x - region_to_remove.end.x - 1
			var leftover_above = region_to_remove.position.y - region.position.y - 1
			var leftover_below = region.end.y - region_to_remove.end.y - 1
			
			if leftover_left > MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(region.position, Vector2(leftover_left, region.size.y)))
			if leftover_right > MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(Vector2(region_to_remove.end.x + 1, region.position.y), Vector2(leftover_right, region.size.y)))
			if leftover_above > MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(region.position, Vector2(region.size.x, leftover_above)))
			if leftover_below > MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(Vector2(region.position.x, region_to_remove.end.y + 1), Vector2(region.size.x, leftover_below)))
	
	for region in removal_queue:
		free_regions.erase(region)
	
	for region in addition_queue:
		free_regions.append(region)