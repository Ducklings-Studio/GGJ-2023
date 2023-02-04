extends Control


func _on_Back_pressed():
	self.set_visible(false)


func _on_BasicRules_pressed():
	$BasicRulesHelp.set_visible(true)


func _on_Building_pressed():
	$BuildingHelp.set_visible(true)


func _on_StrikingMushroom_pressed():
	$AttackHelp.set_visible(true)


func _on_ProtectiveMushroom_pressed():
	$DefenceHelp.set_visible(true)


func _on_UnstableMushroom_pressed():
	$ExplosionHelp.set_visible(true)

