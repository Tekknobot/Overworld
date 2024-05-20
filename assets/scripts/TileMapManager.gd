extends TileMap

@export var node2D: Node2D

var grid = []
var grid_width = 64
var grid_height = 64

var astar_grid = AStarGrid2D.new()
var clicked_pos = Vector2i(0,0);

var rng = RandomNumberGenerator.new()
var open_tiles = []

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
				show_path(tile_pos)
					
				
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
				

