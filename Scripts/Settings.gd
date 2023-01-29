extends Control


func _on_Back_pressed():
	self.set_visible(false)


func _on_HSlider_value_changed(value):
	AudioManager.music_vol = -3*value
	AudioManager.set_volume()
