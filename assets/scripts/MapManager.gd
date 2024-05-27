extends Node2D

const N = 0x1
const E = 0x2
const S = 0x4
const W = 0x8

var cell_walls = {Vector2i(0, -1): N, Vector2i(1, 0): E,
				  Vector2i(0, 1): S, Vector2i(-1, 0): W}

var moves = {N: Vector2i(0, -1),
			 S: Vector2i(0, 1),
			 E: Vector2i(1, 0),
			 W: Vector2i(-1, 0)}
			
@onready var Map = $TileMap

var intersection_blank = preload("res://assets/scenes/prefab/blank.scn")
var blank = preload("res://assets/scenes/prefab/blank.scn")

var building = preload("res://assets/scenes/prefab/building_c.scn")
var building2 = preload("res://assets/scenes/prefab/building_c2.scn")
var tower = preload("res://assets/scenes/prefab/building_c3.scn")
var stadium = preload("res://assets/scenes/prefab/building_c2.scn")
var district = preload("res://assets/scenes/prefab/building_c.scn")

var map_pos = Vector2(0,0)
var road_pos = Vector2(0,0)
var rng = RandomNumberGenerator.new()
var tile_id
var fastNoiseLite = FastNoiseLite.new()
var grid = []

var grid_width = 32
var grid_height = 32

var structures: Array[Area2D]
var structures_blank: Array[Area2D]

var buildings = []
var buildings2 = []
var towers = []
var stadiums = []
var districts = []

var buildingsblank = []
var buildingsblank2 = []
var towersblank = []
var stadiumsblank = []
var districtsblank = []

var world = false
var mars = false
var moon = false
var saturn = false
var venus = false
var night = false

var tile_num = 1
var my_odd_x: int
var my_odd_y: int

var progresscount: int
var biome
var foundation_tile

var tilelist = []
var tile_random_id : int

var tower_coord : Array[Vector2i]
var tower_int = 0

var empty_tiles : Array[Vector2i]
var open_tiles = []

# Called when the node enters the scene tree for the first time.
func _ready():	
	await get_tree().create_timer(0).timeout
	generate_world()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass														

func move(dir):
	map_pos += moves[dir]
	if map_pos.x >= 0 and map_pos.x <= grid_width-1 and map_pos.y >= 0 and map_pos.y <= grid_height-1:
		generate_tile(map_pos)
	
func generate_tile(cell):
		var _cells = find_valid_tiles(cell)
		#check for water
		if Map.get_cell_source_id(0, map_pos) == 0 or Map.get_cell_source_id(0, map_pos) == 1:
			return
		Map.set_cell(0, map_pos, tile_id, Vector2i(0, 0), 0)	
		
func find_valid_tiles(cell):
	var valid_tiles = []
	# check all possible tiles, 0 - 15
	for i in range(16):
		# check the target space's neighbors (if they exist)
		var is_match = false
		for n in cell_walls.keys():		
			var neighbor_id = Map.get_cell_source_id(0, cell + n, false)
			if neighbor_id >= 0:
				# id == -1 is a blank tile
				if (neighbor_id & cell_walls[-n])/cell_walls[-n] == (i & cell_walls[n])/cell_walls[n]:
					is_match = true
				else:
					is_match = false
					# if we found a mismatch, we don't need to check the remaining sides
					break
		if is_match and not i in valid_tiles:
			valid_tiles.append(i)
	return valid_tiles
	
func generate_world():
	
	tilelist = [0, 1, 2, 3, 4, 5, 6]
		
	fastNoiseLite.seed = rng.randi_range(0, 256)
	fastNoiseLite.TYPE_PERLIN
	fastNoiseLite.fractal_octaves = tilelist.size()
	fastNoiseLite.fractal_gain = 0
	
	for x in grid_width:
		grid.append([])
		#await get_tree().create_timer(0).timeout
		for y in grid_height:
			grid[x].append(0)
			# We get the noise coordinate as an absolute value (which represents the gradient - or layer)	
			var absNoise = abs(fastNoiseLite.get_noise_2d(x,y))
			var tiletoplace = int(floor((absNoise * tilelist.size())))
			Map.set_cell(0, Vector2i(x,y), tilelist[tiletoplace], Vector2i(0, 0), 0)	
			progresscount += 1	
	
	await intersections()

func intersections():
	for i in grid_height/4:
		var my_random_tile_x = rng.randi_range(1, (grid_height)-3)
		var my_random_tile_y = rng.randi_range(1, (grid_height)-3)	
		my_odd_x = my_random_tile_x + ((my_random_tile_x+1)%2 * sign(my_random_tile_x-my_odd_x))	
		my_odd_y = my_random_tile_y + ((my_random_tile_y+1)%2 * sign(my_random_tile_y-my_odd_y))	
		var tile_pos = Vector2i(my_odd_x, my_odd_y)
		var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
		var intersection_inst = intersection_blank.instantiate()
		intersection_inst.position = tile_center_pos
		add_child(intersection_inst)	
		intersection_inst.add_to_group("intersections_blank")	
		progresscount += 1	
		
	generate_roads()

func generate_roads():	
	var rand = grid_height/4			
	# Roads		
	for h in rand:
		var structure_group = get_tree().get_nodes_in_group("intersections_blank")
		var structure_global_pos = structure_group[h].position
		var structure_pos = Map.local_to_map(structure_global_pos)
		map_pos = structure_pos
				
		for i in grid_width:
			tile_id = 42
			move(E)
			#await get_tree().create_timer(0).timeout
			progresscount += 1
		map_pos = structure_pos	
		for i in grid_width:
			tile_id = 41
			move(S)
			#await get_tree().create_timer(0).timeout
			progresscount += 1
		map_pos = structure_pos
		for i in grid_width:
			tile_id = 42
			move(W)
			#await get_tree().create_timer(0).timeout
			progresscount += 1
		map_pos = structure_pos
		for i in grid_width:
			tile_id = 41
			move(N)	
			#await get_tree().create_timer(0).timeout
			progresscount += 1
					
		# Intersection		
		for i in grid_width:
			for j in grid_height:
				if Map.get_cell_source_id(0, Vector2i(i,j)) == 41:
					var surrounding_cells = Map.get_surrounding_cells(Vector2i(i,j))
					if Map.get_cell_source_id(0, surrounding_cells[0]) == 42 and Map.get_cell_source_id(0, surrounding_cells[1]) == 41 and Map.get_cell_source_id(0, surrounding_cells[2]) == 42 and Map.get_cell_source_id(0, surrounding_cells[3]) == 41:
						Map.set_cell(0, Vector2i(i,j), 43, Vector2i(0, 0), 0)		
						progresscount += 1												
			
		for i in grid_width:
			for j in grid_height:
				if Map.get_cell_source_id(0, Vector2i(i,j)) == 42:
					var surrounding_cells = Map.get_surrounding_cells(Vector2i(i,j))
					if Map.get_cell_source_id(0, surrounding_cells[0]) == 42 and Map.get_cell_source_id(0, surrounding_cells[1]) == 41 and Map.get_cell_source_id(0, surrounding_cells[2]) == 42 and Map.get_cell_source_id(0, surrounding_cells[3]) == 41:
						Map.set_cell(0, Vector2i(i,j), 43, Vector2i(0, 0), 0)
						progresscount += 1	
	
	spawn_buildings()
	
func spawn_structures(): #useless				
	# Randomize structures at start	
	for i in 128: #buildings
		var my_random_tile_x = rng.randi_range(1, grid_width-2)
		var my_random_tile_y = rng.randi_range(1, grid_width-2)
		var tile_pos = Vector2i(my_random_tile_x, my_random_tile_y)
		var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
		var buildingblank_inst = blank.instantiate()
		buildingblank_inst.position = tile_center_pos
		add_child(buildingblank_inst)
		buildingblank_inst.add_to_group("buildingsblank")
		buildingblank_inst.add_to_group("structuresblank")		
		buildingblank_inst.z_index = tile_pos.x + tile_pos.y				
		buildingblank_inst.position = Vector2(tile_center_pos.x, tile_center_pos.y-500)						
		var tween: Tween = create_tween()
		tween.tween_property(buildingblank_inst, "position", tile_center_pos, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)				
		#await get_tree().create_timer(0).timeout		
		Map.set_cell(0, Vector2i(my_random_tile_x, my_random_tile_y), 9, Vector2i(0, 0), 0)		
		progresscount += 1

	for i in 128: #buildings2
		var my_random_tile_x = rng.randi_range(1, grid_width-2)
		var my_random_tile_y = rng.randi_range(1, grid_width-2)
		var tile_pos = Vector2i(my_random_tile_x, my_random_tile_y)
		var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
		var buildingblank_inst2 = blank.instantiate()
		buildingblank_inst2.position = tile_center_pos
		add_child(buildingblank_inst2)
		buildingblank_inst2.add_to_group("buildingsblank2")
		buildingblank_inst2.add_to_group("structuresblank")		
		buildingblank_inst2.z_index = tile_pos.x + tile_pos.y				
		buildingblank_inst2.position = Vector2(tile_center_pos.x, tile_center_pos.y-500)						
		var tween: Tween = create_tween()
		tween.tween_property(buildingblank_inst2, "position", tile_center_pos, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)				
		#await get_tree().create_timer(0).timeout		
		Map.set_cell(0, Vector2i(my_random_tile_x, my_random_tile_y), 12, Vector2i(0, 0), 0)		
		progresscount += 1
		
	for i in 64: #stadiums
		var my_random_tile_x = rng.randi_range(1, grid_width-2)
		var my_random_tile_y = rng.randi_range(1, grid_width-2)
		var tile_pos = Vector2i(my_random_tile_x, my_random_tile_y)
		var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
		var stadiumblank_inst = blank.instantiate()
		stadiumblank_inst.position = tile_center_pos
		add_child(stadiumblank_inst)
		stadiumblank_inst.add_to_group("stadiumsblank")		
		stadiumblank_inst.add_to_group("structuresblank")
		stadiumblank_inst.z_index = tile_pos.x + tile_pos.y				
		stadiumblank_inst.position = Vector2(tile_center_pos.x, tile_center_pos.y-500)						
		var tween: Tween = create_tween()
		tween.tween_property(stadiumblank_inst, "position", tile_center_pos, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)				
		#await get_tree().create_timer(0).timeout			
		Map.set_cell(0, Vector2i(my_random_tile_x, my_random_tile_y), 10, Vector2i(0, 0), 0)
		progresscount += 1
			
	for i in 64: #districts
		var my_random_tile_x = rng.randi_range(1, grid_width-2)
		var my_random_tile_y = rng.randi_range(1, grid_width-2)
		var tile_pos = Vector2i(my_random_tile_x, my_random_tile_y)
		var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
		var districtblank_inst = blank.instantiate()
		districtblank_inst.position = tile_center_pos
		add_child(districtblank_inst)
		districtblank_inst.add_to_group("districtsblank")	
		districtblank_inst.add_to_group("structuresblank")	
		districtblank_inst.z_index = tile_pos.x + tile_pos.y				
		districtblank_inst.position = Vector2(tile_center_pos.x, tile_center_pos.y-500)						
		var tween: Tween = create_tween()
		tween.tween_property(districtblank_inst, "position", tile_center_pos, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)				
		#await get_tree().create_timer(0).timeout		
		Map.set_cell(0, Vector2i(my_random_tile_x, my_random_tile_y), 11, Vector2i(0, 0), 0)
		progresscount += 1

	for i in grid_width: #towers
		for j in grid_height:
			var my_random_tile_x = rng.randi_range(1, grid_width-2)
			var my_random_tile_y = rng.randi_range(1, grid_width-2)
			if Map.get_cell_source_id(0, Vector2i(i,j)) == 5:	
				Map.set_cell(0, Vector2i(i, j), 13, Vector2i(0, 0), 0)
				tower_coord.append((Vector2i(i,j)))
				progresscount += 1			
					
	buildings = get_tree().get_nodes_in_group("buildings")
	buildings2 = get_tree().get_nodes_in_group("buildings2")
	towers = get_tree().get_nodes_in_group("towers")
	stadiums = get_tree().get_nodes_in_group("stadiums")
	districts = get_tree().get_nodes_in_group("districts")
	
	buildingsblank = get_tree().get_nodes_in_group("buildingsblank")
	buildingsblank2 = get_tree().get_nodes_in_group("buildingsblank2")
	towersblank = get_tree().get_nodes_in_group("towersblank")
	stadiumsblank = get_tree().get_nodes_in_group("stadiumsblank")
	districtsblank = get_tree().get_nodes_in_group("districtsblank")
	
	structures.append_array(buildings)
	structures.append_array(buildings2)
	structures.append_array(towers)
	structures.append_array(stadiums)
	structures.append_array(districts)	
	
	structures_blank.append_array(buildingsblank)
	structures_blank.append_array(buildingsblank2)
	structures_blank.append_array(towersblank)
	structures_blank.append_array(stadiumsblank)
	structures_blank.append_array(districtsblank)		
				
	for i in 128: #towersblank
		var my_random_tile_x = rng.randi_range(1, grid_width-2)
		var my_random_tile_y = rng.randi_range(1, grid_width-2)	
		my_odd_x = my_random_tile_x + ((my_random_tile_x+1)%2 * sign(my_random_tile_x-my_odd_x))	
		my_odd_y = my_random_tile_y + ((my_random_tile_y+1)%2 * sign(my_random_tile_y-my_odd_y))	
		var tile_pos = Vector2i(my_odd_x, my_odd_y)
		var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
		var towerblank_inst = blank.instantiate()
		towerblank_inst.position = tile_center_pos
		add_child(towerblank_inst)	
		towerblank_inst.add_to_group("towersblank")	
		towerblank_inst.add_to_group("structuresblank")	
		towerblank_inst.z_index = tile_pos.x + tile_pos.y
		progresscount += 1

	#intersections()

func spawn_buildings():
	for i in grid_width:
		for j in grid_height:
			if Map.get_cell_source_id(0, Vector2i(i,j)) == 1:
				if rng.randi_range(0, 4) == 0:	
					var tile_pos = Vector2i(i, j)
					var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
					var building_inst = building.instantiate()
					building_inst.position = tile_center_pos
					add_child(building_inst)
					building_inst.add_to_group("buildings")		
					building_inst.z_index = tile_pos.x + tile_pos.y
					building_inst.get_child(0).modulate = Color8(rng.randi_range(150, 255), rng.randi_range(150, 255), rng.randi_range(150, 255))	
					building_inst.position = Vector2(tile_center_pos.x, tile_center_pos.y-500)						
					var tween: Tween = create_tween()
					tween.tween_property(building_inst, "position", tile_center_pos, 0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)				
					#await get_tree().create_timer(0).timeout
					Map.set_cell(0, Vector2i(i, j), 9, Vector2i(0, 0), 0)
					progresscount += 1					

	for i in grid_width:
		for j in grid_height:
			if Map.get_cell_source_id(0, Vector2i(i,j)) == 4:
				if rng.randi_range(0, 2) == 0:	
					var tile_pos = Vector2i(i, j)
					var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
					var building_inst = building2.instantiate()
					building_inst.position = tile_center_pos
					add_child(building_inst)
					building_inst.add_to_group("buildings2")		
					building_inst.z_index = tile_pos.x + tile_pos.y
					building_inst.get_child(0).modulate = Color8(rng.randi_range(150, 255), rng.randi_range(150, 255), rng.randi_range(150, 255))	
					building_inst.position = Vector2(tile_center_pos.x, tile_center_pos.y-500)						
					var tween: Tween = create_tween()
					tween.tween_property(building_inst, "position", tile_center_pos, 0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)				
					#await get_tree().create_timer(0).timeout
					Map.set_cell(0, Vector2i(i, j), 9, Vector2i(0, 0), 0)
					progresscount += 1		

	for i in grid_width:
		for j in grid_height:
			if Map.get_cell_source_id(0, Vector2i(i,j)) == 3:	
				if rng.randi_range(0, 9) == 0:
					var tile_pos = Vector2i(i, j)
					var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
					var building_inst = building.instantiate()
					building_inst.position = tile_center_pos
					add_child(building_inst)
					building_inst.add_to_group("buildings")		
					building_inst.z_index = tile_pos.x + tile_pos.y
					building_inst.get_child(0).modulate = Color8(rng.randi_range(150, 255), rng.randi_range(150, 255), rng.randi_range(150, 255))	
					building_inst.position = Vector2(tile_center_pos.x, tile_center_pos.y-500)						
					var tween: Tween = create_tween()
					tween.tween_property(building_inst, "position", tile_center_pos, 0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)				
					#await get_tree().create_timer(0).timeout
					Map.set_cell(0, Vector2i(i, j), 9, Vector2i(0, 0), 0)
					progresscount += 1	
					
	spawn_stadiums()	
				
func spawn_stadiums():
	for i in grid_width:
		for j in grid_height:
			if Map.get_cell_source_id(0, Vector2i(i,j)) == 2:
				if rng.randi_range(0, 4) == 0:	
					var tile_pos = Vector2i(i, j)
					var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
					var stadium_inst = stadium.instantiate()
					stadium_inst.position = tile_center_pos
					add_child(stadium_inst)	
					stadium_inst.add_to_group("stadiums")	
					stadium_inst.z_index = tile_pos.x + tile_pos.y
					stadium_inst.get_child(0).modulate = Color8(rng.randi_range(150, 255), rng.randi_range(150, 255), rng.randi_range(150, 255))		
					stadium_inst.position = Vector2(tile_center_pos.x, tile_center_pos.y-500)						
					var tween: Tween = create_tween()
					tween.tween_property(stadium_inst, "position", tile_center_pos, 0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)				
					#await get_tree().create_timer(0).timeout
					Map.set_cell(0, Vector2i(i, j), 10, Vector2i(0, 0), 0)
					progresscount += 1
		
	spawn_districts()
	
func spawn_districts():
	for i in grid_width:
		for j in grid_height:
			if Map.get_cell_source_id(0, Vector2i(i,j)) == 6:	
				if rng.randi_range(0, 2) == 0:	
					var tile_pos = Vector2i(i, j)
					var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
					var district_inst = district.instantiate()
					district_inst.position = tile_center_pos
					add_child(district_inst)
					district_inst.add_to_group("districts")		
					district_inst.z_index = tile_pos.x + tile_pos.y				
					district_inst.get_child(0).modulate = Color8(rng.randi_range(150, 255), rng.randi_range(150, 255), rng.randi_range(150, 255))		
					district_inst.position = Vector2(tile_center_pos.x, tile_center_pos.y-500)						
					var tween: Tween = create_tween()
					tween.tween_property(district_inst, "position", tile_center_pos, 0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)				
					#await get_tree().create_timer(0).timeout
					Map.set_cell(0, Vector2i(i, j), 11, Vector2i(0, 0), 0)
					progresscount += 1
	
	spawn_towers_final()
	
func spawn_towers_final():	
	for i in grid_width: #towers
		for j in grid_height:
			var my_random_tile_x = rng.randi_range(1, grid_width-2)
			var my_random_tile_y = rng.randi_range(1, grid_width-2)
			if Map.get_cell_source_id(0, Vector2i(i,j)) == 5:	
				Map.set_cell(0, Vector2i(i, j), 13, Vector2i(0, 0), 0)
				tower_coord.append((Vector2i(i,j)))
				progresscount += 1	
								
	for l in tower_coord.size():	
		if rng.randi_range(0, 4) == 0:
			var tile_pos = tower_coord[rng.randi_range(0, tower_coord.size()-1)]
			var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
			var tower_inst = tower.instantiate()
			tower_inst.position = Vector2(tile_center_pos.x, tile_center_pos.y-500)
			var tween: Tween = create_tween()
			tween.tween_property(tower_inst, "position", tile_center_pos, 0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)								
			add_child(tower_inst)	
			tower_inst.add_to_group("towers")	
			tower_inst.z_index = tile_pos.x + tile_pos.y
			tower_inst.get_child(0).modulate = Color8(rng.randi_range(150, 255), rng.randi_range(150, 255), rng.randi_range(150, 255))		
			Map.set_cell(0, tile_pos, 9, Vector2i(0, 0), 0)
			progresscount += 1						
			#await get_tree().create_timer(0).timeout				
								
	add_to_structures_array()
	
	replace_with_water()
							
func add_to_structures_array():
	buildings = get_tree().get_nodes_in_group("buildings")
	buildings2 = get_tree().get_nodes_in_group("buildings2")
	towers = get_tree().get_nodes_in_group("towers")
	stadiums = get_tree().get_nodes_in_group("stadiums")
	districts = get_tree().get_nodes_in_group("districts")
		
	structures.append_array(buildings)
	structures.append_array(buildings2)
	structures.append_array(towers)
	structures.append_array(stadiums)
	structures.append_array(districts)

	#check_duplicates(structures)

func check_duplicates(a):
	var is_dupe = false
	#var found_dupe = false 

	for i in range(a.size()):
		if is_dupe == true:
			break
		for j in range(a.size()):
			if a[j].position == a[i].position:
				#is_dupe = true
				#found_dupe = true
				#print("duplicate")
				
				var i_pos = Map.local_to_map(a[i].position)	
				var i_global = Map.map_to_local(Vector2i(i_pos.x, i_pos.y)) + Vector2(0,0) / 2	
				a[i].position = i_global
				var tile_pos_i = Vector2i(i_pos.x, i_pos.y)
				#a[i].get_child(0).modulate = Color8(255, 255, 255)	
				a[i].get_child(0).modulate.a = 0
				a[i].position.y -= 500
				a[i].z_index = tile_pos_i.x + tile_pos_i.y
				Map.astar_grid.set_point_solid(i_pos, false)
				
				#Empty foundation indicator
				#Map.set_cell(0, i_pos, 48, Vector2i(0, 0), 0)
				Map.astar_grid.set_point_solid(i_pos, false)	
								
				var j_pos = Map.local_to_map(a[j].position)	
				var j_global = Map.map_to_local(Vector2i(j_pos.x, j_pos.y)) + Vector2(0,0) / 2	
				a[j].position = j_global
				var tile_pos_j = Vector2i(j_pos.x, j_pos.y)
				#a[j].get_child(0).modulate = Color8(0, 0, 0)
				a[j].get_child(0).modulate.a = 1	
				a[j].z_index = tile_pos_j.x + tile_pos_j.y
				Map.astar_grid.set_point_solid(j_pos, true)				

func replace_with_water():
	for i in grid_width:
		for j in grid_height:
			if Map.get_cell_source_id(0, Vector2i(i,j)) == 41 or Map.get_cell_source_id(0, Vector2i(i,j)) == 42:	
				var cells = Map.get_surrounding_cells(Vector2i(i,j))
				for k in cells.size():
					if Map.get_cell_source_id(0, cells[1]) == 0 or Map.get_cell_source_id(0, cells[3]) == 0:
						Map.set_cell(0, Vector2i(i,j), 0, Vector2i(0, 0), 0)
					
func _on_button_pressed():
	get_tree().reload_current_scene()
