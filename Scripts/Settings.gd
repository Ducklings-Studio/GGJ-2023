extends Control

const MUSIC_VOLUME_STEP = 1; # dB by one value on slider
const MUSIC_VOLUME_BASIC = 5;

const INTERFACE_VOLUME_STEP = 1; # dB by one value on slider
const INTERFACE_VOLUME_BASIC = 5;

onready var MusicSlider = $MarginContainer/Control/VBoxContainer/Control2/MusicSlider
onready var AudiSlider = $MarginContainer/Control/VBoxContainer/Control/AudiSlider
onready var musicValueTemp = MusicSlider.value;
onready var interfaceValueTemp = AudiSlider.value;

func _ready():
	var MusicTemp = AudioManager.music_vol;
	var AudioTemp = AudioManager.audio_vol;
	MusicSlider.value = MusicSlider.max_value - (AudioManager.music_vol / MUSIC_VOLUME_STEP + MUSIC_VOLUME_BASIC);
	AudiSlider.value = AudiSlider.max_value - (AudioManager.audio_vol / INTERFACE_VOLUME_STEP + INTERFACE_VOLUME_BASIC);
	AudioManager.music_vol = MusicTemp;
	AudioManager.audio_vol = AudioTemp;
	AudioManager.set_volume()

func _on_Back_pressed():
	self.set_visible(false)

func _on_AudiSlider_value_changed(value):
	var diff =  interfaceValueTemp - value;
	AudioManager.audio_vol += INTERFACE_VOLUME_STEP * diff;
	interfaceValueTemp = value;
	AudioManager.set_volume()
	print(AudioManager.audio_vol)

func _on_MusicSlider_value_changed(value):
	var diff =  musicValueTemp - value;
	AudioManager.music_vol += MUSIC_VOLUME_STEP * diff;
	musicValueTemp = value;
	AudioManager.set_volume()

	
