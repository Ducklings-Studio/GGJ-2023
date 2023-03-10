extends Node

var endgame_parameters := {
	"ModeName": "",
	"EndGameText": "",
	"MatchTimer": "",
	"Mushrooms": 0,
	"MushroomsLost": 0,
	"MineralsMine": 0,
	"MineralsSpend": 0,
	"BgPicture": "",
	"BgAudio": ""
}
enum {
	BUILD, 
	E_ATTACK, 
	E_BOMB, 
	E_DEFENDER, 
	ATTACK, 
	EXPLODE,
}
enum ACTIONS {
	MOVE_LEFT, 
	MOVE_RIGHT, 
	MOVE_UP, 
	MOVE_DOWN,
	BUILD,
	ATTACK,
	EXPLODE,
	E_ATTACKER,
	E_DEFENDER,
	E_BOMB,
}
var classes := [
	preload("res://Scenes/Mushrooms/Base.tscn"),
	preload("res://Scenes/Mushrooms/Standart.tscn"),
	preload("res://Scenes/Mushrooms/Bomber.tscn"),
	preload("res://Scenes/Mushrooms/Defender.tscn"),
	preload("res://Scenes/Mushrooms/Attacker.tscn"),
]
var errors := [
	"",
	"K_NOT_M",
	"K_FAR",
	"K_IBD",
	"K_NOT_A",
	"K_RELOAD"
]
var I_ATTACK: Attacker = classes[4].instance()
var Locales = TranslationServer.get_loaded_locales()
var locale_chosen = Locales.find(TranslationServer.get_locale())


func set_endgame_parameter(new_endgame_parameter):
	endgame_parameters = new_endgame_parameter;


func set_endgame_mode(new_modeName):
	endgame_parameters.ModeName = new_modeName;


func get_endgame_parameter():
	return endgame_parameters;


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


func from_code(code: String):
	var name = TranslationServer.get_locale_name(code)
	if name.empty():
		return code
	return name
