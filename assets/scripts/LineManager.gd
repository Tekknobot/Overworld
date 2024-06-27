extends Node2D

@export var Map: TileMap
@export var line_2d: Line2D
@onready var laserstream = $"../LaserStream"

var line2D = preload("res://assets/scenes/prefab/line_2d.scn")
var explosion = preload("res://assets/scenes/vfx/explosion.scn")

var point1 := Vector2(0, -700)
var point2 := Vector2(-1300, 300)
var point3 := Vector2(1300, 300)
var point4 := Vector2(0, 1700)

var _point2 : Vector2

var _the_point: Vector2

var grid_width = 32
var grid_height = 32

var rng = RandomNumberGenerator.new()
var trajectory_set = false
var trajectory_end = false

var points = []
var onTrajectory = false
static var target
var cpu_traj
var missed = false

var right_click_position

func ready():
	pass
				
func _process(_delta):
	pass

func _input(event):		
	if event is InputEventMouseButton:		
		if event.button_index == MOUSE_BUTTON_RIGHT and onTrajectory == false:	
			if event.pressed:	
				right_click_position = get_global_mouse_position()	
																	
		if event.button_index == MOUSE_BUTTON_LEFT and onTrajectory == false:	
			if event.pressed:		 
				var mouse_position = get_global_mouse_position()
				mouse_position.y += 8
				var mouse_local = Map.local_to_map(mouse_position)
				for j in get_node("/root/Node2D").structures.size():
					if Map.get_cell_source_id(1, mouse_local) == 14 and mouse_local == get_node("/root/Node2D").structures[j].coord:
						var dup = self.duplicate()
						self.get_parent().add_child(dup)
						dup.add_to_group("trajectories")										
						_point2 = right_click_position		
						var coord_A = get_node("/root/Node2D").structures[rng.randi_range(0, get_node("/root/Node2D").structures.size()-1)].coord
						var coord_B = get_node("/root/Node2D").structures[rng.randi_range(0, get_node("/root/Node2D").structures.size()-1)].coord
						var tile_pos = Map.map_to_local(coord_A) + Vector2(0,0) / 2					
						var tile_pos2 = Map.map_to_local(coord_B) + Vector2(0,0) / 2									
						$"../SoundStream".stream = $"../SoundStream".map_sfx[0]
						$"../SoundStream".play()			
						await dup._cubic_bezier(line_2d, _point2, Vector2(0,-150), Vector2(0,-150), mouse_position, 1)									
						var trajects = get_tree().get_nodes_in_group("trajectories_cpu")
						for i in trajects.size():
							trajects[0].queue_free()						
						dup.queue_free()
						Map.on_cpu()	
												
func _cubic_bezier(line_2d: Line2D, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float):
	onTrajectory = true
	var line_inst = line2D.instantiate()
	add_child(line_inst)
					
	var curve := Curve2D.new()
	curve.add_point(p0, Vector2.ZERO, p1)
	curve.add_point(p3, p2, Vector2.ZERO)
	points = curve.get_baked_points()
	for i in points.size():
		line_inst.add_point(points[i])
		target = points[points.size()/2]	
		await get_tree().create_timer(0.01).timeout

	#line_2d.clear_points()	
	var point_position = Map.local_to_map(points[points.size()-1])
	var point_pos = Map.map_to_local(point_position) + Vector2(0,0) / 2

	for i in get_node("/root/Node2D").structures.size():
		if point_position == get_node("/root/Node2D").structures[i].coord:
			var tween: Tween = create_tween()
			for j in 8:
				tween.tween_property(get_node("/root/Node2D").structures[i], "modulate:v", 1, 0.1).from(5)	
			get_node("/root/Node2D").structures[i].get_child(0).play("demolished")	
			get_node("/root/Node2D").structures[i].modulate = Color.WHITE
			
			var explosion_instance = explosion.instantiate()
			get_parent().add_child(explosion_instance)
			var explosion_pos = Map.map_to_local(get_node("/root/Node2D").structures[i].coord) + Vector2(0,0) / 2
			explosion_instance.position = explosion_pos
			explosion_instance.z_index = point_pos.x + point_pos.y
				
			laserstream.stream = laserstream.map_sfx[1]
			laserstream.play()	
				
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
	onTrajectory = false
						
func _intercept_bezier(line_2d: Line2D, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float):
	onTrajectory = true
	var line_inst = line2D.instantiate()
	add_child(line_inst)
					
	var curve := Curve2D.new()
	curve.add_point(p0, Vector2.ZERO, p1)
	curve.add_point(p3, p2, Vector2.ZERO)
	points = curve.get_baked_points()
	for i in points.size():
		line_inst.add_point(points[i])
		await get_tree().create_timer(0).timeout

	#line_2d.clear_points()	
	#var point_position = Map.local_to_map(points[points.size()-1])
	#var point_pos = Map.map_to_local(point_position) + Vector2(0,0) / 2
	#for i in get_node("/root/Node2D").structures.size():
		#if point_position == get_node("/root/Node2D").structures[i].coord:
			#var tween: Tween = create_tween()
			#for j in 8:
				#tween.tween_property(get_node("/root/Node2D").structures[i], "modulate:v", 1, 0.1).from(5)	
			#get_node("/root/Node2D").structures[i].get_child(0).play("demolished")
			#get_node("/root/Node2D").structures[i].modulate = Color.WHITE
			#
			#var explosion_instance = explosion.instantiate()
			#get_parent().add_child(explosion_instance)
			#var explosion_pos = Map.map_to_local(get_node("/root/Node2D").structures[i].coord) + Vector2(0,0) / 2
			#explosion_instance.position = explosion_pos
			#explosion_instance.z_index = (point_pos.x + point_pos.y) + 4
				#
			#$"../AudioStreamPlayer2D".stream = $"../AudioStreamPlayer2D".map_sfx[1]
			#$"../AudioStreamPlayer2D".play()	
				
	for i in 2:
		line_inst.set_antialiased(false)
		line_inst.set_width(1)	
		line_inst.set_default_color(Color.WHITE_SMOKE)	
		await get_tree().create_timer(0.05).timeout
		line_inst.set_width(4)
		line_inst.set_default_color(Color.GRAY)
		await get_tree().create_timer(0.05).timeout
	
	line_inst.hide()
							
	await get_tree().create_timer(0.3).timeout
	onTrajectory = false			

