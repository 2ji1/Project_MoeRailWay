class_name GridPointerRasterizer
extends RefCounted

const CROSSING_EPSILON := 0.0000001


func rasterize_motion(
	from_logical: Vector2,
	to_logical: Vector2,
	grid_rect: Rect2,
	grid_size: Vector2i,
	previous_cell: Vector2i
) -> Array[Vector2i]:
	var crossed_cells: Array[Vector2i] = []
	if grid_size.x <= 0 or grid_size.y <= 0:
		return crossed_cells
	if grid_rect.size.x <= 0.0 or grid_rect.size.y <= 0.0:
		return crossed_cells
	if not grid_rect.has_point(from_logical):
		return crossed_cells

	var motion := to_logical - from_logical
	if motion.is_zero_approx():
		return crossed_cells

	var cell_size := Vector2(
		grid_rect.size.x / float(grid_size.x),
		grid_rect.size.y / float(grid_size.y)
	)
	var local_start := from_logical - grid_rect.position
	var current_cell := Vector2i(
		int(floor(local_start.x / cell_size.x)),
		int(floor(local_start.y / cell_size.y))
	)
	if not _is_cell_inside(current_cell, grid_size):
		return crossed_cells

	var step := Vector2i(_axis_step(motion.x), _axis_step(motion.y))
	var next_x_time := INF
	var next_y_time := INF
	var x_time_step := INF
	var y_time_step := INF
	if step.x != 0:
		var next_x_boundary := grid_rect.position.x + cell_size.x * float(
			current_cell.x + (1 if step.x > 0 else 0)
		)
		next_x_time = (next_x_boundary - from_logical.x) / motion.x
		x_time_step = cell_size.x / absf(motion.x)
	if step.y != 0:
		var next_y_boundary := grid_rect.position.y + cell_size.y * float(
			current_cell.y + (1 if step.y > 0 else 0)
		)
		next_y_time = (next_y_boundary - from_logical.y) / motion.y
		y_time_step = cell_size.y / absf(motion.y)

	var crossing_limit := grid_size.x + grid_size.y + 2
	for _crossing_index in range(crossing_limit):
		var crossing_time := minf(next_x_time, next_y_time)
		if crossing_time > 1.0 + CROSSING_EPSILON:
			break
		if absf(next_x_time - next_y_time) <= CROSSING_EPSILON:
			if absf(motion.x) >= absf(motion.y):
				current_cell.x += step.x
				_append_if_new(crossed_cells, current_cell, grid_size, previous_cell)
				current_cell.y += step.y
				_append_if_new(crossed_cells, current_cell, grid_size, previous_cell)
			else:
				current_cell.y += step.y
				_append_if_new(crossed_cells, current_cell, grid_size, previous_cell)
				current_cell.x += step.x
				_append_if_new(crossed_cells, current_cell, grid_size, previous_cell)
			next_x_time += x_time_step
			next_y_time += y_time_step
		elif next_x_time < next_y_time:
			current_cell.x += step.x
			_append_if_new(crossed_cells, current_cell, grid_size, previous_cell)
			next_x_time += x_time_step
		else:
			current_cell.y += step.y
			_append_if_new(crossed_cells, current_cell, grid_size, previous_cell)
			next_y_time += y_time_step
		if not _is_cell_inside(current_cell, grid_size):
			break

	return crossed_cells


func _axis_step(value: float) -> int:
	if value > 0.0:
		return 1
	if value < 0.0:
		return -1
	return 0


func _is_cell_inside(cell: Vector2i, grid_size: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y


func _append_if_new(
	cells: Array[Vector2i],
	cell: Vector2i,
	grid_size: Vector2i,
	previous_cell: Vector2i
) -> void:
	if not _is_cell_inside(cell, grid_size) or cell == previous_cell:
		return
	if not cells.is_empty() and cells[-1] == cell:
		return
	cells.append(cell)
