class_name GridPointerRasterizer
extends RefCounted

const CROSSING_EPSILON := 0.0000001
const GRID_BOUNDARY_EPSILON := 0.000001


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

	var original_motion := to_logical - from_logical
	if original_motion.is_zero_approx():
		return crossed_cells
	var clipped_points := _clip_motion_to_grid(
		from_logical, to_logical, grid_rect
	)
	if clipped_points.is_empty():
		return crossed_cells
	var clipped_start: Vector2 = clipped_points[0]
	var clipped_end: Vector2 = clipped_points[1]

	var cell_size := Vector2(
		grid_rect.size.x / float(grid_size.x),
		grid_rect.size.y / float(grid_size.y)
	)
	clipped_start = _snap_point_to_grid_boundaries(
		clipped_start, grid_rect, cell_size
	)
	clipped_end = _snap_point_to_grid_boundaries(
		clipped_end, grid_rect, cell_size
	)
	var motion := clipped_end - clipped_start
	var entering_from_outside := not grid_rect.has_point(from_logical)
	var current_cell := _cell_at_clipped_entry(
		clipped_start, original_motion, grid_rect, cell_size, grid_size,
		entering_from_outside
	)
	if not _is_cell_inside(current_cell, grid_size):
		return crossed_cells
	if entering_from_outside:
		for entry_cell in _clipped_corner_entry_prefix(
			clipped_start, original_motion, grid_rect, cell_size,
			grid_size, current_cell
		):
			_append_if_new(crossed_cells, entry_cell, grid_size, previous_cell)
		_append_if_new(crossed_cells, current_cell, grid_size, previous_cell)
	if motion.is_zero_approx():
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
		next_x_time = (next_x_boundary - clipped_start.x) / motion.x
		x_time_step = cell_size.x / absf(motion.x)
	if step.y != 0:
		var next_y_boundary := grid_rect.position.y + cell_size.y * float(
			current_cell.y + (1 if step.y > 0 else 0)
		)
		next_y_time = (next_y_boundary - clipped_start.y) / motion.y
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


func _clip_motion_to_grid(
	from_logical: Vector2,
	to_logical: Vector2,
	grid_rect: Rect2
) -> Array[Vector2]:
	var motion := to_logical - from_logical
	var interval := Vector2(0.0, 1.0)
	interval = _clip_axis(
		from_logical.x,
		motion.x,
		grid_rect.position.x,
		grid_rect.end.x,
		interval
	)
	if interval.x > interval.y + CROSSING_EPSILON:
		return []
	interval = _clip_axis(
		from_logical.y,
		motion.y,
		grid_rect.position.y,
		grid_rect.end.y,
		interval
	)
	if interval.x > interval.y + CROSSING_EPSILON:
		return []
	if (
		interval.y - interval.x <= CROSSING_EPSILON
		and not grid_rect.has_point(to_logical)
	):
		return []
	var clipped: Array[Vector2] = []
	clipped.append(_clamp_point_to_rect(from_logical + motion * interval.x, grid_rect))
	clipped.append(_clamp_point_to_rect(from_logical + motion * interval.y, grid_rect))
	return clipped


func _clamp_point_to_rect(point: Vector2, rect: Rect2) -> Vector2:
	return Vector2(
		clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y)
	)


func _snap_point_to_grid_boundaries(
	point: Vector2,
	grid_rect: Rect2,
	cell_size: Vector2
) -> Vector2:
	var grid_point := Vector2(
		(point.x - grid_rect.position.x) / cell_size.x,
		(point.y - grid_rect.position.y) / cell_size.y
	)
	var boundary_x := roundf(grid_point.x)
	var boundary_y := roundf(grid_point.y)
	if absf(grid_point.x - boundary_x) <= GRID_BOUNDARY_EPSILON:
		grid_point.x = boundary_x
	if absf(grid_point.y - boundary_y) <= GRID_BOUNDARY_EPSILON:
		grid_point.y = boundary_y
	return grid_rect.position + grid_point * cell_size


func _clip_axis(
	start: float,
	delta: float,
	minimum: float,
	maximum: float,
	interval: Vector2
) -> Vector2:
	if is_zero_approx(delta):
		if start < minimum or start >= maximum:
			return Vector2(1.0, 0.0)
		return interval
	var first := (minimum - start) / delta
	var second := (maximum - start) / delta
	if first > second:
		var swap := first
		first = second
		second = swap
	return Vector2(maxf(interval.x, first), minf(interval.y, second))


func _cell_at_clipped_entry(
	point: Vector2,
	motion: Vector2,
	grid_rect: Rect2,
	cell_size: Vector2,
	grid_size: Vector2i,
	entering_from_outside: bool
) -> Vector2i:
	var local_point := point - grid_rect.position
	var grid_point := Vector2(
		local_point.x / cell_size.x,
		local_point.y / cell_size.y
	)
	var cell := Vector2i(int(floor(grid_point.x)), int(floor(grid_point.y)))
	if entering_from_outside and motion.x < 0.0:
		var boundary_x := roundf(grid_point.x)
		if absf(grid_point.x - boundary_x) <= GRID_BOUNDARY_EPSILON:
			cell.x = int(boundary_x) - 1
	if entering_from_outside and motion.y < 0.0:
		var boundary_y := roundf(grid_point.y)
		if absf(grid_point.y - boundary_y) <= GRID_BOUNDARY_EPSILON:
			cell.y = int(boundary_y) - 1
	return cell


func _clipped_corner_entry_prefix(
	point: Vector2,
	motion: Vector2,
	grid_rect: Rect2,
	cell_size: Vector2,
	grid_size: Vector2i,
	inward_cell: Vector2i
) -> Array[Vector2i]:
	var prefix: Array[Vector2i] = []
	var local_point := point - grid_rect.position
	var grid_point := Vector2(
		local_point.x / cell_size.x,
		local_point.y / cell_size.y
	)
	var boundary_x := _grid_boundary_index(grid_point.x)
	var boundary_y := _grid_boundary_index(grid_point.y)
	var x_is_outer := boundary_x == 0 or boundary_x == grid_size.x
	var y_is_outer := boundary_y == 0 or boundary_y == grid_size.y
	var x_is_internal := boundary_x > 0 and boundary_x < grid_size.x
	var y_is_internal := boundary_y > 0 and boundary_y < grid_size.y
	var horizontal_first := absf(motion.x) >= absf(motion.y)
	var intermediate := Vector2i(-1, -1)
	if x_is_outer and y_is_internal and horizontal_first and motion.y != 0.0:
		intermediate = inward_cell - Vector2i(0, _axis_step(motion.y))
	elif y_is_outer and x_is_internal and not horizontal_first and motion.x != 0.0:
		intermediate = inward_cell - Vector2i(_axis_step(motion.x), 0)
	if _is_cell_inside(intermediate, grid_size):
		prefix.append(intermediate)
	return prefix


func _grid_boundary_index(value: float) -> int:
	var boundary := roundf(value)
	if absf(value - boundary) <= GRID_BOUNDARY_EPSILON:
		return int(boundary)
	return -1


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
	if not _is_cell_inside(cell, grid_size):
		return
	if cells.is_empty() and cell == previous_cell:
		return
	if not cells.is_empty() and cells[-1] == cell:
		return
	cells.append(cell)
