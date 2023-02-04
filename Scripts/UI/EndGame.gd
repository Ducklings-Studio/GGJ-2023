extends Control


func _ready():
	$VBoxContainer/Title.text = Global.get_endgame_parameter().EndGameText
	$VBoxContainer/HBoxContainer/ModeName.text = Global.get_endgame_parameter().ModeName
	$VBoxContainer/HBoxContainer2/MatchTimer.text = Global.get_endgame_parameter().MatchTimer
	$VBoxContainer/HBoxContainer3/Mushrooms.text = String(Global.get_endgame_parameter().Mushrooms)
	$VBoxContainer/HBoxContainer4/MushroomsLost.text =  String(Global.get_endgame_parameter().MushroomsLost)
	$VBoxContainer/HBoxContainer5/MineralsMine.text =  String(Global.get_endgame_parameter().MineralsMine)
	$VBoxContainer/HBoxContainer6/MineralsSpend.text =  String(Global.get_endgame_parameter().MineralsSpend)
	
	$TextureRect.texture = load("res://Assets/" + Global.get_endgame_parameter().BgPicture)
	AudioManager.set_music("res://Assets/Audio/" + Global.get_endgame_parameter().BgAudio)
	
func _input(event):
	if event is InputEventKey:
		if event.pressed:
			get_tree().change_scene("res://Scenes/UI/Menu.tscn")
