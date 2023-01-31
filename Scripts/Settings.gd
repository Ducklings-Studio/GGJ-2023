extends Control


func _on_Back_pressed():
	self.set_visible(false)


func _on_AudiSlider_value_changed(value):
	AudioManager.audio_vol = -3*value
	AudioManager.set_volume()


func _on_MusicSlider_value_changed(value):
	AudioManager.music_vol = -3*value
	AudioManager.set_volume()
