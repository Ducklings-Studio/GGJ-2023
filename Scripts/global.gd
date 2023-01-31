extends Node


func _ready():
	var sliders: Array = get_tree().get_nodes_in_group("ui_sliders")
	for inst in sliders:
		inst.connect("value_changed", self, "play_slider")


func play_slider(_tmp):
	AudioManager.play("res://Assets/Audio/Effects/click_004.ogg")
