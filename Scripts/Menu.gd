extends Control


func _on_Play_pressed():
	get_tree().change_scene("res://Scenes/Difficulty.tscn")


func _on_Settings_pressed():
	$Settings.set_visible(true)


func _on_Help_pressed():
	pass # Replace with function body.


func _on_Exit_pressed():
	pass # Replace with function body.


