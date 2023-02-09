extends BasicMushroom
class_name Attacker

export var attack_price: int = 100
export var attack_radius: int = 10
export var attack_cooldown: int = 3
var timer = Timer.new()
var reloaded = true

func _ready():
	timer.connect("timeout", self, "_on_reloaded")
	timer.wait_time = attack_cooldown
	add_child(timer)

func _on_reloaded():
	reloaded = true
	timer.stop()

func can_attack():
	return reloaded

func try_attack():
	if reloaded:
		timer.start()
		reloaded = false
		return true
	else:
		return false
