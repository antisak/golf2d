extends Node2D



var arrowDist = 25


# Called when the node enters the scene tree for the first time.
func _ready():
	$Arrow.position = arrowDist * Vector2.UP
	$Crosshair.position = arrowDist * Vector2.UP
	
	
func get_direction():
	if $Crosshair.visible:
		return $Crosshair.position.normalized()
	else:
		return $Arrow.position.normalized()
		
		
func rotate_crosshair(angle):
	$Crosshair.position = $Crosshair.position.rotated(angle)
	
	
func rotate_arrow(angle):
	$Arrow.position = $Arrow.position.rotated(angle)
	$Arrow.rotate(angle)
	


func show_crosshair():
	$Crosshair.show()
	$Arrow.hide()
	
	
func show_arrow():
	$Arrow.show()
	$Crosshair.hide()
	
	
func hide_markers():
	$Arrow.hide()
	$Crosshair.hide()
