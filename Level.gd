extends Node2D


var path
var greenpath
var par
var greenpos
var greensize
var holepos
var startpos

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func init(path, greenpath, par, greenpos, greensize, holepos, startpos):
	path = path
	greenpath = greenpath
	par = par
	greenpos = greenpos
	greensize = greensize
	holepos = holepos
	startpos = startpos
