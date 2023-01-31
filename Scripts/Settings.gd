extends Control

const MUSIC_VOLUME_STEP = 1; # dB by one value on slider
const MUSIC_VOLUME_BASIC = 5;

const INTERFACE_VOLUME_STEP = 1; # dB by one value on slider
const INTERFACE_VOLUME_BASIC = 5;

var musicValueTemp = MUSIC_VOLUME_BASIC / MUSIC_VOLUME_STEP ;
var interfaceValueTemp = INTERFACE_VOLUME_BASIC / INTERFACE_VOLUME_STEP;

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
