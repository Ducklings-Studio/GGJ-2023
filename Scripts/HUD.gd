extends CanvasLayer

var start_timer = Timer.new()
var iterator = 0

const audios = [
	"res://Assets/Audio/Effects/CountSimple.wav",
	"res://Assets/Audio/Effects/CountSimple.wav",
	"res://Assets/Audio/Effects/CountSimple.wav",
	"res://Assets/Audio/Effects/CountSimple.wav",
	"res://Assets/Audio/Effects/CountFinal.wav"
]

const labels = [
	"5",
	"4",
	"3",
	"2",
	"1",
	"Start!",
]


func _ready():
	AudioManager.play("res://Assets/Audio/Effects/prepare_yourself.ogg")
	start_timer.connect("timeout", self, "count")
	start_timer.wait_time = 1
	add_child(start_timer)
	start_timer.start()
	$"..".is_blocking = true


func count():
	AudioManager.play(audios[iterator])
	show_label(labels[iterator], 0.9)
	iterator += 1
	if iterator >= len(audios):
		start_timer.stop()
		remove_child(start_timer)
		$"..".is_blocking = false


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
