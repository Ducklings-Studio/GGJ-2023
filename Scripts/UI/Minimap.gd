extends Control


export(NodePath) var camera_node
export(Array, NodePath) var tilemap_nodes
export(NodePath) var fog_node
export(Dictionary) var cell_colors

onready var camera = get_node(camera_node)
var tilemaps = []
var fog


func _ready():
	for node in tilemap_nodes:
		tilemaps.append(get_node(node))
	fog = get_node(fog_node)


func get_cells(tilemap : TileMap, id):
	return tilemap.get_used_cells_by_id(id)


var camera_position
var start_vec = Vector2.ONE*75


func _draw():
	if camera_position == null: return
	draw_set_transform(rect_size / 2, 0, Vector2.ONE)
	var zoom = 1 / camera.zoom.x
	var zoomed = Vector2.ONE * zoom

	var camera_cell = tilemaps[0].world_to_map(camera_position)
	var tilemap_offset = camera_cell + (camera_position - tilemaps[0].map_to_world(camera_cell)) / tilemaps[0].cell_size

	#draw_rect(Rect2((-start_vec - tilemap_offset) * zoom, 2 * start_vec * zoom), Color.black)
	for tilemap in tilemaps:
		for id in cell_colors.keys():
			var color = cell_colors[id]
			var cells = get_cells(tilemap, id)
			for cell in cells:
				if fog.get_cellv(cell) == -1:
					draw_rect(Rect2((cell - tilemap_offset) * zoom, zoomed), color)
	

func _process(delta):
	var tmp = camera.get_camera_screen_center()
	if camera_position != tmp:
		camera_position = tmp
		update()
