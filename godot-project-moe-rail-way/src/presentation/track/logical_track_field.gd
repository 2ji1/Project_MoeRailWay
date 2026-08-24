@tool
class_name LogicalTrackField
extends Node2D

const DepartureCandidateScript = preload("res://src/presentation/track/departure_candidate.gd")

enum SizePreset {
	COMPACT,
	STANDARD,
	EXPANSIVE,
	CUSTOM,
}

const PRESET_SIZES := {
	SizePreset.COMPACT: Vector2(900.0, 420.0),
	SizePreset.STANDARD: Vector2(1200.0, 560.0),
	SizePreset.EXPANSIVE: Vector2(1500.0, 700.0),
}

const PRESET_GRID_SIZES := {
	SizePreset.COMPACT: Vector2i(22, 10),
	SizePreset.STANDARD: Vector2i(30, 14),
	SizePreset.EXPANSIVE: Vector2i(36, 16),
}

@export var size_preset: SizePreset = SizePreset.STANDARD:
	set(value):
		var old_size := get_logical_size()
		size_preset = value
		_rescale_candidates(old_size, get_logical_size())
		queue_redraw()

@export_range(640.0, 4000.0, 1.0) var custom_width := 1200.0:
	set(value):
		var old_size := get_logical_size()
		custom_width = value
		_rescale_candidates(old_size, get_logical_size())
		queue_redraw()

@export_range(320.0, 2160.0, 1.0) var custom_height := 560.0:
	set(value):
		var old_size := get_logical_size()
		custom_height = value
		_rescale_candidates(old_size, get_logical_size())
		queue_redraw()

@export var grid_cell_size_units := 40.0:
	set(value):
		grid_cell_size_units = value
		queue_redraw()

@export_range(1, 100, 1) var custom_grid_columns := 30:
	set(value):
		custom_grid_columns = value
		queue_redraw()

@export_range(1, 100, 1) var custom_grid_rows := 14:
	set(value):
		custom_grid_rows = value
		queue_redraw()


func get_logical_size() -> Vector2:
	if size_preset == SizePreset.CUSTOM:
		return Vector2(custom_width, custom_height)
	return PRESET_SIZES[size_preset]


func get_editor_boundary_rect() -> Rect2:
	return Rect2(Vector2.ZERO, get_logical_size())


func get_grid_size() -> Vector2i:
	if size_preset == SizePreset.CUSTOM:
		return Vector2i(custom_grid_columns, custom_grid_rows)
	return PRESET_GRID_SIZES[size_preset]


func get_grid_cell_size_units() -> float:
	return grid_cell_size_units


func get_grid_rect() -> Rect2:
	var grid_size := get_grid_size()
	var grid_extent := Vector2(grid_size) * grid_cell_size_units
	var origin := (get_logical_size() - grid_extent) * 0.5
	return Rect2(origin, grid_extent)


func logical_to_grid_cell(position: Vector2) -> Vector2i:
	var grid_size := get_grid_size()
	if grid_cell_size_units <= 0.0 or grid_size.x <= 0 or grid_size.y <= 0:
		return Vector2i(-1, -1)
	var grid_rect := get_grid_rect()
	if not grid_rect.has_point(position):
		return Vector2i(-1, -1)
	var local_position := position - grid_rect.position
	var cell := Vector2i(
		int(floor(local_position.x / grid_cell_size_units)),
		int(floor(local_position.y / grid_cell_size_units))
	)
	if cell.x < 0 or cell.x >= grid_size.x or cell.y < 0 or cell.y >= grid_size.y:
		return Vector2i(-1, -1)
	return cell


func grid_cell_center(cell: Vector2i) -> Vector2:
	return (
		get_grid_rect().position
		+ (Vector2(cell) + Vector2(0.5, 0.5)) * grid_cell_size_units
	)


func get_sorted_candidate_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	var candidate_parent = get_node_or_null("DepartureCandidates")
	if candidate_parent == null:
		return records
	for child in candidate_parent.get_children():
		if child is DepartureCandidateScript:
			records.append({
				"candidate_id": StringName(child.candidate_id),
				"position": Vector2(child.position),
			})
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.candidate_id) < String(b.candidate_id)
	)
	return records


func validate_configuration() -> PackedStringArray:
	var errors := PackedStringArray()
	var logical_size := get_logical_size()
	if size_preset == SizePreset.CUSTOM:
		if custom_width < 640.0:
			errors.append("custom_width must be at least 640")
		if custom_height < 320.0:
			errors.append("custom_height must be at least 320")
		if custom_width > 4000.0:
			errors.append("custom_width must be at most 4000")
		if custom_height > 2160.0:
			errors.append("custom_height must be at most 2160")
	if grid_cell_size_units <= 0.0:
		errors.append("grid_cell_size_units must be greater than 0")
	var grid_size := get_grid_size()
	if grid_size.x <= 0 or grid_size.y <= 0:
		errors.append("grid dimensions must be greater than 0")
	elif (
		grid_cell_size_units > 0.0
		and (
			float(grid_size.x) * grid_cell_size_units > logical_size.x
			or float(grid_size.y) * grid_cell_size_units > logical_size.y
		)
	):
		errors.append("grid dimensions must fit within logical bounds")
	var candidate_parent = get_node_or_null("DepartureCandidates")
	var candidate_count := 0
	if candidate_parent != null:
		for child in candidate_parent.get_children():
			if child is DepartureCandidateScript:
				candidate_count += 1
	if candidate_count == 0:
		errors.append("DepartureCandidates must contain at least one candidate")
		return errors
	var seen_ids := {}
	for child in candidate_parent.get_children():
		if not child is DepartureCandidateScript:
			continue
		var candidate_owner := "DepartureCandidates/%s" % String(child.name)
		if child.candidate_id.is_empty():
			errors.append("%s.candidate_id must not be empty" % candidate_owner)
		elif seen_ids.has(child.candidate_id):
			errors.append("%s.candidate_id must be unique" % candidate_owner)
		else:
			seen_ids[child.candidate_id] = true
		if (
			child.position.x < 0.0 or child.position.x > logical_size.x
			or child.position.y < 0.0 or child.position.y > logical_size.y
		):
			errors.append("%s.position must be within logical bounds" % candidate_owner)
	return errors


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(get_editor_boundary_rect(), Color(0.91, 0.73, 0.29, 0.9), false, 2.0)


func _rescale_candidates(old_size: Vector2, new_size: Vector2) -> void:
	if old_size.x <= 0.0 or old_size.y <= 0.0:
		return
	var candidate_parent = get_node_or_null("DepartureCandidates")
	if candidate_parent == null:
		return
	for child in candidate_parent.get_children():
		if child is DepartureCandidateScript:
			child.position = (child.position / old_size) * new_size
