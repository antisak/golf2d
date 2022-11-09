extends Node


var maxHeight = 0
var maxDist = 0
var currentDist = 0
var currentHeight = 0
var frameSpeed = 0
var velocity
var swingAcc = 0
var direction = Vector2.UP
var sliceDir = Vector2(0, 0)
var strokes = 0
var score = 0
var holeNumber = 1
export var wind = Vector2(0, 0)
var startPos = Vector2(560, 520)
#var startPos = Vector2(600, 155)
var par = 4
var clubsDist = {"1W":251, "3W":222, "5W":210, "3I":194,
				"4I":186, "5I":177, "6I":167, "7I":157,
				"8I":146, "9I":135, "PW":124, "PT":500}
var clubs = ["1W", "3W", "5W", "3I", "4I", "5I", "6I", "7I", "8I", "9I", "PW", "PT"]
var terrainEffect = {"Fairway":1.0, "Green":1.0, "Rough":0.8, "Sand":0.5, "Hole":1.0}
var terrainRoll = {"Fairway":2.0, "Green":1.0, "Rough":4.0, "Sand":8.0, "OB":8.0, "Hole":1.0}
var holeInfo = {"path": "res://art/test_level2.png", "greenpath": "res://art/test_green.png",
				"par": 4, "greenpos": Vector2(566, 128), "greensize": Vector2(110, 52),
				"holepos": Vector2(641, 155), "startpos": Vector2(641, 155)}
var currentClub = 0
var startTerrain = ""
var screen_size
var levelImg
var hole1 = "res://art/test_level2.png"
var green1 = "res://art/test_green.png"
var holePos = Vector2(641, 155)
var greenPos = Vector2(566, 128)
var greenSize = Vector2(110, 52)
var greenScale
var greenZoom
enum State {IDLE, FLYING, ROLLING, PUTTING, WAITING}
var state = State.IDLE


func _ready():
	$Level.texture = load(hole1)
	$InfoBars.set_wind(wind)
	$HoleMarker.position = holePos
	$Hole.position = holePos
	greenScale = $Level.texture.get_width() / greenSize.x
	greenZoom = Vector2.ONE / greenScale
	screen_size = get_viewport().size
	levelImg = $Level.texture.get_data()
	levelImg.lock()
	startTerrain = get_terrain(startPos)
	next_turn()


func _input(event):
	if state == State.WAITING:
		return
	if event.is_action_pressed("rotate_left"):
		if clubs[currentClub] == "PT":
			var angle = -PI / 16
			$Ball.rotate_crosshair(angle)
			direction = $Ball.get_direction()
		else:
			var angle = -PI / 8
			$Ball.rotate_arrow(angle)
			direction = $Ball.get_direction()
	elif event.is_action_pressed("rotate_right"):
		if clubs[currentClub] == "PT":
			var angle = PI / 16
			$Ball.rotate_crosshair(angle)
			direction = $Ball.get_direction()
		else:
			var angle = PI / 8
			$Ball.rotate_arrow(angle)
			direction = $Ball.get_direction()
	elif event.is_action_pressed("next_club"):
		change_club(currentClub + 1)
	elif event.is_action_pressed("prev_club"):
		change_club(currentClub - 1)


func _process(delta):
	#if Input.is_action_pressed("rotate_left"):
	if state == State.FLYING:
		if out_of_screen():
			state = State.WAITING
			turn_over("OB")
			return
		
		velocity += (currentHeight / 50) * wind / 50 + currentDist * sliceDir / 150
		direction = velocity.normalized()
		var dist = 0.5 * frameSpeed * delta
		var actualDist = 0.5 * velocity.length() * delta
		
		if currentDist + dist >= maxDist:
			dist = maxDist - currentDist
			state = State.WAITING
		
		currentDist += dist
		currentHeight = calc_height()
		$Ball.position += actualDist * direction
		$Ball/Sprite.position = Vector2(0, -currentHeight)
		$Ball/Sprite.scale = Vector2(0.2, 0.2) * (1 + currentHeight / 50)
		
		if state == State.WAITING:
			print(maxDist)
			print($Ball.position.x - startPos.x)
			print($Ball.position.y - startPos.y)
			var terrain = get_terrain($Ball.position)
			if terrain == "Water":
				turn_over("Water")
			elif terrain == "Sand":
				turn_over("Sand")
			else:
				state = State.ROLLING
	elif state == State.ROLLING:
		if out_of_screen():
			state = State.WAITING
			turn_over("OB")
			return
		
		var dist = 0.5 * velocity.length() * delta
		$Ball.position += dist * direction
		var terrain = get_terrain($Ball.position)
		if terrain == "Water":
			state = State.WAITING
			turn_over("Water")
			return
		var velEffect = terrainRoll[terrain] * 250 / maxDist
		velocity -= velEffect * direction
		if velocity.length() <= velEffect:
			state = State.WAITING
			
		if state == State.WAITING:
			turn_over(terrain)
	elif state == State.PUTTING:
		var dist = 0.5 * velocity.length() * delta
		$Ball.position += dist * direction
		if out_of_green():
			zoom_to_full()
			state = State.ROLLING
			velocity *= 0.1
			return
		if $Ball.position.distance_to($Hole.position) < 8 / greenScale && velocity.length() < 150 / greenScale:
			state = State.WAITING
			$Ball.hide()
			turn_over("Hole")
			return
		var terrain = get_terrain($Ball.position)
		var velEffect = terrainRoll[terrain]
		velocity -= (velEffect / greenScale) * direction
		if velocity.length() <= velEffect / greenScale:
			state = State.WAITING
		
		if state == State.WAITING:
			turn_over(terrain)


func out_of_green():
	var x = $Ball.position.x
	var y = $Ball.position.y
	return x < greenPos.x || x > greenPos.x + greenSize.x || y < greenPos.y || y > greenPos.y + greenSize.y


func out_of_screen():
	var x = $Ball.position.x
	var y = $Ball.position.y
	return x < 256 || y < 0 || x > screen_size.x || y > $Level.texture.get_height()


func get_terrain(pos):
	var pix = levelImg.get_pixelv(pos - Vector2(256, 0))
	
	if pix.r8 == 57 && pix.g8 == 235 && pix.b8 == 102:
		return "Fairway"
	if pix.r8 == 16 && pix.g8 == 66 && pix.b8 == 29:
		return "Fairway"
	elif pix.r8 == 36 && pix.g8 == 148 && pix.b8 == 64:
		return "Rough"
	elif pix.r8 == 26 && pix.g8 == 107 && pix.b8 == 46:
		return "Green"
	elif pix.r8 == 66 && pix.g8 == 197 && pix.b8 == 255:
		return "Water"
	elif pix.r8 == 255 && pix.g8 == 196 && pix.b8 == 57:
		return "Sand"
	return "OB"


func turn_over(terrain):
	var msg = "Miss!"
	if terrain == "OB":
		strokes += 1
		msg = "OB"
	elif terrain == "Water":
		strokes += 1
		msg = "Nice day for a swim"
	elif terrain == "Sand":
		startPos = $Ball.position
		startTerrain = terrain
		msg = "Unlucky"
	elif terrain == "Fairway":
		startPos = $Ball.position
		startTerrain = terrain
		msg = "Nice shot!"
	elif terrain == "Rough":
		startPos = $Ball.position
		startTerrain = terrain
		msg = "Could be worse..."
	elif terrain == "Green":
		startPos = $Ball.position
		startTerrain = terrain
		msg = "Good"
	elif terrain == "Hole":
		score += strokes - par
		msg = score_msg(strokes - par)
		$InfoBars.set_message(msg)
		$NextLevelTimer.start()
		return
	$InfoBars.set_message(msg)
	$AfterTurnTimer.start()


func next_turn():
	state = State.IDLE
	$Ball.position = startPos
	
	if startTerrain == "Green":
		zoom_to_green()
		change_club(-1)
	else:
		zoom_to_full()
		change_club(currentClub)
		
	direction = $Ball.get_direction()
	
	$InfoBars.set_message("Go ahead")
	$InfoBars.set_strokes(strokes)
	$InfoBars.set_terrain(startTerrain)
	$InfoBars.reset_swing()
	
	
func next_level():
	$Level.show()
	$HoleMarker.show()
	$Ball.show()
	$Hole.hide()
	holeNumber += 1
	strokes = 0
	currentClub = 0
	holePos = Vector2(641, 155)
	greenPos = Vector2(566, 128)
	greenSize = Vector2(110, 52)
	wind = Vector2(0, 0)
	startPos = Vector2(560, 520)
	par = 4
	$Level.texture = load(hole1)
	$InfoBars.set_wind(wind)
	$InfoBars.set_score(score)
	$InfoBars.set_holeinfo(holeNumber, par)
	$HoleMarker.position = holePos
	$Hole.position = holePos
	greenScale = $Level.texture.get_width() / greenSize.x
	greenZoom = Vector2.ONE / greenScale
	levelImg = $Level.texture.get_data()
	levelImg.lock()
	startTerrain = get_terrain(startPos)
	next_turn()
	
	
func scale_to_green(pos):
	return (pos - greenPos) * greenScale + Vector2(256, 0)
	
	
func scale_to_all(pos):
	return (pos - Vector2(256, 0)) / greenScale + greenPos
	
	
func change_club(club):
	currentClub = club
	if currentClub >= clubs.size():
		currentClub = 0
	elif currentClub < 0:
		currentClub = clubs.size() - 1
		
	$InfoBars.set_club(clubs[currentClub])
	if clubs[currentClub] == "PT":
		$Ball.show_crosshair()
	else:
		$Ball.show_arrow()
	
	
func game_over():
	$InfoBars.set_message("Game over! Final score: " + str(score))


func score_msg(sc):
	if sc == 0:
		return "Par"
	elif sc == -1:
		return "Birdie"
	elif sc == -2:
		return "Eagle"
	elif sc == -3:
		return "Albatross"
	elif sc == 1:
		return "Bogey"
	elif sc == 2:
		return "Double Bogey"
	elif sc == 3:
		return "Triple Bogey"
	elif sc < 3:
		return "Hacker!"
	return "+" + str(sc)

	
func calc_height():
	if maxDist == 0:
		return 0
	var x1 = 0
	var x2 = maxDist
	var currentPos = currentDist
	var a = -4 * maxHeight / pow(x1 - x2, 2)
	var b = 4 * maxHeight * (x1 * x1 - x2 * x2) / pow(x1 - x2, 3)
	var c = -a * x1 * x1 - b * x1
	return a * currentPos * currentPos + b * currentPos + c


func zoom_to_green():
	$Camera.set_zoom(greenZoom)
	$Camera.set_offset(greenPos)
	$HoleMarker.hide()
	$Hole.show()
	$Hole.scale = greenZoom
	$Ball.scale = greenZoom
	

func zoom_to_full():
	$Camera.set_zoom(Vector2.ONE)
	$Camera.set_offset(Vector2.ZERO)
	$HoleMarker.show()
	$Hole.hide()
	$Ball.scale = Vector2.ONE


func _on_InfoBars_swingStart():
	state = State.WAITING


func _on_InfoBars_hit(power, acc):
	print("power: " + str(power))
	print("acc: " + str(acc))
	$Ball.hide_markers()
	strokes += 1
	$InfoBars.set_strokes(strokes)
	
	if power < 10:
		turn_over("")
		return
	
	swingAcc = clamp(acc, -30, 30)
	frameSpeed = 100
	sliceDir = (swingAcc / 30) * direction.tangent()
	direction = (direction - sliceDir / 4).normalized()
	velocity = frameSpeed * direction
	maxDist = clubsDist[clubs[currentClub]] * power / 100 * terrainEffect[startTerrain]
	maxHeight = power / 2
	currentDist = 0
	
	if clubs[currentClub] == "PT":
		if startTerrain == "Green":
			velocity *= 4 * power / 100 / greenScale
			state = State.PUTTING
		else:
			state = State.ROLLING
		return
	
	if startTerrain == "Green":
		zoom_to_full()
	
	state = State.FLYING
