extends ColorRect

signal hit(swingPow, swingAcc)
signal swingStart

enum Phase {IDLE, BACKSWING, DOWNSWING, FOLLOW}
var swingPhase = Phase.IDLE
var swingSpeed = 4
var swingPow = 0
var swingAcc = 0
var barDir = -1


func _ready():
	reset_swing()

func _input(event):
	if event.is_action_pressed("swing"):
		if swingPhase == Phase.IDLE:
			emit_signal("swingStart")
		elif swingPhase == Phase.BACKSWING:
			swingPow = max(100 * (1 - $MoveBar.rect_position.x / $SweetSpot.rect_position.x), 0)
			$MoveBarMarker.rect_position.x = $MoveBar.rect_position.x
			$MoveBarMarker.show()
		elif swingPhase == Phase.DOWNSWING:
			if $MoveBar.rect_position.x < $SweetSpot.rect_position.x:
				swingAcc = $MoveBar.rect_position.x - $SweetSpot.rect_position.x
			elif $MoveBar.rect_position.x + $MoveBar.rect_size.x > $SweetSpot.rect_position.x + $SweetSpot.rect_size.x:
				swingAcc = $MoveBar.rect_position.x + $MoveBar.rect_size.x - $SweetSpot.rect_position.x - $SweetSpot.rect_size.x
			else:
				swingAcc = 0
			
			emit_signal("hit", swingPow, swingAcc)
		elif swingPhase == Phase.FOLLOW:
			return
			
		swingPhase += 1


func _process(_delta):
	if swingPhase == Phase.FOLLOW:
		return
		
	if $MoveBar.rect_position.x + $MoveBar.rect_size.x >= rect_size.x:
		emit_signal("hit", 0, 0)
		swingPhase = Phase.FOLLOW
		
	if swingPhase == Phase.BACKSWING:
		if $MoveBar.rect_position.x <= 0:
			barDir = 1
		$MoveBar.rect_position.x += barDir * swingSpeed
	elif swingPhase == Phase.DOWNSWING:
		$MoveBar.rect_position.x += swingSpeed


func reset_swing():
	swingPhase = Phase.IDLE
	barDir = -1
	
	$MoveBar.rect_position.x = $SweetSpot.rect_position.x + $SweetSpot.rect_size.x / 2
	$MoveBarMarker.hide()
	
	
func set_club(club):
	$Club.text = club
	
	
func set_terrain(terrain):
	$Terrain.text = terrain
