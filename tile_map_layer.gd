extends TileMapLayer

@export var camera: Camera2D

var current_view_z := 20
var last_center := Vector2i(1 << 30, 1 << 30)
var cell_size = Vector2i(16,16)
var rendered := {} # Dictionary<Vector2i, int>

func _process(_delta):
	if camera == null:
		return

	var center_tile = local_to_map(to_local(camera.global_position))
	if center_tile != last_center:
		_update_visible_area(center_tile)
		last_center = center_tile

func _update_visible_area(center: Vector2i):
	# Calculate visible tiles based on viewport + camera zoom
	var viewport_tiles_x = int(ceil(get_viewport_rect().size.x / cell_size.x / camera.zoom.x))
	var viewport_tiles_y = int(ceil(get_viewport_rect().size.y / cell_size.y / camera.zoom.y))
	var half_x = viewport_tiles_x / 2
	var half_y = viewport_tiles_y / 2

	var visible_min = Vector2i(center.x - half_x, center.y - half_y)
	var visible_max = Vector2i(center.x + half_x, center.y + half_y)

	# Remove tiles no longer visible
	for pos in rendered.keys():
		if pos.x < visible_min.x or pos.x > visible_max.x \
		or pos.y < visible_min.y or pos.y > visible_max.y:
			set_cell(pos, -1)
			rendered.erase(pos)

	# Draw newly visible tiles
	for x in range(visible_min.x, visible_max.x + 1):
		for y in range(visible_min.y, visible_max.y + 1):
			var pos := Vector2i(x, y)
			if not rendered.has(pos):
				_draw_tile(pos)

func _draw_tile(pos: Vector2i):
	var data = Map.getTileData(Vector3i(pos.x, pos.y, current_view_z))
	if typeof(data) != TYPE_ARRAY or data.size() == 0:
		return

	var tile_id = data[0]
	if tile_id == -1:
		return

	rendered[pos] = tile_id
	if data.size() > 1:
		set_cell(pos, tile_id, data[1])
	else:
		set_cell(pos, tile_id)

func _full_redraw(center: Vector2i):
	clear()
	rendered.clear()
	_update_visible_area(center)

func _input(event):
	if event.is_action_pressed("zUp"):
		current_view_z += 1
		_full_redraw(last_center)

	elif event.is_action_pressed("zDown"):
		current_view_z -= 1
		_full_redraw(last_center)

	elif event.is_action_pressed("zoomOut"):
		_full_redraw(last_center)

	elif event.is_action_pressed("zoomIn"):
		_full_redraw(last_center)
