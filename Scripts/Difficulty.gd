extends Control

func _on_Hard_pressed():
	Global.set_endgame_mode("K_HARD")
	get_tree().change_scene("res://Scenes/Locations/Game.tscn")


func _on_Normal_pressed():
	Global.set_endgame_mode("K_NORM")
	get_tree().change_scene("res://Scenes/Locations/Chill_Beach.tscn")


func _on_Easy_pressed():
	Global.set_endgame_mode("K_EASY")
	get_tree().change_scene("res://Scenes/Locations/Duelity.tscn")
	

func _on_Back_pressed():
	self.set_visible(false)

