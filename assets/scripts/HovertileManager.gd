extends Sprite2D

@export var Map: TileMap
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("esc"):
		get_tree().quit()
			
	# Tile hover
	var mouse_pos = get_global_mouse_position()
	mouse_pos.y += 8
	var tile_pos = Map.local_to_map(mouse_pos)
	var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2

	var tile_data = Map.get_cell_tile_data(0, tile_pos)

	if tile_data is TileData:					
		position = tile_center_pos
		z_index = tile_pos.x + tile_pos.y
		#print(tile_pos);	

	if Input.is_action_pressed("space"):
		for i in get_node("/root/Node2D").structures.size():
			var tween: Tween = create_tween()
			var random = rng.randi_range(0, get_node("/root/Node2D").structures.size()-1)
			tween.tween_property(get_node("/root/Node2D").structures[i], "modulate:v", 1, 0.1).from(5)	
			get_node("/root/Node2D").structures[i].get_child(0).play("default")	
			await get_tree().create_timer(0).timeout
