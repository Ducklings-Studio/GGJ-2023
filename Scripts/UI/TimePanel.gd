extends PanelContainer

var amount = 0 


func _on_Timer_timeout():
	amount += 1
	var minutes = amount / 60
	var seconds = amount % 60
	$MarginContainer/Time.set_text("%02d:%02d" % [minutes, seconds])


func Get_Time():
	return amount


func _on_HUD_game_started():
	$MarginContainer/Timer.start()
