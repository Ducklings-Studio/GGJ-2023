extends Control


func _ready():
	$VBoxContainer/Title.text = Global.get_endgame_parametr().EndGameText;
	$VBoxContainer/HBoxContainer2/MatchTimer.text = Global.get_endgame_parametr().MatchTimer;
	$VBoxContainer/HBoxContainer3/Mushrooms.text = String(Global.get_endgame_parametr().Mushrooms);
	$VBoxContainer/HBoxContainer4/MushroomsLost.text =  String(Global.get_endgame_parametr().MushroomsLost);
	$VBoxContainer/HBoxContainer5/MineralsMine.text =  String(Global.get_endgame_parametr().MineralsMine);
	$VBoxContainer/HBoxContainer6/MineralsSpend.text =  String(Global.get_endgame_parametr().MineralsSpend);

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			get_tree().change_scene("res://Scenes/UI/Menu.tscn")
