extends Control

const MUSIC_VOLUME_STEP = 1 # dB by one value on slider
const MUSIC_VOLUME_BASIC = 5

const INTERFACE_VOLUME_STEP = 1 # dB by one value on slider
const INTERFACE_VOLUME_BASIC = 5

const CONTROLS_PATH = "MarginContainer/Control/TabContainer/Control/Scroll/VBox/"

onready var MusicSlider = $MarginContainer/Control/TabContainer/Audio/Control2/MusicSlider
onready var AudiSlider = $MarginContainer/Control/TabContainer/Audio/Control/AudiSlider
onready var musicValueTemp = MusicSlider.value
onready var interfaceValueTemp = AudiSlider.value

onready var locales = $MarginContainer/Control/TabContainer/Other/Scroll/VBox/Lang/Option

var can_change_key = false
var action_string


func _ready():
	var MusicTemp = AudioManager.music_vol;
	var AudioTemp = AudioManager.audio_vol;
	MusicSlider.value = MusicSlider.max_value - (AudioManager.music_vol / MUSIC_VOLUME_STEP + MUSIC_VOLUME_BASIC);
	AudiSlider.value = AudiSlider.max_value - (AudioManager.audio_vol / INTERFACE_VOLUME_STEP + INTERFACE_VOLUME_BASIC);
	AudioManager.music_vol = MusicTemp;
	AudioManager.audio_vol = AudioTemp;
	AudioManager.set_volume()
	
	_set_keys() 
	_set_locales()


func _input(event):
	if event is InputEventKey: 
		if can_change_key:
			_change_key(event)
			can_change_key = false


func _on_Back_pressed():
	self.set_visible(false)


func _on_AudiSlider_value_changed(value):
	var diff =  interfaceValueTemp - value;
	AudioManager.audio_vol += INTERFACE_VOLUME_STEP * diff;
	interfaceValueTemp = value;
	AudioManager.set_volume()


func _on_MusicSlider_value_changed(value):
	var diff =  musicValueTemp - value;
	AudioManager.music_vol += MUSIC_VOLUME_STEP * diff;
	musicValueTemp = value;
	AudioManager.set_volume()


func _set_keys():
	for a in Global.ACTIONS:
		var path = "%s%s%s" % [CONTROLS_PATH, str(a), "/Button"]
		get_node(path).set_pressed(false)
		if !InputMap.get_action_list(a).empty():
			get_node(path).set_text(InputMap.get_action_list(a)[0].as_text())
		else:
			get_node(path).set_text("UNKNOWN")


func _mark_button(key: String):
	can_change_key = true
	action_string = key
	
	for a in Global.ACTIONS:
		if a != key:
			var path = "%s%s%s" % [CONTROLS_PATH, str(a), "/Button"]
			get_node(path).set_pressed(false)


func _change_key(new_key):
	if !InputMap.get_action_list(action_string).empty():
		InputMap.action_erase_event(action_string, InputMap.get_action_list(action_string)[0])
	
	#for a in Global.ACTIONS:
	#	if InputMap.action_has_event(a, new_key):
	#		InputMap.action_erase_event(a, new_key)
	
	InputMap.action_add_event(action_string, new_key)
	
	_set_keys()


func _on_bind_key(key):
	_mark_button(key)


func _set_locales():
	for l in Global.Locales:
		locales.add_item(Global.from_code(l))


func _on_locale_selected(index):
	TranslationServer.set_locale(Global.Locales[index])
