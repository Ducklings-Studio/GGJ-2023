extends Node

var num_players = 4
var bus = "master"
var available = []  # available players.
var music
var queue = []  # sounds to play.
var music_vol
var audio_vol

func _ready():
	music_vol = 0
	audio_vol = 0
	music = AudioStreamPlayer.new()
	add_child(music)
	music.bus = bus
	set_music("res://Assets/Audio/MainBg.ogg")
	for i in num_players:
		var p = AudioStreamPlayer.new()
		add_child(p)
		available.append(p)
		p.connect("finished", self, "_on_stream_finished", [p])
		p.bus = bus


func set_music(path):
	music.stream = load(path)
	music.set_volume_db(music_vol)
	music.play()


func _on_stream_finished(stream):
	available.append(stream)


func play(sound_path):
	queue.append(sound_path)


func set_volume():
	music.set_volume_db(music_vol)
	music.stream_paused = music_vol == -30
	if audio_vol == -30:
		queue.clear()
	for i in available.size():
		available[i].set_volume_db(audio_vol)


func _process(_delta):
	if not queue.empty() and not available.empty() && audio_vol > -30:
		available[0].stream = load(queue.pop_front())
		available[0].set_volume_db(audio_vol)
		available[0].play()
		if music_vol > -5:
			music.set_volume_db(-5)
		available.pop_front()
	elif available.size() == num_players:
		music.set_volume_db(music_vol)
