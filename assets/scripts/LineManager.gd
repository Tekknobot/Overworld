extends Node2D

@export var Map: TileMap
@export var line_2d: Line2D

var line2D = preload("res://assets/scenes/prefab/line_2d.scn")
var explosion = preload("res://assets/scenes/vfx/explosion.scn")
var sparks = preload("res://assets/scenes/vfx/blood.scn")

var point1 : Vector2
var _point2 : Vector2

var grid_width = 64
var grid_height = 64

var rng = RandomNumberGenerator.new()
var trajectory_set = false
var trajectory_end = false

var points = []

func ready():
	pass

func _process(_delta):
	pass

func _input(event):		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:	
			if event.pressed:			 
				var mouse_position = get_global_mouse_position()
				mouse_position.y += 8
				if mouse_position != _point2:
					var tile_pos = Map.local_to_map(mouse_position)
					var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2
					point1 = tile_center_pos
							
		if event.button_index == MOUSE_BUTTON_RIGHT:	
			if event.pressed:		 
				var mouse_position = get_global_mouse_position()
				mouse_position.y += 8
				if mouse_position != _point2:
					var tile_pos = Map.local_to_map(mouse_position)
					var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2
					_point2 = mouse_position
					$"../AudioStreamPlayer2D".stream = $"../AudioStreamPlayer2D".map_sfx[0]
					$"../AudioStreamPlayer2D".play()						
					await _cubic_bezier(line_2d, point1, Vector2(0, -250), Vector2(0, -250), _point2, 1)

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			for i in 1:
				var coord_A = get_node("/root/Node2D").structures[rng.randi_range(0, get_node("/root/Node2D").structures.size()-1)].coord
				var coord_B = get_node("/root/Node2D").structures[rng.randi_range(0, get_node("/root/Node2D").structures.size()-1)].coord
				var tile_pos = Map.map_to_local(coord_A) + Vector2(0,0) / 2					
				var tile_pos2 = Map.map_to_local(coord_B) + Vector2(0,0) / 2	
				$"../AudioStreamPlayer2D".stream = $"../AudioStreamPlayer2D".map_sfx[0]
				$"../AudioStreamPlayer2D".play()						
				_cubic_bezier(line_2d, tile_pos, Vector2(0, -250), Vector2(0, -250), tile_pos2, 1)	
				#var dup = self.duplicate()
				#self.get_parent().add_child(dup)							
								
func _cubic_bezier(line_2d: Line2D, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float):
	var line_inst = line2D.instantiate()
	add_child(line_inst)
					
	var curve := Curve2D.new()
	curve.add_point(p0, Vector2.ZERO, p1)
	curve.add_point(p3, p2, Vector2.ZERO)
	points = curve.get_baked_points()
	for i in points.size():
		line_inst.add_point(points[i])
		await get_tree().create_timer(0).timeout

	line_2d.clear_points()	
	var point_position = Map.local_to_map(points[points.size()-1])
	var point_pos = Map.map_to_local(point_position) + Vector2(0,0) / 2
	for i in get_node("/root/Node2D").structures.size():
		if point_position == get_node("/root/Node2D").structures[i].coord:
			var tween: Tween = create_tween()
			#tween.tween_property(get_node("/root/Node2D").structures[i], "modulate:v", 1, 0.1).from(5)	
			get_node("/root/Node2D").structures[i].get_child(0).play("demolished")	
			
			var explosion_instance = explosion.instantiate()
			get_parent().add_child(explosion_instance)
			var explosion_pos = Map.map_to_local(get_node("/root/Node2D").structures[i].coord) + Vector2(0,0) / 2
			explosion_instance.position = explosion_pos
			explosion_instance.z_index = (point_pos.x + point_pos.y) + 4
				
			$"../AudioStreamPlayer2D".stream = $"../AudioStreamPlayer2D".map_sfx[1]
			$"../AudioStreamPlayer2D".play()	
				
	for i in 4:
		line_inst.set_antialiased(false)
		line_inst.set_width(1)	
		line_inst.set_default_color(Color.WHITE_SMOKE)	
		await get_tree().create_timer(0.05).timeout
		line_inst.set_width(4)
		line_inst.set_default_color(Color.GRAY)
		await get_tree().create_timer(0.05).timeout
	
	line_inst.hide()
			
	await get_tree().create_timer(0.3).timeout		
