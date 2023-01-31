extends Control

const SOUND_STEP = 1; # dB by one value on slider
const SOUND_BASE = 5; # basic dB

var valueTemp =  SOUND_BASE / SOUND_STEP;

func _on_Back_pressed():
	self.set_visible(false)


func _on_AudiSlider_value_changed(value):
	AudioManager.audio_vol = -3*value
	AudioManager.set_volume()


func _on_MusicSlider_value_changed(value):
	var diff =  valueTemp - value;
	AudioManager.music_vol += SOUND_STEP * diff;
	valueTemp = value;
	AudioManager.set_volume()
