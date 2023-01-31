extends Node2D

var is_blocking = true

var XError = 1
var YError = -7
var FieldErrorX = 512
var FieldErrorY = 300
var width = 32
var height = 16

var greenMushroom = preload("res://Scenes/Mushrooms/Green.tscn")

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			spawn_mushroom(event.position.x-FieldErrorX, event.position.y-FieldErrorY)

func spawn_mushroom(x, y):
	var mushroom = greenMushroom.instance()
	mushroom.position = Vector2(XError+floor(x/width+0.5)*width, YError+floor(y/height+0.5)*height)
	print(floor(x/width+0.5), " ", floor(y/height+0.5))
	print(floor(x/width+0.5)*width, " ", floor(y/height+0.5)*height)
	add_child(mushroom)
	
