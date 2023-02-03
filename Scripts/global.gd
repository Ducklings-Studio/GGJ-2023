extends Node

var endgame_parametrs := {
	"EndGameText": "",
	"MatchTimer": "",
	"Mushrooms": 0,
	"MushroomsLost": 0,
	"MineralsMine": 0,
	"MineralsSpend": 0
}

func set_endgame_parameter(new_endgame_parameter):
	endgame_parametrs = new_endgame_parameter;

func get_endgame_parametr():
	return endgame_parametrs;


func upload_buttons():
	var buttons: Array = get_tree().get_nodes_in_group("ui_buttons")
	for i in buttons:
		i.connect("mouse_entered", self, "play_button")
		i.connect("pressed", self, "play_button_click")

	var sliders: Array = get_tree().get_nodes_in_group("ui_sliders")
	for i in sliders:
		i.connect("value_changed", self, "play_slider")


func play_button_click():
	AudioManager.play("res://Assets/Audio/Effects/MenuButtonHover.wav")


func play_button():
	AudioManager.play("res://Assets/Audio/Effects/MenuButtonClick.wav")


func play_slider(_tmp):
	AudioManager.play("res://Assets/Audio/Effects/SliderSound.wav")
