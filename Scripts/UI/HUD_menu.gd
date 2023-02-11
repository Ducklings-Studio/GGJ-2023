extends PanelContainer


func _ready():
	set_visible(false)


func _on_Back_pressed():
	set_visible(false)


func _on_Settings_pressed():
	$"../Settings".set_visible(true)


func _on_Exit_pressed():
	get_tree().change_scene("res://Scenes/UI/Menu.tscn")


func _on_MenuBtn_pressed():
	set_visible(true)


func _on_Help_pressed():
	$"../Help".set_visible(true)
