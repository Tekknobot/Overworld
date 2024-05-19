extends Node2D

@export var Map: TileMap
@export var line_2d: Line2D

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

func ready():
	pass

func _process(_delta):
	var mouse_position = get_global_mouse_position()
	if mouse_position != _point2 and trajectory_set == true and trajectory_end == true:
		_point2 = mouse_position
		_cubic_bezier(line_2d, point1, Vector2(0,-400), Vector2(0,-400), _point2, 1)
		trajectory_set = false
		trajectory_end = false
		
func _input(event):		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:	
			if event.pressed:			 
				var mouse_position = get_global_mouse_position()
				if mouse_position != _point2:
					var tile_pos = Map.local_to_map(mouse_position)
					var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2
					point1 = tile_center_pos
					trajectory_set = true
							
		if event.button_index == MOUSE_BUTTON_LEFT:	
			if event.pressed:			 
				var mouse_position = get_global_mouse_position()
				if mouse_position != _point2:
					var tile_pos = Map.local_to_map(mouse_position)
					var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2
					_point2 = mouse_position
					_cubic_bezier(line_2d, point1, Vector2(0,-400), Vector2(0,-400), _point2, 1)
					trajectory_end = true	
						
func _cubic_bezier(line: Line2D, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float):
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var q2 = p2.lerp(p3, t)

	var r0 = q0.lerp(q1, t)
	var r1 = q1.lerp(q2, t)

	var s = r0.lerp(r1, t)
		
	line.set_joint_mode(2)
	var curve := Curve2D.new()
	curve.add_point(p0, Vector2.ZERO, p1)
	curve.add_point(p3, p2, Vector2.ZERO)
	line.points = curve.get_baked_points()	
	
	return s
