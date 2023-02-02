extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_Back_pressed():
	self.set_visible(false)
	
func _on_BasicRules_pressed():
	$BasicRulesHelp.set_visible(true);
	
func _on_StrikingMushroom_pressed():
	$AttackHelp.set_visible(true);
