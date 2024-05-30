extends Node2D

@export var node2D: Node2D

var rng = RandomNumberGenerator.new()

var open_tiles = []
var random = []

var grid_width = 64
var grid_height = 64

var soldier = preload("res://assets/scenes/prefab/Soldier.scn")
var godzilla = preload("res://assets/scenes/prefab/Zombie.scn")

var spawn_complete = false

# Called when the node enters the scene tree for the first time.
func _ready():
	await spawn()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func spawn():	
	await get_tree().create_timer(1).timeout
	
	# Find open tiles again
	open_tiles.clear()	
	for i in grid_width:
		for j in grid_height:
			if get_node("../TileMap").get_cell_source_id(0, Vector2i(i,j)) == 3 and get_node("../TileMap").astar_grid.is_point_solid(Vector2i(i,j)) == false:		
				open_tiles.append(Vector2i(i,j))
	
	random.clear()
	random = get_random_numbers(0, open_tiles.size())

	# Drop soldier at start	
	for i in 64:	
		var soldier_inst = soldier.instantiate()
		node2D.add_child(soldier_inst)
		soldier_inst.add_to_group("humans")	
		soldier_inst.add_to_group("alive")		
		var new_position = get_node("../TileMap").map_to_local(open_tiles[random[i]]) + Vector2(0,0) / 2
		soldier_inst.position = Vector2(new_position.x, new_position.y-500)
		var tween: Tween = create_tween()
		tween.tween_property(soldier_inst, "position", new_position, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
		get_node("../TileMap").astar_grid.set_point_solid(new_position, true)
		await get_tree().create_timer(0).timeout
		
	# Find open tiles again
	open_tiles.clear()	
	for i in grid_width:
		for j in grid_height:
			if get_node("../TileMap").astar_grid.is_point_solid(Vector2i(i,j)) == false:		
				open_tiles.append(Vector2i(i,j))
	
	random.clear()
	random = get_random_numbers(0, open_tiles.size())

	# Drop soldier_cpu at start	
	for i in 64:	
		var soldier_inst = soldier.instantiate()
		node2D.add_child(soldier_inst)
		soldier_inst.add_to_group("cpu")
		soldier_inst.add_to_group("alive")			
		var new_position = get_node("../TileMap").map_to_local(open_tiles[random[i]]) + Vector2(0,0) / 2
		soldier_inst.position = Vector2(new_position.x, new_position.y-500)
		var tween: Tween = create_tween()
		tween.tween_property(soldier_inst, "position", new_position, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		soldier_inst.get_child(0).modulate = Color8(255, 155, 0)	
		get_node("../TileMap").astar_grid.set_point_solid(new_position, true)
		await get_tree().create_timer(0).timeout		

	await get_tree().create_timer(1).timeout
	spawn_complete = true

	# Find open tiles again
	open_tiles.clear()	
	for i in grid_width:
		for j in grid_height:
			if get_node("../TileMap").get_cell_source_id(0, Vector2i(i,j)) == 0 and get_node("../TileMap").astar_grid.is_point_solid(Vector2i(i,j)) == false:		
				open_tiles.append(Vector2i(i,j))
	
	random.clear()
	random = get_random_numbers(0, open_tiles.size())
	
	# Drop Godzilla_cpu at start	
	for i in 4:	
		var godzilla_inst = godzilla.instantiate()
		node2D.add_child(godzilla_inst)
		godzilla_inst.add_to_group("godzilla")
		godzilla_inst.add_to_group("alive")			
		var new_position = get_node("../TileMap").map_to_local(open_tiles[random[i]]) + Vector2(0,0) / 2
		godzilla_inst.position = Vector2(new_position.x, new_position.y-500)
		var tween: Tween = create_tween()
		tween.tween_property(godzilla_inst, "position", new_position, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		#godzilla_inst.get_child(0).modulate = Color8(255, 155, 0)	
		get_node("../TileMap").astar_grid.set_point_solid(new_position, true)
		await get_tree().create_timer(0).timeout		

	await get_tree().create_timer(1).timeout
	spawn_complete = true	
	
func get_random_numbers(from, to):
	var arr = []
	for i in range(from,to):
		arr.append(i)
	arr.shuffle()
	return arr	
