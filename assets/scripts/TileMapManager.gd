extends TileMap

@export var node2D: Node2D
@onready var soundstream = $"../SoundStream"
@onready var linemanager = $"../LineManager"

var grid = []
var grid_width = 32
var grid_height = 32

var astar_grid = AStarGrid2D.new()
var clicked_pos = Vector2i(0,0);

var rng = RandomNumberGenerator.new()
var open_tiles = []

var humans = []
var cpu = []
var all_units = []
var user_units = []
var cpu_units = []

var selected_pos = Vector2i(0,0);
var target_pos = Vector2i(0,0);
var selected_unit_num = 1

var moving = false

var right_clicked_unit
var left_clicked_unit
var attack_range = false

var _temp
var alive_humans = []
var alive_cpu = []

var dead_humans = 0
var dead_cpu = 0

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
	
	# Layer 2
	#Remove tiles that are off map
	for h in grid_height:
		for i in grid_width:
			set_cell(2, Vector2i(-grid_height+h, i), -1, Vector2i(0, 0), 0)
	for h in grid_height:
		for i in grid_width:
			set_cell(2, Vector2i(grid_height+h, i), -1, Vector2i(0, 0), 0)
	for h in grid_height:
		for i in grid_width:
			set_cell(2, Vector2i(h, -grid_height+i), -1, Vector2i(0, 0), 0)
	for h in grid_height:
		for i in grid_width:
			set_cell(2, Vector2i(h, grid_height+i), -1, Vector2i(0, 0), 0)
	
	#Remove tiles that are on the corner grids off map
	for h in grid_height:
		for i in grid_width:
			set_cell(2, Vector2i(-h-1, -i-1), -1, Vector2i(0, 0), 0)
	for h in grid_height:
		for i in grid_width:
			set_cell(2, Vector2i(h+grid_height, -i-1), -1, Vector2i(0, 0), 0)
	for h in grid_height:
		for i in grid_width:
			set_cell(2, Vector2i(-h-1, i+grid_height), -1, Vector2i(0, 0), 0)
	for h in grid_height:
		for i in grid_width:
			set_cell(2, Vector2i(h+grid_height, i+grid_height), -1, Vector2i(0, 0), 0)
				
func _input(event):
	if event is InputEventKey:	
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()				
							
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and get_node("../SpawnManager").spawn_complete == true and moving == false:	
			if event.pressed:
				attack_range = false
				var mouse_pos = get_global_mouse_position()
				mouse_pos.y += 8
				var tile_pos = local_to_map(mouse_pos)
				var mouse_position = map_to_local(tile_pos) + Vector2(0,0) / 2	
				#var tile_data = get_cell_tile_data(0, tile_pos)

				clicked_pos = tile_pos	
				
				all_units.clear()
				user_units.clear()
				cpu_units.clear()	
								
				humans = get_tree().get_nodes_in_group("humans")
				cpu = get_tree().get_nodes_in_group("cpu")
				
				all_units.append_array(humans)	
				all_units.append_array(cpu)		
				user_units.append_array(humans)
				cpu_units.append_array(cpu)	
					
				# Return if clicked on struture
				for i in node2D.structures.size():
					var tile_center_pos = map_to_local(tile_pos) + Vector2(0,0) / 2
					if node2D.structures[i].position == tile_center_pos:
						return					
				
				for i in user_units.size():
					if user_units[i].tile_pos == tile_pos and attack_range == false:
						show_movement_range(tile_pos)
						#show_full_range()
						user_units[i].selected = true
						selected_unit_num = i
						selected_pos = user_units[i].tile_pos
						
						soundstream.stream = soundstream.map_sfx[8]
						soundstream.play()							
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
						if user_units[selected_unit_num].check_water() == true:
							#user_units[selected_unit_num].get_child(0).play("move")
							var tile_center_position = map_to_local(patharray[h]) + Vector2(0,0) / 2
							var unit_pos = local_to_map(user_units[selected_unit_num].position)
							user_units[selected_unit_num].z_index = unit_pos.x + unit_pos.y																					
							var tween = create_tween()
							tween.tween_property(user_units[selected_unit_num], "position", tile_center_position, 0.1)								
							await tween.finished
							user_units[selected_unit_num].get_child(0).play("default")
							for i in user_units.size():
								user_units[i].selected = false
								
							moving = false	
							if user_units[selected_unit_num].check_water() == true:
								pass
							
						elif user_units[selected_unit_num].check_land() == true:							
							user_units[selected_unit_num].get_child(0).play("move")						
							var tile_center_position = map_to_local(patharray[h]) + Vector2(0,0) / 2
							var unit_pos = local_to_map(user_units[selected_unit_num].position)
							user_units[selected_unit_num].z_index = unit_pos.x + unit_pos.y																					
							var tween = create_tween()
							tween.tween_property(user_units[selected_unit_num], "position", tile_center_position, 0.1)								
							await tween.finished
							user_units[selected_unit_num].get_child(0).play("default")
							for i in user_units.size():
								user_units[i].selected = false
								
							moving = false		
							soundstream.stream = soundstream.map_sfx[6]
							soundstream.play()
					
					await user_range_ai(user_units[selected_unit_num].tile_pos, user_units[selected_unit_num])	
					on_cpu()														

		if event.button_index == MOUSE_BUTTON_RIGHT and get_node("../SpawnManager").spawn_complete == true and moving == false:	
			if event.pressed:
				attack_range = false						
				#Remove hover tiles										
				for j in grid_height:
					for k in grid_width:
						set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)	
																									
				var mouse_pos = get_global_mouse_position()
				mouse_pos.y += 8
				var tile_pos = local_to_map(mouse_pos)		
				var tile_data = get_cell_tile_data(0, tile_pos)
							
				for i in user_units.size():
					if user_units[i].tile_pos == tile_pos:
						right_clicked_unit = user_units[i]
						selected_unit_num = user_units[i].unit_num
						selected_pos = user_units[i].tile_pos	
						attack_range = true												
						break	
						
				if tile_data is TileData:				
					for i in user_units.size():
						var unit_pos = local_to_map(user_units[i].position)

						if unit_pos == tile_pos :																				
							var hoverflag_1 = true															
							for j in grid_height:	
								set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
								if hoverflag_1 == true:
									for k in node2D.structures.size():
										if tile_pos.x-j >= 0:	
											set_cell(1, Vector2i(tile_pos.x-j, tile_pos.y), 14, Vector2i(0, 0), 0)
											if astar_grid.is_point_solid(Vector2i(tile_pos.x-j, tile_pos.y)) == true and user_units[i].tile_pos != Vector2i(tile_pos.x-j, tile_pos.y):
												hoverflag_1 = false
												break	
									
							var hoverflag_2 = true										
							for j in grid_height:	
								set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
								if hoverflag_2 == true:											
									for k in node2D.structures.size():																						
										if tile_pos.y+j <= grid_height:
											set_cell(1, Vector2i(tile_pos.x, tile_pos.y+j), 14, Vector2i(0, 0), 0)
											if astar_grid.is_point_solid(Vector2i(tile_pos.x, tile_pos.y+j)) == true and user_units[i].tile_pos != Vector2i(tile_pos.x, tile_pos.y+j):
												hoverflag_2 = false
												break

							var hoverflag_3 = true	
							for j in grid_height:	
								set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
								if hoverflag_3 == true:											
									for k in node2D.structures.size():																													
										if tile_pos.x+j <= grid_height:
											set_cell(1, Vector2i(tile_pos.x+j, tile_pos.y), 14, Vector2i(0, 0), 0)
											if astar_grid.is_point_solid(Vector2i(tile_pos.x+j, tile_pos.y)) == true and user_units[i].tile_pos != Vector2i(tile_pos.x+j, tile_pos.y):
												hoverflag_3 = false
												break

							var hoverflag_4 = true	
							for j in grid_height:	
								set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
								if hoverflag_4 == true:											
									for k in node2D.structures.size():																											
										if tile_pos.y-j >= 0:									
											set_cell(1, Vector2i(tile_pos.x, tile_pos.y-j), 14, Vector2i(0, 0), 0)
											if astar_grid.is_point_solid(Vector2i(tile_pos.x, tile_pos.y-j)) == true and user_units[i].tile_pos != Vector2i(tile_pos.x, tile_pos.y-j):
												hoverflag_4 = false
												break
						
				if tile_pos.x == 0:
					set_cell(1, Vector2i(tile_pos.x-1, tile_pos.y), -1, Vector2i(0, 0), 0)
				if tile_pos.y == 0:
					set_cell(1, Vector2i(tile_pos.x, tile_pos.y-1), -1, Vector2i(0, 0), 0)							
				if tile_pos.x == grid_height-1:
					set_cell(1, Vector2i(tile_pos.x+1, tile_pos.y), -1, Vector2i(0, 0), 0)
				if tile_pos.y == grid_height-1:
					set_cell(1, Vector2i(tile_pos.x, tile_pos.y+1), -1, Vector2i(0, 0), 0)	

				soundstream.stream = soundstream.map_sfx[5]
				soundstream.play()
														
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
			set_cell(2, Vector2i(j,k), -1, Vector2i(0, 0), 0)
	
	#Place hover tiles		
	var surrounding_cells = get_node("../TileMap").get_surrounding_cells(tile_pos)
	
	for k in surrounding_cells.size():
		set_cell(2, tile_pos, -1, Vector2i(0, 0), 0)
		set_cell(2, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), 14, Vector2i(0, 0), 0)									
		if surrounding_cells[k].x <= -1 or surrounding_cells[k].y >= grid_height or surrounding_cells[k].x >= grid_height or surrounding_cells[k].y <= -1:
			set_cell(2, tile_pos, -1, Vector2i(0, 0), 0)
			set_cell(2, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), -1, Vector2i(0, 0), 0)								
	#for k in surrounding_cells.size():
		#set_cell(2, tile_pos, -1, Vector2i(0, 0), 0)
		#set_cell(2, Vector2i(surrounding_cells[k].x+1, surrounding_cells[k].y), 14, Vector2i(0, 0), 0)																																								
		#set_cell(2, Vector2i(surrounding_cells[k].x-1, surrounding_cells[k].y), 14, Vector2i(0, 0), 0)															
		#set_cell(2, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+1), 14, Vector2i(0, 0), 0)																																								
		#set_cell(2, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-1), 14, Vector2i(0, 0), 0)								
	#for k in surrounding_cells.size():
		#set_cell(2, tile_pos, -1, Vector2i(0, 0), 0)
		#set_cell(2, Vector2i(surrounding_cells[k].x+2, surrounding_cells[k].y), 14, Vector2i(0, 0), 0)																																								
		#set_cell(2, Vector2i(surrounding_cells[k].x-2, surrounding_cells[k].y), 14, Vector2i(0, 0), 0)															
		#set_cell(2, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+2), 14, Vector2i(0, 0), 0)																																								
		#set_cell(2, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-2), 14, Vector2i(0, 0), 0)															
	#for k in surrounding_cells.size():
		#set_cell(2, tile_pos, -1, Vector2i(0, 0), 0)
		#set_cell(2, Vector2i(surrounding_cells[k].x+3, surrounding_cells[k].y), 14, Vector2i(0, 0), 0)																																								
		#set_cell(2, Vector2i(surrounding_cells[k].x-3, surrounding_cells[k].y), 14, Vector2i(0, 0), 0)															
		#set_cell(2, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+3), 14, Vector2i(0, 0), 0)																																								
		#set_cell(2, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-3), 14, Vector2i(0, 0), 0)	
	#for k in surrounding_cells.size():
		#set_cell(2, tile_pos, -1, Vector2i(0, 0), 0)
		#set_cell(2, Vector2i(surrounding_cells[k].x+4, surrounding_cells[k].y), 14, Vector2i(0, 0), 0)																																								
		#set_cell(2, Vector2i(surrounding_cells[k].x-4, surrounding_cells[k].y), 14, Vector2i(0, 0), 0)															
		#set_cell(2, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+4), 14, Vector2i(0, 0), 0)																																								
		#set_cell(2, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-4), 14, Vector2i(0, 0), 0)	
											#
	#set_cell(2, tile_pos, -1, Vector2i(0, 0), 0)
	#set_cell(2, Vector2i(tile_pos.x+2, tile_pos.y+2), 14, Vector2i(0, 0), 0)																																								
	#set_cell(2, Vector2i(tile_pos.x-2, tile_pos.y-2), 14, Vector2i(0, 0), 0)															
	#set_cell(2, Vector2i(tile_pos.x+2, tile_pos.y-2), 14, Vector2i(0, 0), 0)																																								
	#set_cell(2, Vector2i(tile_pos.x-2, tile_pos.y+2), 14, Vector2i(0, 0), 0)	
#
	#set_cell(2, tile_pos, -1, Vector2i(0, 0), 0)
	#set_cell(2, Vector2i(tile_pos.x+2, tile_pos.y+3), 14, Vector2i(0, 0), 0)																																								
	#set_cell(2, Vector2i(tile_pos.x-3, tile_pos.y-2), 14, Vector2i(0, 0), 0)															
	#set_cell(2, Vector2i(tile_pos.x+2, tile_pos.y-3), 14, Vector2i(0, 0), 0)																																								
	#set_cell(2, Vector2i(tile_pos.x-3, tile_pos.y+2), 14, Vector2i(0, 0), 0)	
#
	#set_cell(2, tile_pos, -1, Vector2i(0, 0), 0)
	#set_cell(2, Vector2i(tile_pos.x+3, tile_pos.y+2), 14, Vector2i(0, 0), 0)																																								
	#set_cell(2, Vector2i(tile_pos.x-2, tile_pos.y-3), 14, Vector2i(0, 0), 0)															
	#set_cell(2, Vector2i(tile_pos.x+3, tile_pos.y-2), 14, Vector2i(0, 0), 0)																																								
	#set_cell(2, Vector2i(tile_pos.x-2, tile_pos.y+3), 14, Vector2i(0, 0), 0)

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

func show_full_range():
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), 7, Vector2i(0, 0), 0)	

func remove_hover_tiles():
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)	

func user_range_ai(closest_cpu_to_human: Vector2i, active_unit: Area2D):
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)	
																						
	var closest_position = map_to_local(closest_cpu_to_human) + Vector2(0,0) / 2	
	var tile_pos = local_to_map(active_unit.position)		
				
	for i in user_units.size():
		if user_units[i].tile_pos == active_unit.tile_pos:
			right_clicked_unit = user_units[i]
			selected_unit_num = user_units[i].unit_num
			selected_pos = user_units[i].tile_pos	
			attack_range = true												
			break	
			
	for i in user_units.size():
		var unit_pos_map = local_to_map(user_units[i].position)
		if unit_pos_map == active_unit.tile_pos:																				
			var hoverflag_1 = true															
			for j in grid_height:	
				set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
				if hoverflag_1 == true:
					if tile_pos.x-j >= 0:	
						set_cell(1, Vector2i(tile_pos.x-j, tile_pos.y), 14, Vector2i(0, 0), 0)
						if astar_grid.is_point_solid(Vector2i(tile_pos.x-j, tile_pos.y)) == true and active_unit.tile_pos != Vector2i(tile_pos.x-j, tile_pos.y):
							hoverflag_1 = false
							for l in cpu_units.size():
								if cpu_units[l].tile_pos == Vector2i(tile_pos.x-j, tile_pos.y):
									var closest =  map_to_local(Vector2i(tile_pos.x-j, tile_pos.y)) + Vector2(0,0) / 2	
									var attack_center_pos = map_to_local(Vector2i(tile_pos.x-j, tile_pos.y)) + Vector2(0,0) / 2	
									
									if active_unit.scale.x == 1 and active_unit.position.x > attack_center_pos.x:
										active_unit.scale.x = 1
									
									elif active_unit.scale.x == -1 and active_unit.position.x < attack_center_pos.x:
										active_unit.scale.x = -1	
									
									if active_unit.scale.x == -1 and active_unit.position.x > attack_center_pos.x:
										active_unit.scale.x = 1
									
									elif active_unit.scale.x == 1 and active_unit.position.x < attack_center_pos.x:
										active_unit.scale.x = -1																																					
															
									user_units[i].get_child(0).play("attack")	
									
									soundstream.stream = soundstream.map_sfx[3]
									soundstream.play()	
															
									await get_tree().create_timer(0).timeout
									user_units[i].get_child(0).play("default")		
									
									var _bumpedvector = cpu_units[l].tile_pos
									var right_clicked_pos = local_to_map(user_units[i].position)
																		 	
									await SetLinePoints(Vector2(user_units[i].position.x, user_units[i].position.y-16), closest)
									
									if right_clicked_pos.y < cpu_units[l].tile_pos.y and right_clicked_unit.position.x > attack_center_pos.x:	
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y+1)) + Vector2(0,0) / 2	
										var tween: Tween = create_tween()
										tween.tween_property(cpu_units[l], "modulate:v", 1, 0.50).from(5)
										cpu_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										cpu_units[l].position.y -= 1500		
										cpu_units[l].add_to_group("dead") 	
										cpu_units[l].remove_from_group("alive") 														
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
											
									if right_clicked_pos.y > cpu_units[l].tile_pos.y and right_clicked_unit.position.x < attack_center_pos.x:								
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y-1)) + Vector2(0,0) / 2
										var tween: Tween = create_tween()
										tween.tween_property(cpu_units[l], "modulate:v", 1, 0.50).from(5)
										cpu_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										cpu_units[l].position.y -= 1500		
										cpu_units[l].add_to_group("dead") 	
										cpu_units[l].remove_from_group("alive") 														
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false								
										
									if right_clicked_pos.x > cpu_units[l].tile_pos.x and right_clicked_unit.position.x > attack_center_pos.x:	
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x-1, _bumpedvector.y)) + Vector2(0,0) / 2										
										var tween: Tween = create_tween()
										tween.tween_property(cpu_units[l], "modulate:v", 1, 0.50).from(5)
										cpu_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										cpu_units[l].position.y -= 1500		
										cpu_units[l].add_to_group("dead")  	
										cpu_units[l].remove_from_group("alive") 														
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false														
										
									if right_clicked_pos.x < cpu_units[l].tile_pos.x and right_clicked_unit.position.x < attack_center_pos.x:
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x+1, _bumpedvector.y)) + Vector2(0,0) / 2
										var tween: Tween = create_tween()
										tween.tween_property(cpu_units[l], "modulate:v", 1, 0.50).from(5)
										cpu_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										cpu_units[l].position.y -= 1500		
										cpu_units[l].add_to_group("dead")  	
										cpu_units[l].remove_from_group("alive") 														
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
																
									await get_tree().create_timer(0).timeout	
			user_units[i].check_water()																									
			var hoverflag_2 = true										
			for j in grid_height:	
				set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
				if hoverflag_2 == true:																																	
					if tile_pos.y+j <= grid_height:
						set_cell(1, Vector2i(tile_pos.x, tile_pos.y+j), 14, Vector2i(0, 0), 0)
						if astar_grid.is_point_solid(Vector2i(tile_pos.x, tile_pos.y+j)) == true and active_unit.tile_pos != Vector2i(tile_pos.x, tile_pos.y+j):
							hoverflag_2 = false
							for l in cpu_units.size():
								if cpu_units[l].tile_pos == Vector2i(tile_pos.x, tile_pos.y+j):
									var closest =  map_to_local(Vector2i(tile_pos.x, tile_pos.y+j)) + Vector2(0,0) / 2	
									var attack_center_pos = map_to_local(Vector2i(tile_pos.x, tile_pos.y+j)) + Vector2(0,0) / 2	
									
									if active_unit.scale.x == 1 and active_unit.position.x > attack_center_pos.x:
										active_unit.scale.x = 1
									
									elif active_unit.scale.x == -1 and active_unit.position.x < attack_center_pos.x:
										active_unit.scale.x = -1	
									
									if active_unit.scale.x == -1 and active_unit.position.x > attack_center_pos.x:
										active_unit.scale.x = 1
									
									elif active_unit.scale.x == 1 and active_unit.position.x < attack_center_pos.x:
										active_unit.scale.x = -1																																					
															
									user_units[i].get_child(0).play("attack")	
									
									soundstream.stream = soundstream.map_sfx[3]
									soundstream.play()	
															
									await get_tree().create_timer(0.1).timeout
									user_units[i].get_child(0).play("default")	
									
									var _bumpedvector = cpu_units[l].tile_pos
									var right_clicked_pos = local_to_map(user_units[i].position)
																		 	
									await SetLinePoints(Vector2(user_units[i].position.x, user_units[i].position.y-16), closest)
									
									if right_clicked_pos.y < cpu_units[l].tile_pos.y and right_clicked_unit.position.x > attack_center_pos.x:	
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y+1)) + Vector2(0,0) / 2	
										var tween: Tween = create_tween()
										tween.tween_property(cpu_units[l], "modulate:v", 1, 0.50).from(5)
										cpu_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										cpu_units[l].position.y -= 1500		
										cpu_units[l].add_to_group("dead") 	
										cpu_units[l].remove_from_group("alive") 													
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
											
									if right_clicked_pos.y > cpu_units[l].tile_pos.y and right_clicked_unit.position.x < attack_center_pos.x:								
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y-1)) + Vector2(0,0) / 2
										var tween: Tween = create_tween()
										tween.tween_property(cpu_units[l], "modulate:v", 1, 0.50).from(5)
										cpu_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										cpu_units[l].position.y -= 1500		
										cpu_units[l].add_to_group("dead") 		
										cpu_units[l].remove_from_group("alive") 													
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
																		
									if right_clicked_pos.x > cpu_units[l].tile_pos.x and right_clicked_unit.position.x > attack_center_pos.x:	
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x-1, _bumpedvector.y)) + Vector2(0,0) / 2										
										var tween: Tween = create_tween()
										tween.tween_property(cpu_units[l], "modulate:v", 1, 0.50).from(5)
										cpu_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										cpu_units[l].position.y -= 1500		
										cpu_units[l].add_to_group("dead") 	
										cpu_units[l].remove_from_group("alive") 													
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false														
										
									if right_clicked_pos.x < cpu_units[l].tile_pos.x and right_clicked_unit.position.x < attack_center_pos.x:
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x+1, _bumpedvector.y)) + Vector2(0,0) / 2
										var tween: Tween = create_tween()
										tween.tween_property(cpu_units[l], "modulate:v", 1, 0.50).from(5)
										cpu_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										cpu_units[l].position.y -= 1500		
										cpu_units[l].add_to_group("dead") 	
										cpu_units[l].remove_from_group("alive") 														
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
																
									await get_tree().create_timer(0).timeout	
			user_units[i].check_water()
			var hoverflag_3 = true	
			for j in grid_height:	
				set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
				if hoverflag_3 == true:																																								
					if tile_pos.x+j <= grid_height:
						set_cell(1, Vector2i(tile_pos.x+j, tile_pos.y), 14, Vector2i(0, 0), 0)
						if astar_grid.is_point_solid(Vector2i(tile_pos.x+j, tile_pos.y)) == true and active_unit.tile_pos != Vector2i(tile_pos.x+j, tile_pos.y):
							hoverflag_3 = false
							for l in cpu_units.size():
								if cpu_units[l].tile_pos == Vector2i(tile_pos.x+j, tile_pos.y):
									var closest =  map_to_local(Vector2i(tile_pos.x+j, tile_pos.y)) + Vector2(0,0) / 2	
									var attack_center_pos = map_to_local(Vector2i(tile_pos.x+j, tile_pos.y)) + Vector2(0,0) / 2	
									
									if active_unit.scale.x == 1 and active_unit.position.x > attack_center_pos.x:
										active_unit.scale.x = 1
									
									elif active_unit.scale.x == -1 and active_unit.position.x < attack_center_pos.x:
										active_unit.scale.x = -1	
									
									if active_unit.scale.x == -1 and user_units[i].position.x > attack_center_pos.x:
										active_unit.scale.x = 1
									
									elif user_units[i].scale.x == 1 and user_units[i].position.x < attack_center_pos.x:
										user_units[i].scale.x = -1																																					
															
									user_units[i].get_child(0).play("attack")	
									
									soundstream.stream = soundstream.map_sfx[3]
									soundstream.play()	
															
									await get_tree().create_timer(0.1).timeout
									user_units[i].get_child(0).play("default")	
									
									var _bumpedvector = cpu_units[l].tile_pos
									var right_clicked_pos = local_to_map(user_units[i].position)
																		 	
									await SetLinePoints(Vector2(user_units[i].position.x, user_units[i].position.y-16), closest)
									
									if right_clicked_pos.y < cpu_units[l].tile_pos.y and right_clicked_unit.position.x > attack_center_pos.x:	
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y+1)) + Vector2(0,0) / 2	
										var tween: Tween = create_tween()
										tween.tween_property(cpu_units[l], "modulate:v", 1, 0.50).from(5)
										cpu_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										cpu_units[l].position.y -= 1500		
										cpu_units[l].add_to_group("dead") 
										cpu_units[l].remove_from_group("alive") 															
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
											
									if right_clicked_pos.y > cpu_units[l].tile_pos.y and right_clicked_unit.position.x < attack_center_pos.x:								
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y-1)) + Vector2(0,0) / 2
										var tween: Tween = create_tween()
										tween.tween_property(cpu_units[l], "modulate:v", 1, 0.50).from(5)
										cpu_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										cpu_units[l].position.y -= 1500		
										cpu_units[l].add_to_group("dead") 
										cpu_units[l].remove_from_group("alive") 															
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
																		
									if right_clicked_pos.x > cpu_units[l].tile_pos.x and right_clicked_unit.position.x > attack_center_pos.x:	
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x-1, _bumpedvector.y)) + Vector2(0,0) / 2										
										var tween: Tween = create_tween()
										tween.tween_property(cpu_units[l], "modulate:v", 1, 0.50).from(5)
										cpu_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										cpu_units[l].position.y -= 1500		
										cpu_units[l].add_to_group("dead")  	
										cpu_units[l].remove_from_group("alive") 														
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
																								
									if right_clicked_pos.x < cpu_units[l].tile_pos.x and right_clicked_unit.position.x < attack_center_pos.x:
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x+1, _bumpedvector.y)) + Vector2(0,0) / 2
										var tween: Tween = create_tween()
										tween.tween_property(cpu_units[l], "modulate:v", 1, 0.50).from(5)
										cpu_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										cpu_units[l].position.y -= 1500		
										cpu_units[l].add_to_group("dead") 		
										cpu_units[l].remove_from_group("alive") 													
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
																
									await get_tree().create_timer(0).timeout	
			user_units[i].check_water()
			var hoverflag_4 = true	
			for j in grid_height:	
				set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
				if hoverflag_4 == true:																																						
					if tile_pos.y-j >= 0:									
						set_cell(1, Vector2i(tile_pos.x, tile_pos.y-j), 14, Vector2i(0, 0), 0)
						if astar_grid.is_point_solid(Vector2i(tile_pos.x, tile_pos.y-j)) == true and user_units[i].tile_pos != Vector2i(tile_pos.x, tile_pos.y-j):
							hoverflag_4 = false
							for l in cpu_units.size():
								if cpu_units[l].tile_pos == Vector2i(tile_pos.x, tile_pos.y-j):
									var closest =  map_to_local(Vector2i(tile_pos.x, tile_pos.y-j)) + Vector2(0,0) / 2	
									var attack_center_pos = map_to_local(Vector2i(tile_pos.x, tile_pos.y-j)) + Vector2(0,0) / 2	
									
									if user_units[i].scale.x == 1 and user_units[i].position.x > attack_center_pos.x:
										user_units[i].scale.x = 1
									
									elif user_units[i].scale.x == -1 and user_units[i].position.x < attack_center_pos.x:
										user_units[i].scale.x = -1	
									
									if user_units[i].scale.x == -1 and user_units[i].position.x > attack_center_pos.x:
										user_units[i].scale.x = 1
									
									elif user_units[i].scale.x == 1 and user_units[i].position.x < attack_center_pos.x:
										user_units[i].scale.x = -1																																					
															
									user_units[i].get_child(0).play("attack")	
									
									soundstream.stream = soundstream.map_sfx[3]
									soundstream.play()	
															
									await get_tree().create_timer(0.1).timeout
									user_units[i].get_child(0).play("default")	
									
									var _bumpedvector = cpu_units[l].tile_pos
									var right_clicked_pos = local_to_map(user_units[i].position)
																		 	
									await SetLinePoints(Vector2(user_units[i].position.x, user_units[i].position.y-16), closest)
									
									if right_clicked_pos.y < cpu_units[l].tile_pos.y and right_clicked_unit.position.x > attack_center_pos.x:	
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y+1)) + Vector2(0,0) / 2	
										var tween: Tween = create_tween()
										tween.tween_property(cpu_units[l], "modulate:v", 1, 0.50).from(5)
										cpu_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										cpu_units[l].position.y -= 1500		
										cpu_units[l].add_to_group("dead") 	
										cpu_units[l].remove_from_group("alive") 														
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
											
									if right_clicked_pos.y > cpu_units[l].tile_pos.y and right_clicked_unit.position.x < attack_center_pos.x:								
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y-1)) + Vector2(0,0) / 2
										var tween: Tween = create_tween()
										tween.tween_property(cpu_units[l], "modulate:v", 1, 0.50).from(5)
										cpu_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										cpu_units[l].position.y -= 1500		
										cpu_units[l].add_to_group("dead") 
										cpu_units[l].remove_from_group("alive") 															
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
																		
									if right_clicked_pos.x > cpu_units[l].tile_pos.x and right_clicked_unit.position.x > attack_center_pos.x:	
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x-1, _bumpedvector.y)) + Vector2(0,0) / 2										
										var tween: Tween = create_tween()
										tween.tween_property(cpu_units[l], "modulate:v", 1, 0.50).from(5)
										cpu_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										cpu_units[l].position.y -= 1500		
										cpu_units[l].add_to_group("dead") 
										cpu_units[l].remove_from_group("alive") 															
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
																								
									if right_clicked_pos.x < cpu_units[l].tile_pos.x and right_clicked_unit.position.x < attack_center_pos.x:
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x+1, _bumpedvector.y)) + Vector2(0,0) / 2
										var tween: Tween = create_tween()
										tween.tween_property(cpu_units[l], "modulate:v", 1, 0.50).from(5)
										cpu_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										cpu_units[l].position.y -= 1500		
										cpu_units[l].add_to_group("dead") 
										cpu_units[l].remove_from_group("alive") 														
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
																
									await get_tree().create_timer(0).timeout	
			user_units[i].check_water()
				
	if tile_pos.x == 0:
		set_cell(1, Vector2i(tile_pos.x-1, tile_pos.y), -1, Vector2i(0, 0), 0)
	if tile_pos.y == 0:
		set_cell(1, Vector2i(tile_pos.x, tile_pos.y-1), -1, Vector2i(0, 0), 0)							
	if tile_pos.x == grid_height-1:
		set_cell(1, Vector2i(tile_pos.x+1, tile_pos.y), -1, Vector2i(0, 0), 0)
	if tile_pos.y == grid_height-1:
		set_cell(1, Vector2i(tile_pos.x, tile_pos.y+1), -1, Vector2i(0, 0), 0)	

	soundstream.stream = soundstream.map_sfx[5]
	soundstream.play() 
		
func on_cpu():
	all_units.clear()
	user_units.clear()
	cpu_units.clear()	
	
	humans = get_tree().get_nodes_in_group("humans")
	cpu = get_tree().get_nodes_in_group("cpu")
	
	all_units.append_array(humans)	
	all_units.append_array(cpu)		
	user_units.append_array(humans)
	cpu_units.append_array(cpu)		
	
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
	
	moving = false		
	
	alive_humans.clear()					
	for i in user_units.size():
		if user_units[i].is_in_group("alive"):
			alive_humans.append(user_units[i])
			
	alive_cpu.clear()
	for i in cpu_units.size():
		if cpu_units[i].is_in_group("alive"):
			alive_cpu.append(cpu_units[i])
			
	if alive_cpu.size() <= 0 or alive_humans.size() <= 0:	
		return	
		
	var target_human = rng.randi_range(0,alive_cpu.size()-1)
	var closest_humans_to_cpu = alive_cpu[target_human].get_closest_attack_humans()
	var active_unit = alive_cpu[target_human]
	
	await cpu_range_ai(closest_humans_to_cpu.tile_pos, active_unit)
	await remove_hover_tiles()
	await cpu_attack_ai(target_human, closest_humans_to_cpu, active_unit)
	await cpu_range_ai(closest_humans_to_cpu.tile_pos, active_unit)
	await remove_hover_tiles()
	await linemanager.missile_launch()

func cpu_range_ai(closest_humans_to_cpu: Vector2i, active_unit: Area2D):
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)	
																						
	var closest_position = map_to_local(closest_humans_to_cpu) + Vector2(0,0) / 2	
	var tile_pos = local_to_map(active_unit.position)		
				
	for i in cpu_units.size():
		if cpu_units[i].tile_pos == active_unit.tile_pos:
			right_clicked_unit = cpu_units[i]
			selected_unit_num = cpu_units[i].unit_num
			selected_pos = cpu_units[i].tile_pos	
			attack_range = true												
			break	
			
	for i in cpu_units.size():
		var unit_pos_map = local_to_map(cpu_units[i].position)
		if unit_pos_map == active_unit.tile_pos:																		
			var hoverflag_1 = true															
			for j in grid_height:	
				set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
				if hoverflag_1 == true:
					if tile_pos.x-j >= 0:	
						set_cell(1, Vector2i(tile_pos.x-j, tile_pos.y), 14, Vector2i(0, 0), 0)
						if astar_grid.is_point_solid(Vector2i(tile_pos.x-j, tile_pos.y)) == true and cpu_units[i].tile_pos != Vector2i(tile_pos.x-j, tile_pos.y):
							hoverflag_1 = false
							for l in user_units.size():
								if user_units[l].tile_pos == Vector2i(tile_pos.x-j, tile_pos.y):
									var closest =  map_to_local(Vector2i(tile_pos.x-j, tile_pos.y)) + Vector2(0,0) / 2	
									var attack_center_pos = map_to_local(Vector2i(tile_pos.x-j, tile_pos.y)) + Vector2(0,0) / 2	
									
									if cpu_units[i].scale.x == 1 and cpu_units[i].position.x > attack_center_pos.x:
										cpu_units[i].scale.x = 1
									
									elif cpu_units[i].scale.x == -1 and cpu_units[i].position.x < attack_center_pos.x:
										cpu_units[i].scale.x = -1	
									
									if cpu_units[i].scale.x == -1 and cpu_units[i].position.x > attack_center_pos.x:
										cpu_units[i].scale.x = 1
									
									elif cpu_units[i].scale.x == 1 and cpu_units[i].position.x < attack_center_pos.x:
										cpu_units[i].scale.x = -1																																					
															
									cpu_units[i].get_child(0).play("attack")	
									
									soundstream.stream = soundstream.map_sfx[3]
									soundstream.play()	
															
									await get_tree().create_timer(0).timeout
									cpu_units[i].get_child(0).play("default")		
									
									var _bumpedvector = user_units[l].tile_pos
									var right_clicked_pos = local_to_map(cpu_units[i].position)
																		 	
									await SetLinePoints(Vector2(cpu_units[i].position.x, cpu_units[i].position.y-16), closest)
									
									if right_clicked_pos.y < user_units[l].tile_pos.y and right_clicked_unit.position.x > attack_center_pos.x:	
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y+1)) + Vector2(0,0) / 2	
										var tween: Tween = create_tween()
										tween.tween_property(user_units[l], "modulate:v", 1, 0.50).from(5)
										user_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										user_units[l].position.y -= 1500		
										user_units[l].add_to_group("dead") 	
										user_units[l].remove_from_group("alive") 														
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
											
									if right_clicked_pos.y > user_units[l].tile_pos.y and right_clicked_unit.position.x < attack_center_pos.x:								
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y-1)) + Vector2(0,0) / 2
										var tween: Tween = create_tween()
										tween.tween_property(user_units[l], "modulate:v", 1, 0.50).from(5)
										user_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										user_units[l].position.y -= 1500		
										user_units[l].add_to_group("dead") 		
										user_units[l].remove_from_group("alive") 													
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false								
										
									if right_clicked_pos.x > user_units[l].tile_pos.x and right_clicked_unit.position.x > attack_center_pos.x:	
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x-1, _bumpedvector.y)) + Vector2(0,0) / 2										
										var tween: Tween = create_tween()
										tween.tween_property(user_units[l], "modulate:v", 1, 0.50).from(5)
										user_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										user_units[l].position.y -= 1500		
										user_units[l].add_to_group("dead")  
										user_units[l].remove_from_group("alive") 															
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false														
										
									if right_clicked_pos.x < user_units[l].tile_pos.x and right_clicked_unit.position.x < attack_center_pos.x:
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x+1, _bumpedvector.y)) + Vector2(0,0) / 2
										var tween: Tween = create_tween()
										tween.tween_property(user_units[l], "modulate:v", 1, 0.50).from(5)
										user_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										user_units[l].position.y -= 1500		
										user_units[l].add_to_group("dead")  
										user_units[l].remove_from_group("alive") 															
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
																
									await get_tree().create_timer(0).timeout	
			cpu_units[i].check_water()																									
			var hoverflag_2 = true										
			for j in grid_height:	
				set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
				if hoverflag_2 == true:																																	
					if tile_pos.y+j <= grid_height:
						set_cell(1, Vector2i(tile_pos.x, tile_pos.y+j), 14, Vector2i(0, 0), 0)
						if astar_grid.is_point_solid(Vector2i(tile_pos.x, tile_pos.y+j)) == true and cpu_units[i].tile_pos != Vector2i(tile_pos.x, tile_pos.y+j):
							hoverflag_2 = false
							for l in user_units.size():
								if user_units[l].tile_pos == Vector2i(tile_pos.x, tile_pos.y+j):
									var closest =  map_to_local(Vector2i(tile_pos.x, tile_pos.y+j)) + Vector2(0,0) / 2	
									var attack_center_pos = map_to_local(Vector2i(tile_pos.x, tile_pos.y+j)) + Vector2(0,0) / 2	
									
									if cpu_units[i].scale.x == 1 and cpu_units[i].position.x > attack_center_pos.x:
										cpu_units[i].scale.x = 1
									
									elif cpu_units[i].scale.x == -1 and cpu_units[i].position.x < attack_center_pos.x:
										cpu_units[i].scale.x = -1	
									
									if cpu_units[i].scale.x == -1 and cpu_units[i].position.x > attack_center_pos.x:
										cpu_units[i].scale.x = 1
									
									elif cpu_units[i].scale.x == 1 and cpu_units[i].position.x < attack_center_pos.x:
										cpu_units[i].scale.x = -1																																					
															
									cpu_units[i].get_child(0).play("attack")	
									
									soundstream.stream = soundstream.map_sfx[3]
									soundstream.play()	
															
									await get_tree().create_timer(0.1).timeout
									cpu_units[i].get_child(0).play("default")	
									
									var _bumpedvector = cpu_units[l].tile_pos
									var right_clicked_pos = local_to_map(cpu_units[i].position)
																		 	
									await SetLinePoints(Vector2(cpu_units[i].position.x, cpu_units[i].position.y-16), closest)
									
									if right_clicked_pos.y < user_units[l].tile_pos.y and right_clicked_unit.position.x > attack_center_pos.x:	
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y+1)) + Vector2(0,0) / 2	
										var tween: Tween = create_tween()
										tween.tween_property(cpu_units[l], "modulate:v", 1, 0.50).from(5)
										user_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										user_units[l].position.y -= 1500		
										user_units[l].add_to_group("dead") 		
										user_units[l].remove_from_group("alive") 												
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
											
									if right_clicked_pos.y > user_units[l].tile_pos.y and right_clicked_unit.position.x < attack_center_pos.x:								
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y-1)) + Vector2(0,0) / 2
										var tween: Tween = create_tween()
										tween.tween_property(user_units[l], "modulate:v", 1, 0.50).from(5)
										user_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										user_units[l].position.y -= 1500		
										user_units[l].add_to_group("dead") 	
										user_units[l].remove_from_group("alive") 														
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
																		
									if right_clicked_pos.x > user_units[l].tile_pos.x and right_clicked_unit.position.x > attack_center_pos.x:	
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x-1, _bumpedvector.y)) + Vector2(0,0) / 2										
										var tween: Tween = create_tween()
										tween.tween_property(user_units[l], "modulate:v", 1, 0.50).from(5)
										user_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										user_units[l].position.y -= 1500		
										user_units[l].add_to_group("dead") 		
										user_units[l].remove_from_group("alive") 												
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false														
										
									if right_clicked_pos.x < user_units[l].tile_pos.x and right_clicked_unit.position.x < attack_center_pos.x:
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x+1, _bumpedvector.y)) + Vector2(0,0) / 2
										var tween: Tween = create_tween()
										tween.tween_property(user_units[l], "modulate:v", 1, 0.50).from(5)
										user_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										user_units[l].position.y -= 1500		
										user_units[l].add_to_group("dead") 	
										user_units[l].remove_from_group("alive") 														
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
																
									await get_tree().create_timer(0).timeout	
			cpu_units[i].check_water()
			var hoverflag_3 = true	
			for j in grid_height:	
				set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
				if hoverflag_3 == true:																																								
					if tile_pos.x+j <= grid_height:
						set_cell(1, Vector2i(tile_pos.x+j, tile_pos.y), 14, Vector2i(0, 0), 0)
						if astar_grid.is_point_solid(Vector2i(tile_pos.x+j, tile_pos.y)) == true and cpu_units[i].tile_pos != Vector2i(tile_pos.x+j, tile_pos.y):
							hoverflag_3 = false
							for l in user_units.size():
								if user_units[l].tile_pos == Vector2i(tile_pos.x+j, tile_pos.y):
									var closest =  map_to_local(Vector2i(tile_pos.x+j, tile_pos.y)) + Vector2(0,0) / 2	
									var attack_center_pos = map_to_local(Vector2i(tile_pos.x+j, tile_pos.y)) + Vector2(0,0) / 2	
									
									if cpu_units[i].scale.x == 1 and cpu_units[i].position.x > attack_center_pos.x:
										cpu_units[i].scale.x = 1
									
									elif cpu_units[i].scale.x == -1 and cpu_units[i].position.x < attack_center_pos.x:
										cpu_units[i].scale.x = -1	
									
									if cpu_units[i].scale.x == -1 and cpu_units[i].position.x > attack_center_pos.x:
										cpu_units[i].scale.x = 1
									
									elif cpu_units[i].scale.x == 1 and cpu_units[i].position.x < attack_center_pos.x:
										cpu_units[i].scale.x = -1																																					
															
									cpu_units[i].get_child(0).play("attack")	
									
									soundstream.stream = soundstream.map_sfx[3]
									soundstream.play()	
															
									await get_tree().create_timer(0.1).timeout
									cpu_units[i].get_child(0).play("default")	
									
									var _bumpedvector = cpu_units[l].tile_pos
									var right_clicked_pos = local_to_map(cpu_units[i].position)
																		 	
									await SetLinePoints(Vector2(cpu_units[i].position.x, cpu_units[i].position.y-16), closest)
									
									if right_clicked_pos.y < user_units[l].tile_pos.y and right_clicked_unit.position.x > attack_center_pos.x:	
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y+1)) + Vector2(0,0) / 2	
										var tween: Tween = create_tween()
										tween.tween_property(user_units[l], "modulate:v", 1, 0.50).from(5)
										user_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										user_units[l].position.y -= 1500		
										user_units[l].add_to_group("dead") 		
										user_units[l].remove_from_group("alive") 													
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
											
									if right_clicked_pos.y > user_units[l].tile_pos.y and right_clicked_unit.position.x < attack_center_pos.x:								
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y-1)) + Vector2(0,0) / 2
										var tween: Tween = create_tween()
										tween.tween_property(user_units[l], "modulate:v", 1, 0.50).from(5)
										user_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										user_units[l].position.y -= 1500		
										user_units[l].add_to_group("dead") 
										user_units[l].remove_from_group("alive") 
										user_units[l].remove_from_group("zombies") 															
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
																		
									if right_clicked_pos.x > user_units[l].tile_pos.x and right_clicked_unit.position.x > attack_center_pos.x:	
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x-1, _bumpedvector.y)) + Vector2(0,0) / 2										
										var tween: Tween = create_tween()
										tween.tween_property(user_units[l], "modulate:v", 1, 0.50).from(5)
										user_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										user_units[l].position.y -= 1500		
										user_units[l].add_to_group("dead")  	
										user_units[l].remove_from_group("alive") 														
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
																								
									if right_clicked_pos.x < cpu_units[l].tile_pos.x and right_clicked_unit.position.x < attack_center_pos.x:
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x+1, _bumpedvector.y)) + Vector2(0,0) / 2
										var tween: Tween = create_tween()
										tween.tween_property(user_units[l], "modulate:v", 1, 0.50).from(5)
										user_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										user_units[l].position.y -= 1500		
										user_units[l].add_to_group("dead") 		
										user_units[l].remove_from_group("alive") 													
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
																
									await get_tree().create_timer(0).timeout	
			cpu_units[i].check_water()
			var hoverflag_4 = true	
			for j in grid_height:	
				set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
				if hoverflag_4 == true:																																						
					if tile_pos.y-j >= 0:									
						set_cell(1, Vector2i(tile_pos.x, tile_pos.y-j), 14, Vector2i(0, 0), 0)
						if astar_grid.is_point_solid(Vector2i(tile_pos.x, tile_pos.y-j)) == true and cpu_units[i].tile_pos != Vector2i(tile_pos.x, tile_pos.y-j):
							hoverflag_4 = false
							for l in user_units.size():
								if user_units[l].tile_pos == Vector2i(tile_pos.x, tile_pos.y-j):
									var closest =  map_to_local(Vector2i(tile_pos.x, tile_pos.y-j)) + Vector2(0,0) / 2	
									var attack_center_pos = map_to_local(Vector2i(tile_pos.x, tile_pos.y-j)) + Vector2(0,0) / 2	
									
									if cpu_units[i].scale.x == 1 and cpu_units[i].position.x > attack_center_pos.x:
										cpu_units[i].scale.x = 1
									
									elif cpu_units[i].scale.x == -1 and cpu_units[i].position.x < attack_center_pos.x:
										cpu_units[i].scale.x = -1	
									
									if cpu_units[i].scale.x == -1 and cpu_units[i].position.x > attack_center_pos.x:
										cpu_units[i].scale.x = 1
									
									elif cpu_units[i].scale.x == 1 and cpu_units[i].position.x < attack_center_pos.x:
										cpu_units[i].scale.x = -1																																					
															
									cpu_units[i].get_child(0).play("attack")	
									
									soundstream.stream = soundstream.map_sfx[3]
									soundstream.play()	
															
									await get_tree().create_timer(0.1).timeout
									cpu_units[i].get_child(0).play("default")	
									
									var _bumpedvector = cpu_units[l].tile_pos
									var right_clicked_pos = local_to_map(cpu_units[i].position)
																		 	
									await SetLinePoints(Vector2(cpu_units[i].position.x, cpu_units[i].position.y-16), closest)
									
									if right_clicked_pos.y < user_units[l].tile_pos.y and right_clicked_unit.position.x > attack_center_pos.x:	
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y+1)) + Vector2(0,0) / 2	
										var tween: Tween = create_tween()
										tween.tween_property(user_units[l], "modulate:v", 1, 0.50).from(5)
										user_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										user_units[l].position.y -= 1500		
										user_units[l].add_to_group("dead") 		
										user_units[l].remove_from_group("alive") 													
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
											
									if right_clicked_pos.y > user_units[l].tile_pos.y and right_clicked_unit.position.x < attack_center_pos.x:								
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y-1)) + Vector2(0,0) / 2
										var tween: Tween = create_tween()
										tween.tween_property(user_units[l], "modulate:v", 1, 0.50).from(5)
										user_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										user_units[l].position.y -= 1500		
										user_units[l].add_to_group("dead") 	
										user_units[l].remove_from_group("alive") 														
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
																		
									if right_clicked_pos.x > user_units[l].tile_pos.x and right_clicked_unit.position.x > attack_center_pos.x:	
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x-1, _bumpedvector.y)) + Vector2(0,0) / 2										
										var tween: Tween = create_tween()
										tween.tween_property(user_units[l], "modulate:v", 1, 0.50).from(5)
										user_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										user_units[l].position.y -= 1500		
										user_units[l].add_to_group("dead") 		
										user_units[l].remove_from_group("alive") 													
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
																								
									if right_clicked_pos.x < user_units[l].tile_pos.x and right_clicked_unit.position.x < attack_center_pos.x:
										var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x+1, _bumpedvector.y)) + Vector2(0,0) / 2
										var tween: Tween = create_tween()
										tween.tween_property(user_units[l], "modulate:v", 1, 0.50).from(5)
										user_units[l].get_child(0).play("death")
										soundstream.stream = soundstream.map_sfx[1]
										soundstream.play()								
										await get_tree().create_timer(0.5).timeout	
										user_units[l].position.y -= 1500		
										user_units[l].add_to_group("dead") 		
										user_units[l].remove_from_group("alive") 												
										soundstream.stream = soundstream.map_sfx[7]
										soundstream.play()	
										attack_range = false
																
									await get_tree().create_timer(0).timeout	
			cpu_units[i].check_water()
				
	if tile_pos.x == 0:
		set_cell(1, Vector2i(tile_pos.x-1, tile_pos.y), -1, Vector2i(0, 0), 0)
	if tile_pos.y == 0:
		set_cell(1, Vector2i(tile_pos.x, tile_pos.y-1), -1, Vector2i(0, 0), 0)							
	if tile_pos.x == grid_height-1:
		set_cell(1, Vector2i(tile_pos.x+1, tile_pos.y), -1, Vector2i(0, 0), 0)
	if tile_pos.y == grid_height-1:
		set_cell(1, Vector2i(tile_pos.x, tile_pos.y+1), -1, Vector2i(0, 0), 0)	

	soundstream.stream = soundstream.map_sfx[5]
	soundstream.play() 
		
func cpu_attack_ai(target_human: int, closest_cpu_to_human: Area2D, active_unit: Area2D):				
	if !closest_cpu_to_human.is_in_group("dead"):
		var closest_atack = closest_cpu_to_human							
		var cpu_target_pos = local_to_map(closest_atack.position)
		var cpu_surrounding_cells = get_surrounding_cells(cpu_target_pos)
		var active_pos = local_to_map(active_unit.position)
		
		active_unit.get_child(0).play("move")
		var open_tile = rng.randi_range(0,3)
		if astar_grid.is_point_solid(cpu_surrounding_cells[open_tile]) == false and get_cell_source_id(0, cpu_surrounding_cells[open_tile]) != -1: 
			
			var patharray = astar_grid.get_point_path(active_pos, cpu_surrounding_cells[open_tile])
			# Find path and set hover cells
			for h in patharray.size():
				await get_tree().create_timer(0.01).timeout
				set_cell(1, patharray[h], 7, Vector2i(0, 0), 0)
				if h == active_unit.unit_movement:
					get_node("../TileMap").set_cell(1, patharray[h], 15, Vector2i(0, 0), 0)			
				
			# Move unit		
			for h in patharray.size():
				moving = true		
				if active_unit.check_water() == true:
					var tile_center_position = map_to_local(patharray[h]) + Vector2(0,0) / 2
					var unit_pos = local_to_map(active_unit.position)
					active_unit.z_index = unit_pos.x + unit_pos.y																					
					var tween = create_tween()
					tween.tween_property(active_unit, "position", tile_center_position, 0.1)								
					await tween.finished
					active_unit.get_child(0).play("default")
					for i in user_units.size():
						user_units[i].selected = false
						
					moving = false	
					
				elif active_unit.check_land() == true:							
					active_unit.get_child(0).play("move")						
					var tile_center_position = map_to_local(patharray[h]) + Vector2(0,0) / 2
					var unit_pos = local_to_map(active_unit.position)
					active_unit.z_index = unit_pos.x + unit_pos.y																					
					var tween = create_tween()
					tween.tween_property(active_unit, "position", tile_center_position, 0.1)								
					await tween.finished
					active_unit.get_child(0).play("default")
					for i in user_units.size():
						user_units[i].selected = false
						
					moving = false		
						
					soundstream.stream = soundstream.map_sfx[6]
					soundstream.play()						
				
				if h == active_unit.unit_movement:
					break	
									
			moving = false
							
			# Remove hover cells
			for h in patharray.size():
				set_cell(1, patharray[h], -1, Vector2i(0, 0), 0)
			
			active_unit.get_child(0).play("default")	
			
			for i in 4:
				var cpu_pos = local_to_map(active_unit.position)
				if cpu_pos == cpu_surrounding_cells[i]:
					var attack_center_position = map_to_local(cpu_target_pos) + Vector2(0,0) / 2	
								
					if active_unit.scale.x == 1 and active_unit.position.x > attack_center_position.x:
						active_unit.scale.x = 1
					elif active_unit.scale.x == -1 and active_unit.position.x < attack_center_position.x:
						active_unit.scale.x = -1	
					if active_unit.scale.x == -1 and active_unit.position.x > attack_center_position.x:
						active_unit.scale.x = 1
					elif active_unit.scale.x == 1 and active_unit.position.x < attack_center_position.x:
						active_unit.scale.x = -1						
		

					active_unit.get_child(0).play("attack")	
					
					soundstream.stream = soundstream.map_sfx[4]
					soundstream.play()							
						
					#await get_tree().create_timer(1).timeout
					
					var tween: Tween = create_tween()
					tween.tween_property(closest_atack, "modulate:v", 1, 0.50).from(5)						
					closest_atack.get_child(0).play("death")	
					
					soundstream.stream = soundstream.map_sfx[7]
					soundstream.play()		
									
					await get_tree().create_timer(1).timeout
					closest_atack.add_to_group("dead")
					closest_atack.remove_from_group("alive")
					closest_atack.position.y -= 1500
					active_unit.get_child(0).play("default")	
					break
									
			moving = false
			active_unit.check_land()
			active_unit.check_water()	
		else:
			active_unit.check_land()
			active_unit.check_water()
			active_unit.get_child(0).play("default")				
			on_cpu()
			
func arrays():
	all_units.clear()
	user_units.clear()
	cpu_units.clear()		
	
	humans = get_tree().get_nodes_in_group("humans")
	cpu = get_tree().get_nodes_in_group("cpu")
	
	all_units.append_array(humans)	
	all_units.append_array(cpu)		
	user_units.append_array(humans)
	cpu_units.append_array(cpu)			

	alive_humans.clear()	
	for i in user_units.size():
		if !user_units[i].is_in_group("dead"):
			alive_humans.append(user_units[i])
	
	alive_cpu.clear()		
	for i in cpu_units.size():
		if !cpu_units[i].is_in_group("dead"):
			alive_cpu.append(cpu_units[i])			

	
func SetLinePoints(a: Vector2, b: Vector2):
	var _a = get_node("../TileMap").local_to_map(a)
	var _b = get_node("../TileMap").local_to_map(b)		

	var projectile = preload("res://assets/scenes/prefab/projectile.scn")
	var projectile_instance = projectile.instantiate()
	var projectile_position = get_node("../TileMap").map_to_local(_a) + Vector2(0,0) / 2
	projectile_instance.set_name("explosion")
	get_parent().add_child(projectile_instance)
	projectile_instance.position = projectile_position	
	projectile_instance.position.y -= 16
	projectile_instance.z_index = (_a.x + _a.y) + 1
		
	projectile_instance.position = a
	projectile_instance.z_index = projectile_instance.position.x + projectile_instance.position.y
	var tween: Tween = create_tween()
	b.y -= 16
	tween.tween_property(projectile_instance, "position", b, 1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)	

	var blast = preload("res://assets/scenes/vfx/explosion.scn")
	var blast_instance = blast.instantiate()
	var blast_position = get_node("../TileMap").map_to_local(_a) + Vector2(0,0) / 2
	blast_instance.set_name("blast")
	get_parent().add_child(blast_instance)
	blast_instance.position = blast_position	
	blast_instance.position.y -= 16
	blast_instance.z_index = (_a.x + _a.y) + 1
		
	blast_instance.position = a
	blast_instance.z_index = blast_instance.position.x + blast_instance.position.y
	var tween_blast: Tween = create_tween()
	b.y -= 16
	tween_blast.tween_property(blast_instance, "position", b, 1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)	
	await get_tree().create_timer(1).timeout		

	projectile_instance.queue_free()		
	blast_instance.queue_free()	

	var explosion = preload("res://assets/scenes/vfx/explosion.scn")
	var explosion_instance = explosion.instantiate()
	var explosion_position = get_node("../TileMap").map_to_local(_b) + Vector2(0,0) / 2
	explosion_instance.set_name("explosion")
	get_parent().add_child(explosion_instance)
	explosion_instance.position = explosion_position	
	explosion_instance.position.y -= 16
	explosion_instance.z_index = (_b.x + _b.y) + 1

	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)	
			
	attack_range = false		
