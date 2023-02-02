extends Control

func _on_Hard_pressed():
	get_tree().change_scene("res://Scenes/Game.tscn")


func _on_Normal_pressed():
	get_tree().change_scene("res://Scenes/Chill_Beach.tscn")


func _on_Easy_pressed():
	get_tree().change_scene("res://Scenes/Duelity.tscn")
	

func _on_Back_pressed():
	self.set_visible(false)

