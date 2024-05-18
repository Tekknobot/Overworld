extends Camera2D

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
