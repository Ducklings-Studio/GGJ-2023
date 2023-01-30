extends Node2D


var timer = Timer.new()
var iterator = 0
const audios = [
	"res://Assets/Audio/Effects/5.ogg",
	"res://Assets/Audio/Effects/4.ogg",
	"res://Assets/Audio/Effects/3.ogg",
	"res://Assets/Audio/Effects/2.ogg",
	"res://Assets/Audio/Effects/1.ogg",
	"res://Assets/Audio/Effects/begin.ogg",
]

func _ready():
	timer.connect("timeout", self, "count")
	timer.wait_time = 1
	add_child(timer)
	timer.start()


func count():
	AudioManager.play(audios[iterator])
	iterator += 1
	if iterator >= len(audios):
		timer.stop()
		remove_child(timer)
