extends Camera2D

class_name MainCamera

var _previousPosition: Vector2 = Vector2(0, 0);
var _moveCamera: bool = false;

var zoomTarget:float = 1

func _input(event):
	if event.is_action("zoom_out"):
			# *(.2 * zoomTarget) to have the step between zoom in/out stable
			# clamp alias min/max is to not flip the zoom and limit how many you can zoom
			# get_axis to support mouse/key/joystick 
		self.zoomTarget = 1
		pass
	pass
	
	if event.is_action("zoom_in"):
		self.zoomTarget = 2
		pass
	pass
		
func _process(delta):
	_zoom(delta)
	pass

func _zoom(delta):
	if zoom.x != zoomTarget:
			# lerp is to smooth the zoom and delta is to stabilize the lerp between fps
		var zoomTmp = lerp(zoom.x, zoomTarget, 10 * delta)
		zoom = Vector2(zoomTmp,zoomTmp)
		pass
	pass

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if event.is_pressed():
			_previousPosition = event.position
			_moveCamera = true;
		else:	
			_moveCamera = false;
	elif event is InputEventMouseMotion && _moveCamera:
		get_viewport().set_input_as_handled()
		position += (_previousPosition - event.position);
		_previousPosition = event.position;
	
	pass
