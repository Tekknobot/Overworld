extends Node2D

@export var Map: TileMap
@export var line_2d: Line2D

var line2D = preload("res://assets/scenes/prefab/line_2d.scn")

var point1 : Vector2
#@export var point2 : Vector2 = Vector2(0, 0)
@export_range(1, 1000) var segments : int = 100
@export var width : int = 10
@export var color : Color = Color.GREEN
@export var antialiasing : bool = false

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
		if event.button_index == MOUSE_BUTTON_RIGHT:	
			if event.pressed:			 
				var mouse_position = get_global_mouse_position()
				if mouse_position != _point2:
					var tile_pos = Map.local_to_map(mouse_position)
					var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2
					point1 = tile_center_pos
							
		if event.button_index == MOUSE_BUTTON_LEFT:	
			if event.pressed:		 
				var mouse_position = get_global_mouse_position()
				if mouse_position != _point2:
					var tile_pos = Map.local_to_map(mouse_position)
					var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2
					_point2 = mouse_position
					_cubic_bezier(line_2d, point1, Vector2(0, -250), Vector2(0, -250), _point2, 1)
						
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
