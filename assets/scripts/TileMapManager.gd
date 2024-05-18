extends TileMap

@export var node2D: Node2D

var grid = []
var grid_width = 32
var grid_height = 32

var astar_grid = AStarGrid2D.new()
var clicked_pos = Vector2i(0,0);

var rng = RandomNumberGenerator.new()

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
	
func _input(event):
	if event is InputEventKey:	
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()
				
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:	
			if event.pressed:
				var mouse_position = get_global_mouse_position()
				mouse_position.y += 8
				var tile_pos = local_to_map(mouse_position)	
				if astar_grid.is_point_solid(tile_pos):
					show_path(tile_pos)
				
func show_path(tile_pos):
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
			
	var rand = rng.randi_range(0, node2D.structures.size()-1)		
	var coord = node2D.structures[rand].coord		
	var cells_around = get_surrounding_cells(coord)  				
	var patharray = astar_grid.get_point_path(tile_pos, cells_around[0])			
	# Find path and set hover cells
	if patharray.size() >= 1 and cells_around.size() >= 0:
		for h in patharray.size():
			await get_tree().create_timer(0.05).timeout
			set_cell(1, patharray[h], 7, Vector2i(0, 0), 0)	
		
		var tween: Tween = create_tween()
		tween.tween_property(get_node("/root/Node2D").structures[rand], "modulate:v", 1, 0.20).from(5)										
	else:
		show_path(tile_pos)
		return	
				

