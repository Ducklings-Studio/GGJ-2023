extends Control

func _ready():
	AudioManager.play("res://Assets/Audio/Effects/prepare_yourself.ogg")


func _on_Easy_pressed():
	get_tree().change_scene("res://Scenes/Game.tscn")


func _on_Suuuuuper_Easy_pressed():
	get_tree().change_scene("res://Scenes/Chill_Beach.tscn")


func _on_Very_Easy_pressed():
	get_tree().change_scene("res://Scenes/Chill_Beach.tscn")
	
	
func _on_Back_pressed():
	get_tree().change_scene("res://Scenes/Menu.tscn")
