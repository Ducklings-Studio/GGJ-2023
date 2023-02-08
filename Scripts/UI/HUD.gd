extends CanvasLayer

var start_timer = Timer.new()
var iterator = 0

signal game_started

const audios = [
	"res://Assets/Audio/Effects/CountSimple.wav",
	"res://Assets/Audio/Effects/CountSimple.wav",
	"res://Assets/Audio/Effects/CountSimple.wav",
	"res://Assets/Audio/Effects/CountSimple.wav",
	"res://Assets/Audio/Effects/CountFinal.wav",
	"res://Assets/Audio/Effects/Fight.wav"
]
const labels = [
	"5",
	"4",
	"3",
	"2",
	"1",
	"Start!",
]

onready var game = $"../Camera2D"
onready var error_msg = $Error


func _ready():
	assert (len(labels) == len(audios))

	game.connect("error", self, "error")
	Global.upload_buttons()

	AudioManager.play("res://Assets/Audio/Effects/PrepareYourself.wav")
	start_timer.connect("timeout", self, "count")
	start_timer.wait_time = 1
	add_child(start_timer)
	start_timer.start()


func error(id: int):
	error_msg.set_text(Global.errors[id])
	error_msg.set_visible(true)
	var timer = Timer.new()
	timer.wait_time = 1
	timer.connect("timeout", self, "clean_error", [timer])
	add_child(timer)
	timer.start()



func count():
	AudioManager.play(audios[iterator])
	show_label(labels[iterator], 0.9)
	iterator += 1
	if iterator >= len(audios):
		start_timer.stop()
		remove_child(start_timer)
		emit_signal("game_started")


func show_label(text, duration):
	$Label.set_text(text)
	$Label.set_visible(true)

	var timer = Timer.new()
	timer.connect("timeout", self, "clean_label", [timer])
	timer.wait_time = duration
	add_child(timer)
	timer.start()


func clean_label(timer: Timer):
	timer.stop()
	remove_child(timer)
	$Label.set_visible(false)


func set_gems(amount):
	$Resources/MarginContainer/HBoxContainer/Amount.set_text(str(amount))


func show_options(arr):
	var kar = $Options/MarginContainer/GridContainer.get_children()
	for i in kar:
		i.set_visible(false)
	for i in arr:
		kar[i].set_visible(true)


func _on_Action_pressed(action_id):
	game.process_action(action_id)


func Get_Time():
	var time = $Time.Get_Time()
	var minutes = time / 60
	var seconds = time % 60
	return "%02d:%02d" % [minutes, seconds]


func clean_error(timer: Timer):
	timer.stop()
	remove_child(timer)
	error_msg.set_visible(false)
