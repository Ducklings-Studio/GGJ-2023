extends Node


func _ready():
	var buttons: Array = get_tree().get_nodes_in_group("ui_buttons")
	for i in buttons:
		i.connect("mouse_entered", self, "play_button")
		i.connect("pressed", self, "play_button_click")

	var sliders: Array = get_tree().get_nodes_in_group("ui_sliders")
	for i in sliders:
		i.connect("value_changed", self, "play_slider")


func play_button_click():
	print("1")
	AudioManager.play("res://Assets/Audio/Effects/MenuButton.wav")


func play_button():
	print("2")
	AudioManager.play("res://Assets/Audio/Effects/MenuButton.wav")


func play_slider(_tmp):
	print("3")
	AudioManager.play("res://Assets/Audio/Effects/MenuButton.wav")
