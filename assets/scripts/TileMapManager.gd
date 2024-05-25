extends TileMap

@export var node2D: Node2D
@onready var soundstream = $"../SoundStream"

var grid = []
var grid_width = 64
var grid_height = 64

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
		if event.pressed and event.keycode == KEY_2:
			pass
						
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and get_node("../SpawnManager").spawn_complete == true and moving == false:	
			if event.pressed:
				var mouse_pos = get_global_mouse_position()
				mouse_pos.y += 8
				var tile_pos = local_to_map(mouse_pos)
				var mouse_position = map_to_local(tile_pos) + Vector2(0,0) / 2	
				#var tile_data = get_cell_tile_data(0, tile_pos)

				clicked_pos = tile_pos	
				
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
						
				# Ranged Attack
				for h in all_units.size():					
					var clicked_center_pos = map_to_local(clicked_pos) + Vector2(0,0) / 2
					left_clicked_unit = all_units[h]
					
					#Butch Projectile shoot	
					if mouse_position == all_units[h].position and get_cell_source_id(1, tile_pos) == 14 and attack_range == true:
						var attack_center_pos = map_to_local(clicked_pos) + Vector2(0,0) / 2	
						
						if right_clicked_unit.scale.x == 1 and right_clicked_unit.position.x > attack_center_pos.x:
							right_clicked_unit.scale.x = 1
						
						elif right_clicked_unit.scale.x == -1 and right_clicked_unit.position.x < attack_center_pos.x:
							right_clicked_unit.scale.x = -1	
						
						if right_clicked_unit.scale.x == -1 and right_clicked_unit.position.x > attack_center_pos.x:
							right_clicked_unit.scale.x = 1
						
						elif right_clicked_unit.scale.x == 1 and right_clicked_unit.position.x < attack_center_pos.x:
							right_clicked_unit.scale.x = -1																																					
												
						right_clicked_unit.get_child(0).play("attack")	
						
						soundstream.stream = soundstream.map_sfx[3]
						soundstream.play()	
												
						await get_tree().create_timer(0.1).timeout
						right_clicked_unit.get_child(0).play("default")		
						
						var _bumpedvector = clicked_pos
						var right_clicked_pos = local_to_map(right_clicked_unit.position)
						
						 	
						await SetLinePoints(Vector2(right_clicked_unit.position.x,right_clicked_unit.position.y-16), Vector2(all_units[h].position.x,all_units[h].position.y-16))
						all_units[h].get_child(0).set_offset(Vector2(0,0))
													
						if right_clicked_pos.y < clicked_pos.y and right_clicked_unit.position.x > attack_center_pos.x:	
							var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y+1)) + Vector2(0,0) / 2
							get_node("../TileMap").all_units[h].position = clicked_pos
							all_units[h].position = tile_center_pos	
							var unit_pos = local_to_map(all_units[h].position)										
							all_units[h].z_index = unit_pos.x + unit_pos.y	
							var tween: Tween = create_tween()
							tween.tween_property(all_units[h], "modulate:v", 1, 0.50).from(5)
							all_units[h].get_child(0).play("death")
							soundstream.stream = soundstream.map_sfx[1]
							soundstream.play()								
							await get_tree().create_timer(0.5).timeout	
							all_units[h].position.y -= 500		
							all_units[h].add_to_group("dead") 
							all_units[h].remove_from_group("zombies") 															
							soundstream.stream = soundstream.map_sfx[7]
							soundstream.play()	
							
						if right_clicked_pos.y > clicked_pos.y and right_clicked_unit.position.x < attack_center_pos.x:								
							var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y-1)) + Vector2(0,0) / 2
							get_node("../TileMap").all_units[h].position = clicked_pos
							all_units[h].position = tile_center_pos	
							var unit_pos = local_to_map(all_units[h].position)										
							all_units[h].z_index = unit_pos.x + unit_pos.y
							var tween: Tween = create_tween()
							tween.tween_property(all_units[h], "modulate:v", 1, 0.50).from(5)
							all_units[h].get_child(0).play("death")
							soundstream.stream = soundstream.map_sfx[1]
							soundstream.play()								
							await get_tree().create_timer(0.5).timeout	
							all_units[h].position.y -= 500		
							all_units[h].add_to_group("dead") 
							all_units[h].remove_from_group("zombies") 																					
							soundstream.stream = soundstream.map_sfx[7]
							soundstream.play()	
														
						if right_clicked_pos.x > clicked_pos.x and right_clicked_unit.position.x > attack_center_pos.x:	
							var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x-1, _bumpedvector.y)) + Vector2(0,0) / 2										
							get_node("../TileMap").all_units[h].position = clicked_pos
							all_units[h].position = tile_center_pos	
							var unit_pos = local_to_map(all_units[h].position)										
							all_units[h].z_index = unit_pos.x + unit_pos.y
							var tween: Tween = create_tween()
							tween.tween_property(all_units[h], "modulate:v", 1, 0.50).from(5)
							all_units[h].get_child(0).play("death")
							soundstream.stream = soundstream.map_sfx[1]
							soundstream.play()									
							await get_tree().create_timer(0.5).timeout	
							all_units[h].position.y -= 500		
							all_units[h].add_to_group("dead") 
							all_units[h].remove_from_group("zombies") 								
							soundstream.stream = soundstream.map_sfx[7]
							soundstream.play()	
																				
						if right_clicked_pos.x < clicked_pos.x and right_clicked_unit.position.x < attack_center_pos.x:
							var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x+1, _bumpedvector.y)) + Vector2(0,0) / 2
							get_node("../TileMap").all_units[h].position = clicked_pos
							all_units[h].position = tile_center_pos	
							var unit_pos = local_to_map(all_units[h].position)										
							all_units[h].z_index = unit_pos.x + unit_pos.y		
							var tween: Tween = create_tween()
							tween.tween_property(all_units[h], "modulate:v", 1, 0.50).from(5)
							all_units[h].get_child(0).play("death")
							soundstream.stream = soundstream.map_sfx[1]
							soundstream.play()								
							await get_tree().create_timer(0.5).timeout	
							all_units[h].position.y -= 500		
							all_units[h].add_to_group("dead") 
							all_units[h].remove_from_group("zombies") 								
							soundstream.stream = soundstream.map_sfx[7]
							soundstream.play()	
													
						await get_tree().create_timer(0).timeout	
						
					if all_units[h].in_water == true:
						all_units[h].get_child(0).play("water")
																		
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
							if user_units[selected_unit_num].check_water() == true:
								pass
							
						elif user_units[selected_unit_num].check_land() == true:							
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
							soundstream.stream = soundstream.map_sfx[6]
							soundstream.play()														

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
				if tile_pos.x == 15:
					set_cell(1, Vector2i(tile_pos.x+1, tile_pos.y), -1, Vector2i(0, 0), 0)
				if tile_pos.y == 15:
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

func show_full_range():
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), 7, Vector2i(0, 0), 0)	

func SetLinePoints(a: Vector2, b: Vector2):
	var _a = get_node("../TileMap").local_to_map(a)
	var _b = get_node("../TileMap").local_to_map(b)		

	var projectile = preload("res://assets/scenes/vfx/explosion.scn")
	var projectile_instance = projectile.instantiate()
	var projectile_position = get_node("../TileMap").map_to_local(_a) + Vector2(0,0) / 2
	projectile_instance.set_name("explosion")
	get_parent().add_child(projectile_instance)
	projectile_instance.position = projectile_position	
	projectile_instance.position.y -= 16
	projectile_instance.z_index = (_b.x + _b.y) + 1
		
	projectile_instance.position = a
	projectile_instance.z_index = projectile_instance.position.x + projectile_instance.position.y
	var tween: Tween = create_tween()
	tween.tween_property(projectile_instance, "position", b, 1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)	
	await get_tree().create_timer(1).timeout	

	projectile_instance.queue_free()		

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

func remove_hover_tiles():
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)	
