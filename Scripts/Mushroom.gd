extends Node2D
class_name BasicMushroom

signal res_mined(amount)
signal built()

export var abilities: Array = []
export var radius: int = 1
export var cost: int = 500
export var time_to_build: int = 10
export var res_per_sec: int = 10

var build_timer = Timer.new()
var miner_timer = Timer.new()


func _ready():
	build_timer.connect("timeout", self, "_on_Built")
	miner_timer.connect("timeout", self, "_on_Miner_timeout")

	build_timer.wait_time = time_to_build
	miner_timer.wait_time = 1

	add_child(build_timer)
	add_child(miner_timer)

	build_timer.start()


func _on_Built():
	build_timer.stop()
	remove_child(build_timer)
	emit_signal("built")
	miner_timer.start()


func _on_Miner_timeout():
	emit_signal("res_mined", res_per_sec)
