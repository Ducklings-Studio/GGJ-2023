extends Node2D

var WaitingTimer = Timer.new();

var is_blocking = true

var XError = 1
var YError = -7
var FieldErrorX = 512
var FieldErrorY = 300
var width = 32
var height = 16

var greenMushroom = preload("res://Scenes/Mushrooms/Green.tscn")

func _ready():
	AudioManager.set_music("res://Assets/Audio/MatchSound.ogg")


func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			spawn_mushroom(event.position.x-FieldErrorX, event.position.y-FieldErrorY)

func spawn_mushroom(x, y):
	var mushroom = greenMushroom.instance()
	var positionX = floor(x/width+0.5)
	var positionY = floor(y/height+0.5)
	mushroom.position = Vector2(XError+positionX*width/2, YError+positionY*height/2)
	add_child(mushroom)
	