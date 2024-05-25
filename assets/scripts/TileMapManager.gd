extends TileMap

@export var node2D: Node2D

var grid = []
var grid_width = 64
var grid_height = 64

var astar_grid = AStarGrid2D.new()
var clicked_pos = Vector2i(0,0);

var rng = RandomNumberGenerator.new()
var open_tiles = []

var humans = []
var all_units = []
var user_units = []

var selected_pos = Vector2i(0,0);
var target_pos = Vector2i(0,0);
var selected_unit_num = 1

var moving = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	astar_grid.size = Vector2i(grid_width, grid_height)
	astar_grid.cell_size = Vector2(1, 1)
	astar_grid.default_compute_heuristic = 1
	astar_grid.diagonal_mode = 1
	astar_grid.update()

	#Remove tiles that are off map
	for h in grid_height:
		for i in grid_width:
			set_cell(1, Vector2i(-grid_height+h, i), -1, Vector2i(0, 0), 0)
	for h in grid_height:
		for i in grid_width:
			set_cell(1, Vector2i(grid_height+h, i), -1, Vector2i(0, 0), 0)
	for h in grid_height:
		for i in grid_width:
			set_cell(1, Vector2i(h, -grid_height+i), -1, Vector2i(0, 0), 0)
	for h in grid_height:
		for i in grid_width:
			set_cell(1, Vector2i(h, grid_height+i), -1, Vector2i(0, 0), 0)
	
	#Remove tiles that are on the corner grids off map
	for h in grid_height:
		for i in grid_width:
			set_cell(1, Vector2i(-h-1, -i-1), -1, Vector2i(0, 0), 0)
	for h in grid_height:
		for i in grid_width:
			set_cell(1, Vector2i(h+grid_height, -i-1), -1, Vector2i(0, 0), 0)
	for h in grid_height:
		for i in grid_width:
			set_cell(1, Vector2i(-h-1, i+grid_height), -1, Vector2i(0, 0), 0)
	for h in grid_height:
		for i in grid_width:
			set_cell(1, Vector2i(h+grid_height, i+grid_height), -1, Vector2i(0, 0), 0)
	
func _input(event):
	if event is InputEventKey:	
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()
					
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and get_node("../SpawnManager").spawn_complete == true and moving == false:	
			if event.pressed:
				
				var mouse_pos = get_global_mouse_position()
				mouse_pos.y += 8
				var tile_pos = local_to_map(mouse_pos)	
				#var tile_data = get_cell_tile_data(0, tile_pos)

				clicked_pos = tile_pos	
				
				humans = get_tree().get_nodes_in_group("humans")
				
				all_units.append_array(humans)			
				user_units.append_array(humans)	
				
				# Return if clicked on struture
				for i in node2D.structures.size():
					var tile_center_pos = map_to_local(tile_pos) + Vector2(0,0) / 2
					if node2D.structures[i].position == tile_center_pos:
						return					
				
				for i in user_units.size():
					if user_units[i].tile_pos == tile_pos:
						show_movement_range(tile_pos)
						user_units[i].selected = true
						selected_unit_num = i
						selected_pos = user_units[i].tile_pos
						break
												
				#Move unit
				if get_cell_source_id(1, tile_pos) == 7 and astar_grid.is_point_solid(tile_pos) == false and user_units[selected_unit_num].selected == true:
					#Remove hover tiles										
					for j in grid_height:
						for k in grid_width:
							set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
											
					target_pos = tile_pos 
					var patharray = astar_grid.get_point_path(selected_pos, target_pos)
					
					# Find path and set hover cells
					for h in patharray.size():
						set_cell(1, patharray[h], 7, Vector2i(0, 0), 0)	
											
					# Move unit		
					for h in patharray.size():
						moving = true		
						
						user_units[selected_unit_num].get_child(0).play("move")						
						var tile_center_position = map_to_local(patharray[h]) + Vector2(0,0) / 2
						var unit_pos = local_to_map(user_units[selected_unit_num].position)
						user_units[selected_unit_num].z_index = unit_pos.x + unit_pos.y																					
						var tween = create_tween()
						tween.tween_property(user_units[selected_unit_num], "position", tile_center_position, 0.25)								
						await tween.finished
						user_units[selected_unit_num].get_child(0).play("default")
						for i in user_units.size():
							user_units[i].selected = false
							
						moving = false											
															
func show_path(tile_pos):
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)

	# Find open tiles
	open_tiles.clear()	
	for i in grid_width:
		for j in grid_height:
			if astar_grid.is_point_solid(Vector2i(i,j)) == false:			
				open_tiles.append(Vector2i(i,j))
	
	var rand = rng.randi_range(0, open_tiles.size()-1)		
	var rand2 = rng.randi_range(0, open_tiles.size()-1)					
	var patharray = astar_grid.get_point_path(tile_pos, open_tiles[rand2])			
	# Find path and set hover cells
	for h in patharray.size():
		await get_tree().create_timer(0.05).timeout
		set_cell(1, patharray[h], 7, Vector2i(0, 0), 0)												

func show_attack_range(tile_pos: Vector2i):
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
	
	#Place hover tiles		
	var surrounding_cells = get_node("../TileMap").get_surrounding_cells(tile_pos)
	
	for k in surrounding_cells.size():
		set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
		set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), 14, Vector2i(0, 0), 0)									
		if surrounding_cells[k].x <= -1 or surrounding_cells[k].y >= 16 or surrounding_cells[k].x >= 16 or surrounding_cells[k].y <= -1:
			set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
			set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), -1, Vector2i(0, 0), 0)								
	for k in surrounding_cells.size():
		set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
		set_cell(1, Vector2i(surrounding_cells[k].x+1, surrounding_cells[k].y), 14, Vector2i(0, 0), 0)																																								
		set_cell(1, Vector2i(surrounding_cells[k].x-1, surrounding_cells[k].y), 14, Vector2i(0, 0), 0)															
		set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+1), 14, Vector2i(0, 0), 0)																																								
		set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-1), 14, Vector2i(0, 0), 0)								
	for k in surrounding_cells.size():
		set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
		set_cell(1, Vector2i(surrounding_cells[k].x+2, surrounding_cells[k].y), 14, Vector2i(0, 0), 0)																																								
		set_cell(1, Vector2i(surrounding_cells[k].x-2, surrounding_cells[k].y), 14, Vector2i(0, 0), 0)															
		set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+2), 14, Vector2i(0, 0), 0)																																								
		set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-2), 14, Vector2i(0, 0), 0)															
	for k in surrounding_cells.size():
		set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
		set_cell(1, Vector2i(surrounding_cells[k].x+3, surrounding_cells[k].y), 14, Vector2i(0, 0), 0)																																								
		set_cell(1, Vector2i(surrounding_cells[k].x-3, surrounding_cells[k].y), 14, Vector2i(0, 0), 0)															
		set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+3), 14, Vector2i(0, 0), 0)																																								
		set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-3), 14, Vector2i(0, 0), 0)	
	for k in surrounding_cells.size():
		set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
		set_cell(1, Vector2i(surrounding_cells[k].x+4, surrounding_cells[k].y), 14, Vector2i(0, 0), 0)																																								
		set_cell(1, Vector2i(surrounding_cells[k].x-4, surrounding_cells[k].y), 14, Vector2i(0, 0), 0)															
		set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+4), 14, Vector2i(0, 0), 0)																																								
		set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-4), 14, Vector2i(0, 0), 0)	
											
	set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
	set_cell(1, Vector2i(tile_pos.x+2, tile_pos.y+2), 14, Vector2i(0, 0), 0)																																								
	set_cell(1, Vector2i(tile_pos.x-2, tile_pos.y-2), 14, Vector2i(0, 0), 0)															
	set_cell(1, Vector2i(tile_pos.x+2, tile_pos.y-2), 14, Vector2i(0, 0), 0)																																								
	set_cell(1, Vector2i(tile_pos.x-2, tile_pos.y+2), 14, Vector2i(0, 0), 0)	

	set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
	set_cell(1, Vector2i(tile_pos.x+2, tile_pos.y+3), 14, Vector2i(0, 0), 0)																																								
	set_cell(1, Vector2i(tile_pos.x-3, tile_pos.y-2), 14, Vector2i(0, 0), 0)															
	set_cell(1, Vector2i(tile_pos.x+2, tile_pos.y-3), 14, Vector2i(0, 0), 0)																																								
	set_cell(1, Vector2i(tile_pos.x-3, tile_pos.y+2), 14, Vector2i(0, 0), 0)	

	set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
	set_cell(1, Vector2i(tile_pos.x+3, tile_pos.y+2), 14, Vector2i(0, 0), 0)																																								
	set_cell(1, Vector2i(tile_pos.x-2, tile_pos.y-3), 14, Vector2i(0, 0), 0)															
	set_cell(1, Vector2i(tile_pos.x+3, tile_pos.y-2), 14, Vector2i(0, 0), 0)																																								
	set_cell(1, Vector2i(tile_pos.x-2, tile_pos.y+3), 14, Vector2i(0, 0), 0)

func show_movement_range(tile_pos: Vector2i):
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
	
	#Place hover tiles		
	var surrounding_cells = get_node("../TileMap").get_surrounding_cells(tile_pos)
	
	for k in surrounding_cells.size():
		set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
		set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), 7, Vector2i(0, 0), 0)									
		if surrounding_cells[k].x <= -1 or surrounding_cells[k].y >= 16 or surrounding_cells[k].x >= 16 or surrounding_cells[k].y <= -1:
			set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
			set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), -1, Vector2i(0, 0), 0)								
	for k in surrounding_cells.size():
		set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
		set_cell(1, Vector2i(surrounding_cells[k].x+1, surrounding_cells[k].y), 7, Vector2i(0, 0), 0)																																								
		set_cell(1, Vector2i(surrounding_cells[k].x-1, surrounding_cells[k].y), 7, Vector2i(0, 0), 0)															
		set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+1), 7, Vector2i(0, 0), 0)																																								
		set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-1), 7, Vector2i(0, 0), 0)								
	for k in surrounding_cells.size():
		set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
		set_cell(1, Vector2i(surrounding_cells[k].x+2, surrounding_cells[k].y), 7, Vector2i(0, 0), 0)																																								
		set_cell(1, Vector2i(surrounding_cells[k].x-2, surrounding_cells[k].y), 7, Vector2i(0, 0), 0)															
		set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+2), 7, Vector2i(0, 0), 0)																																								
		set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-2), 7, Vector2i(0, 0), 0)															
	for k in surrounding_cells.size():
		set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
		set_cell(1, Vector2i(surrounding_cells[k].x+3, surrounding_cells[k].y), 7, Vector2i(0, 0), 0)																																								
		set_cell(1, Vector2i(surrounding_cells[k].x-3, surrounding_cells[k].y), 7, Vector2i(0, 0), 0)															
		set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+3), 7, Vector2i(0, 0), 0)																																								
		set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-3), 7, Vector2i(0, 0), 0)	
	for k in surrounding_cells.size():
		set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
		set_cell(1, Vector2i(surrounding_cells[k].x+4, surrounding_cells[k].y), 7, Vector2i(0, 0), 0)																																								
		set_cell(1, Vector2i(surrounding_cells[k].x-4, surrounding_cells[k].y), 7, Vector2i(0, 0), 0)															
		set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+4), 7, Vector2i(0, 0), 0)																																								
		set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-4), 7, Vector2i(0, 0), 0)	
											
	set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
	set_cell(1, Vector2i(tile_pos.x+2, tile_pos.y+2), 7, Vector2i(0, 0), 0)																																								
	set_cell(1, Vector2i(tile_pos.x-2, tile_pos.y-2), 7, Vector2i(0, 0), 0)															
	set_cell(1, Vector2i(tile_pos.x+2, tile_pos.y-2), 7, Vector2i(0, 0), 0)																																								
	set_cell(1, Vector2i(tile_pos.x-2, tile_pos.y+2), 7, Vector2i(0, 0), 0)	

	set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
	set_cell(1, Vector2i(tile_pos.x+2, tile_pos.y+3), 7, Vector2i(0, 0), 0)																																								
	set_cell(1, Vector2i(tile_pos.x-3, tile_pos.y-2), 7, Vector2i(0, 0), 0)															
	set_cell(1, Vector2i(tile_pos.x+2, tile_pos.y-3), 7, Vector2i(0, 0), 0)																																								
	set_cell(1, Vector2i(tile_pos.x-3, tile_pos.y+2), 7, Vector2i(0, 0), 0)	

	set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
	set_cell(1, Vector2i(tile_pos.x+3, tile_pos.y+2), 7, Vector2i(0, 0), 0)																																								
	set_cell(1, Vector2i(tile_pos.x-2, tile_pos.y-3), 7, Vector2i(0, 0), 0)															
	set_cell(1, Vector2i(tile_pos.x+3, tile_pos.y-2), 7, Vector2i(0, 0), 0)																																								
	set_cell(1, Vector2i(tile_pos.x-2, tile_pos.y+3), 7, Vector2i(0, 0), 0)
