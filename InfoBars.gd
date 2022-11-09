extends CanvasLayer


signal hit(swingPow, swingAcc)
signal swingStart

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_strokes(strokes):
	$StrokeCounter.text = "Shot " + str(strokes)
	
	
func set_score(score):
	$Score.text = "Score " + str(score)


func set_message(msg):
	$Message.text = msg
	
	
func set_holeinfo(hole, par):
	$HoleInfo.text = "Hole " + str(hole) + "\n" + "Par " + str(par) + "\n" + "320 m"
	
	
func set_wind(wind):
	$Wind.text = "Wind\n" + str(round(wind.length())) + " m/s"
	$Wind/WindArrow.rotation = -wind.angle_to(Vector2.UP)
	
	
func reset_swing():
	$SwingBar.reset_swing()
	
	
func set_club(club):
	$SwingBar.set_club(club)
	
	
func set_terrain(terrain):
	$SwingBar.set_terrain(terrain)


func _on_SwingBar_swingStart():
	emit_signal("swingStart")


func _on_SwingBar_hit(swingPow, swingAcc):
	emit_signal("hit", swingPow, swingAcc)
