extends Camera2D

export var delta = Vector2(2.5, 2.5)

export var panSpeed = 10.0
export var speed = 10.0
export var zoomspeed = 10.0

export var zoomMin = 0.25
export var zoomMax = 3.0
export var marginX = 200.0
export var marginY = 200.0

var mousepos = Vector2()
var zoomfactor = 1.0
var not_zooming = true

var selected
var action
var is_blocking = true
var gems = 0


var classes := [
	preload("res://Scenes/Mushrooms/Base.tscn"),
	preload("res://Scenes/Mushrooms/Standart.tscn"),
	preload("res://Scenes/Mushrooms/Bomber.tscn"),
	preload("res://Scenes/Mushrooms/Defender.tscn"),
	preload("res://Scenes/Mushrooms/Attacker.tscn"),
]

#Base for duelity
const BASE_POS = Vector2(-1, -24)

const START_X = -70;
const END_X = 70;
const START_Y = -70;
const END_Y = 70;


func _ready():
	set_fogs()
	add_gems(450)

	var base = get_parent().build(BASE_POS, 0)
	if base.has_method("_on_Miner_timeout"):
		base.connect("res_mined", self, "add_gems")
	remove_fog(0, BASE_POS)
	
	position = $"../floor".map_to_world(BASE_POS)
	clean_action()


func set_fogs():
	for i in range(START_X, END_X):
		for j in range(START_Y, END_Y):
			$"../fog".set_cellv(Vector2(i, j), 0)


func remove_fog(class_id: int, coords: Vector2):
	var radius = 7
	if class_id == 0:
		radius = 12
	for i in range(-radius, radius + 1): 
		for j in range(-radius, radius + 1):
			$"../fog".set_cellv(coords + Vector2(i,j), -1);


func add_gems(amount):
	gems += amount
	$"../HUD".set_gems(gems)


func _process(delta):
	if is_blocking:
		return
	var inpx = (int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left")))
	var inpy = (int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up")))
	position.x = lerp(position.x, position.x + inpx * speed * zoom.x, speed * delta)
	position.y = lerp(position.y, position.y + inpy * speed * zoom.y, speed * delta)

	if Input.is_key_pressed(KEY_SPACE):
		if mousepos.x < marginX:
			position.x = lerp(position.x, position.x - abs(mousepos.x - marginX)/marginX * panSpeed * zoom.x, panSpeed * delta)
		elif mousepos.x > OS.window_size.x - marginX:
			position.x = lerp(position.x, position.x + abs(mousepos.x - OS.window_size.x + marginX)/marginX *  panSpeed * zoom.x, panSpeed * delta)
		if mousepos.y < marginY:
			position.y = lerp(position.y, position.y - abs(mousepos.y - marginY)/marginY * panSpeed * zoom.y, panSpeed * delta)
		elif mousepos.y > OS.window_size.y - marginY:
			position.y = lerp(position.y, position.y + abs(mousepos.y - OS.window_size.y + marginY)/marginY * panSpeed * zoom.y, panSpeed * delta)

	#zoom in
	zoom.x = lerp(zoom.x, zoom.x * zoomfactor, zoomspeed * delta)
	zoom.y = lerp(zoom.y, zoom.y * zoomfactor, zoomspeed * delta)
	zoom.x = clamp(zoom.x, zoomMin, zoomMax)
	zoom.y = clamp(zoom.y, zoomMin, zoomMax)

	if not_zooming:
		zoomfactor = 1.0


func _unhandled_input(event):
	if is_blocking:
		return
	if event is InputEventMouseButton:
		not_zooming = true
		
		if event.is_pressed():
			not_zooming = false
			if event.button_index == BUTTON_WHEEL_UP:
				zoomfactor -= 0.01 * zoomspeed
			if event.button_index == BUTTON_WHEEL_DOWN:
				zoomfactor += 0.01 * zoomspeed
	
	if event is InputEventMouse:
		mousepos = event.position
	
	if event is InputEventMouseButton:
		if !event.is_pressed():
			return

		if InputMap.event_is_action(event, "ui_left_mouse_button"):
			var evpos = get_global_mouse_position() + delta
			var coords = $"../floor".world_to_map(evpos)

			if get_parent().objs.has(coords):
				selected = get_parent().get_centered(coords)
				$"../HUD".show_options(get_parent().objs[selected].abilities)
				return

			if action == Global.BUILD and $"../fog".get_cellv(coords) and get_parent().can_be_built(selected, coords, gems):
				var mushroom = get_parent().build(coords, 1)
				if mushroom.has_method("_on_Miner_timeout"):
					mushroom.connect("res_mined", self, "add_gems")
				add_gems(-mushroom.cost)
				
				remove_fog(1, coords)
				get_parent().build_roots(selected, coords, 2)
				if get_parent().graph.has(selected):
					get_parent().graph[selected].push_back(coords)
				else:
					get_parent().graph[selected] = [coords]
				get_parent().reversed_graph[coords] = selected
				clean_action()
			elif action == Global.ATTACK and get_parent().is_enough_gems(-1, gems, Global.ATTACK) and get_parent().can_attack(selected, coords):
				get_parent().attack(selected, coords)
				clean_action()

		elif InputMap.event_is_action(event, "ui_right_mouse_button"):
			clean_action()

	if event is InputEventMouseMotion and selected != null:
		var evpos = get_global_mouse_position() + delta
		var coords = $"../floor".world_to_map(evpos)
		if action == Global.BUILD:
			show_build_options(selected, coords)
		elif action == Global.ATTACK:
			show_build_options(selected, coords, true)

	if event.is_pressed() or selected == null:
		return

	if InputMap.event_is_action(event, "build") and "min_build_radius" in get_parent().objs[selected]:
		process_action(Global.BUILD)
		return
	if InputMap.event_is_action(event, "attack") and get_parent().objs[selected] is Attacker:
		process_action(Global.ATTACK)
		return
	if InputMap.event_is_action(event, "explode") and get_parent().objs[selected] is Bomber:
		process_action(Global.EXPLODE)
		return
	
	if not get_parent().objs[selected] is Standart:
		return
	
	if InputMap.event_is_action(event, "evolve_attack"):
		process_action(Global.E_ATTACK)
		return
	if InputMap.event_is_action(event, "evolve_bomb"):
		process_action(Global.E_BOMB)
		return
	if InputMap.event_is_action(event, "evolve_defender"):
		process_action(Global.E_DEFENDER)
		return


func process_action(action_id):
	action = action_id

	if action == Global.EXPLODE:
		get_parent().explode(selected)
		return

	var mushroom
	if action == Global.E_ATTACK:
		if get_parent().is_enough_gems(4, gems, Global.E_ATTACK):
			mushroom = get_parent().evolve(selected, 4)
	elif action == Global.E_BOMB:
		if get_parent().is_enough_gems(2, gems, Global.E_BOMB):
			mushroom = get_parent().evolve(selected, 2)
	elif action == Global.E_DEFENDER:
		if get_parent().is_enough_gems(3, gems, Global.E_DEFENDER):
			mushroom = get_parent().evolve(selected, 3)
	else:
		return

	print(mushroom)
	if mushroom != null and mushroom.has_method("_on_Miner_timeout"):
		mushroom.connect("res_mined", self, "add_gems")
		add_gems(-mushroom.cost)
	clean_action()


func clean_action():
	selected = null
	action = null
	$"../HUD".show_options([])
	$"../tips".clear()


func show_build_options(origin: Vector2, coords: Vector2, is_attack = false):
	$"../tips".clear()
	coords -= Vector2.ONE
	
	if is_attack:
		$"../tips".set_cellv(coords, 6)
		return

	if $"../fog".get_cellv(coords) and get_parent().can_be_built(origin, coords + Vector2.ONE, gems): 
		$"../tips".set_cellv(coords, 0)
	else:
		$"../tips".set_cellv(coords, 1)


func _on_HUD_game_started():
	is_blocking = false
