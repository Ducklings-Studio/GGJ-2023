extends Control


func _ready():
	Global.upload_buttons()
	AudioManager.set_music("res://Assets/Audio/MenuSound.ogg")


func _on_Play_pressed():
	$Difficulty.set_visible(true)


func _on_Settings_pressed():
	$Settings.set_visible(true)


func _on_Help_pressed():
	$Help.set_visible(true)


func _on_Exit_pressed():
	get_tree().quit()
