extends Control


func _on_Play_pressed():
	get_tree().change_scene("res://Scenes/Game.tscn")


func _on_Settings_pressed():
	$Settings.set_visible(true)
