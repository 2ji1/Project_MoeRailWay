extends "res://tests/support/prototype_test.gd"

const GridPointerRasterizerScript = preload(
	"res://src/presentation/track/grid_pointer_rasterizer.gd"
)


func run() -> PackedStringArray:
	_test_public_class_contract()
	_test_horizontal_fast_motion()
	_test_vertical_fast_motion()
	_test_l_shape_uses_two_physical_events()
	_test_outside_grid_motion()
	_test_outside_reentry_preserves_intermediate_cells()
	_test_outside_to_outside_crossing_preserves_in_grid_cells()
	_test_reverse_outside_crossing_preserves_in_grid_cells()
	_test_corner_touch_does_not_invent_a_cell()
	_test_outer_edge_corner_entry_uses_inward_cell()
	_test_outer_axis_first_corner_entry_preserves_two_cells()
	_test_equal_axis_corner_entry_uses_horizontal_first()
	_test_corner_entry_can_return_to_historical_previous_cell()
	_test_outer_edge_corner_exit_keeps_deterministic_inside_step()
	_test_reentry_does_not_pathfind_across_an_unobserved_gap()
	_test_repeated_cell_is_suppressed()
	_test_reverse_axis_crossings()
	_test_exact_boundary_and_reverse_suppression()
	_test_horizontal_dominant_corner()
	_test_vertical_dominant_corner()
	_test_equal_axis_corner_is_horizontal_first()
	_test_reverse_equal_axis_corner_is_horizontal_first()
	_test_mixed_direction_dominant_corners()
	return finish()


func _test_public_class_contract() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	assert_equal(
		rasterizer.get_script().get_global_name(),
		StringName("GridPointerRasterizer"),
		"Rasterizer publishes the canonical public class name"
	)


func _test_horizontal_fast_motion() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var result: Array[Vector2i] = rasterizer.rasterize_motion(
		Vector2(20.0, 20.0),
		Vector2(140.0, 20.0),
		Rect2(Vector2.ZERO, Vector2(1200.0, 560.0)),
		Vector2i(30, 14),
		Vector2i(0, 0)
	)
	assert_equal(
		result,
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
		"Fast horizontal motion preserves every crossed cell"
	)


func _test_vertical_fast_motion() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var result: Array[Vector2i] = rasterizer.rasterize_motion(
		Vector2(20.0, 20.0),
		Vector2(20.0, 140.0),
		Rect2(Vector2.ZERO, Vector2(1200.0, 560.0)),
		Vector2i(30, 14),
		Vector2i(0, 0)
	)
	assert_equal(
		result,
		[Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)],
		"Fast vertical motion preserves every crossed cell"
	)


func _test_l_shape_uses_two_physical_events() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var grid_rect := Rect2(Vector2.ZERO, Vector2(160.0, 160.0))
	var first: Array[Vector2i] = rasterizer.rasterize_motion(
		Vector2(20.0, 20.0), Vector2(100.0, 20.0), grid_rect, Vector2i(4, 4), Vector2i(0, 0)
	)
	var second: Array[Vector2i] = rasterizer.rasterize_motion(
		Vector2(100.0, 20.0), Vector2(100.0, 100.0), grid_rect, Vector2i(4, 4), Vector2i(2, 0)
	)
	var combined: Array[Vector2i] = first.duplicate()
	combined.append_array(second)
	assert_equal(
		combined,
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)],
		"An L shape preserves the order of two physical events"
	)


func _test_outside_grid_motion() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var grid_rect := Rect2(Vector2.ZERO, Vector2(160.0, 160.0))
	assert_equal(
		rasterizer.rasterize_motion(
			Vector2(-100.0, -100.0), Vector2(-20.0, -20.0), grid_rect, Vector2i(4, 4), Vector2i(0, 0)
		),
		[],
		"A segment wholly outside the grid emits no cells"
	)
	assert_equal(
		rasterizer.rasterize_motion(
			Vector2(140.0, 20.0), Vector2(220.0, 20.0), grid_rect, Vector2i(4, 4), Vector2i(3, 0)
		),
		[],
		"Leaving the final grid cell never emits an outside cell"
	)
	assert_equal(
		rasterizer.rasterize_motion(
			Vector2(20.0, 20.0), Vector2(220.0, 20.0), grid_rect, Vector2i(4, 4), Vector2i(0, 0)
		),
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
		"Motion leaving the grid preserves only its in-grid crossings"
	)


func _test_outside_reentry_preserves_intermediate_cells() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var result: Array[Vector2i] = rasterizer.rasterize_motion(
		Vector2(180.0, 60.0),
		Vector2(140.0, 140.0),
		Rect2(Vector2.ZERO, Vector2(160.0, 160.0)),
		Vector2i(4, 4),
		Vector2i(3, 1)
	)
	assert_equal(
		result,
		[Vector2i(3, 2), Vector2i(3, 3)],
		"Reentry from outside preserves every in-grid cell between the accepted endpoint and pointer"
	)


func _test_outside_to_outside_crossing_preserves_in_grid_cells() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var result: Array[Vector2i] = rasterizer.rasterize_motion(
		Vector2(-20.0, 20.0),
		Vector2(180.0, 20.0),
		Rect2(Vector2.ZERO, Vector2(160.0, 160.0)),
		Vector2i(4, 4),
		Vector2i(-1, -1)
	)
	assert_equal(
		result,
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
		"A physical segment with outside endpoints preserves the complete in-grid crossing"
	)


func _test_reverse_outside_crossing_preserves_in_grid_cells() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var result: Array[Vector2i] = rasterizer.rasterize_motion(
		Vector2(180.0, 20.0),
		Vector2(-20.0, 20.0),
		Rect2(Vector2.ZERO, Vector2(160.0, 160.0)),
		Vector2i(4, 4),
		Vector2i(-1, -1)
	)
	assert_equal(
		result,
		[Vector2i(3, 0), Vector2i(2, 0), Vector2i(1, 0), Vector2i(0, 0)],
		"A reverse outside crossing preserves the same physical order"
	)


func _test_corner_touch_does_not_invent_a_cell() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var result: Array[Vector2i] = rasterizer.rasterize_motion(
		Vector2(-20.0, 20.0),
		Vector2(20.0, -20.0),
		Rect2(Vector2.ZERO, Vector2(160.0, 160.0)),
		Vector2i(4, 4),
		Vector2i(-1, -1)
	)
	assert_equal(
		result,
		[],
		"A segment touching only the outer corner does not claim an in-grid cell"
	)


func _test_outer_edge_corner_entry_uses_inward_cell() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var grid_rect := Rect2(Vector2.ZERO, Vector2(160.0, 160.0))
	var cases := [
		{"label": "right", "from": Vector2(180.0, 110.0), "to": Vector2(140.0, 50.0), "expected": [Vector2i(3, 1)]},
		{"label": "left", "from": Vector2(-20.0, 110.0), "to": Vector2(20.0, 50.0), "expected": [Vector2i(0, 1)]},
		{"label": "top", "from": Vector2(110.0, -20.0), "to": Vector2(50.0, 20.0), "expected": [Vector2i(1, 0)]},
		{"label": "bottom", "from": Vector2(110.0, 180.0), "to": Vector2(50.0, 140.0), "expected": [Vector2i(1, 3)]},
	]
	for entry_case in cases:
		assert_equal(
			rasterizer.rasterize_motion(
				entry_case["from"], entry_case["to"], grid_rect,
				Vector2i(4, 4), Vector2i(-1, -1)
			),
			entry_case["expected"],
			"%s-edge corner entry begins in the directionally inward cell" % entry_case["label"]
		)


func _test_outer_axis_first_corner_entry_preserves_two_cells() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var grid_rect := Rect2(Vector2.ZERO, Vector2(160.0, 160.0))
	var cases := [
		{"label": "right", "from": Vector2(180.0, 70.0), "to": Vector2(140.0, 90.0), "expected": [Vector2i(3, 1), Vector2i(3, 2)]},
		{"label": "left", "from": Vector2(-20.0, 70.0), "to": Vector2(20.0, 90.0), "expected": [Vector2i(0, 1), Vector2i(0, 2)]},
		{"label": "top", "from": Vector2(70.0, -20.0), "to": Vector2(90.0, 20.0), "expected": [Vector2i(1, 0), Vector2i(2, 0)]},
		{"label": "bottom", "from": Vector2(70.0, 180.0), "to": Vector2(90.0, 140.0), "expected": [Vector2i(1, 3), Vector2i(2, 3)]},
	]
	for entry_case in cases:
		assert_equal(
			rasterizer.rasterize_motion(
				entry_case["from"], entry_case["to"], grid_rect,
				Vector2i(4, 4), Vector2i(-1, -1)
			),
			entry_case["expected"],
			"%s-edge outer-axis-first entry preserves both in-grid corner cells" % entry_case["label"]
		)


func _test_equal_axis_corner_entry_uses_horizontal_first() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var grid_rect := Rect2(Vector2.ZERO, Vector2(160.0, 160.0))
	var cases := [
		{"label": "right", "from": Vector2(180.0, 60.0), "to": Vector2(140.0, 100.0), "expected": [Vector2i(3, 1), Vector2i(3, 2)]},
		{"label": "left", "from": Vector2(-20.0, 60.0), "to": Vector2(20.0, 100.0), "expected": [Vector2i(0, 1), Vector2i(0, 2)]},
		{"label": "top", "from": Vector2(60.0, -20.0), "to": Vector2(100.0, 20.0), "expected": [Vector2i(2, 0)]},
		{"label": "bottom", "from": Vector2(60.0, 180.0), "to": Vector2(100.0, 140.0), "expected": [Vector2i(2, 3)]},
	]
	for entry_case in cases:
		assert_equal(
			rasterizer.rasterize_motion(
				entry_case["from"], entry_case["to"], grid_rect,
				Vector2i(4, 4), Vector2i(-1, -1)
			),
			entry_case["expected"],
			"%s-edge equal-axis entry applies the horizontal-first tie rule" % entry_case["label"]
		)


func _test_corner_entry_can_return_to_historical_previous_cell() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var grid_rect := Rect2(Vector2.ZERO, Vector2(160.0, 160.0))
	var cases := [
		{"label": "right", "from": Vector2(180.0, 70.0), "to": Vector2(140.0, 90.0), "previous": Vector2i(3, 2), "expected": [Vector2i(3, 1), Vector2i(3, 2)]},
		{"label": "left", "from": Vector2(-20.0, 70.0), "to": Vector2(20.0, 90.0), "previous": Vector2i(0, 2), "expected": [Vector2i(0, 1), Vector2i(0, 2)]},
		{"label": "top", "from": Vector2(70.0, -20.0), "to": Vector2(90.0, 20.0), "previous": Vector2i(2, 0), "expected": [Vector2i(1, 0), Vector2i(2, 0)]},
		{"label": "bottom", "from": Vector2(70.0, 180.0), "to": Vector2(90.0, 140.0), "previous": Vector2i(2, 3), "expected": [Vector2i(1, 3), Vector2i(2, 3)]},
	]
	for entry_case in cases:
		assert_equal(
			rasterizer.rasterize_motion(
				entry_case["from"], entry_case["to"], grid_rect,
				Vector2i(4, 4), entry_case["previous"]
			),
			entry_case["expected"],
			"%s-edge entry may return to the historical cell after a new corner cell" % entry_case["label"]
		)


func _test_outer_edge_corner_exit_keeps_deterministic_inside_step() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var grid_rect := Rect2(Vector2.ZERO, Vector2(160.0, 160.0))
	var cases := [
		{"label": "right", "from": Vector2(140.0, 50.0), "to": Vector2(180.0, 110.0), "previous": Vector2i(3, 1), "expected": [Vector2i(3, 2)]},
		{"label": "left", "from": Vector2(20.0, 50.0), "to": Vector2(-20.0, 110.0), "previous": Vector2i(0, 1), "expected": [Vector2i(0, 2)]},
		{"label": "top", "from": Vector2(50.0, 20.0), "to": Vector2(110.0, -20.0), "previous": Vector2i(1, 0), "expected": [Vector2i(2, 0)]},
		{"label": "bottom", "from": Vector2(50.0, 140.0), "to": Vector2(110.0, 180.0), "previous": Vector2i(1, 3), "expected": [Vector2i(2, 3)]},
	]
	for exit_case in cases:
		assert_equal(
			rasterizer.rasterize_motion(
				exit_case["from"], exit_case["to"], grid_rect,
				Vector2i(4, 4), exit_case["previous"]
			),
			exit_case["expected"],
			"%s-edge corner exit keeps the deterministic in-grid corner step" % exit_case["label"]
		)


func _test_reentry_does_not_pathfind_across_an_unobserved_gap() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var result: Array[Vector2i] = rasterizer.rasterize_motion(
		Vector2(180.0, 140.0),
		Vector2(140.0, 140.0),
		Rect2(Vector2.ZERO, Vector2(160.0, 160.0)),
		Vector2i(4, 4),
		Vector2i(3, 0)
	)
	assert_equal(
		result,
		[Vector2i(3, 3)],
		"Reentry reports its observed cell without inventing a path from the prior endpoint"
	)


func _test_repeated_cell_is_suppressed() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var grid_rect := Rect2(Vector2.ZERO, Vector2(160.0, 160.0))
	assert_equal(
		rasterizer.rasterize_motion(
			Vector2(20.0, 20.0), Vector2(20.0, 20.0), grid_rect, Vector2i(4, 4), Vector2i(0, 0)
		),
		[],
		"Zero motion emits no cell"
	)
	assert_equal(
		rasterizer.rasterize_motion(
			Vector2(20.0, 20.0), Vector2(30.0, 30.0), grid_rect, Vector2i(4, 4), Vector2i(0, 0)
		),
		[],
		"Motion within one cell emits no cell"
	)
	assert_equal(
		rasterizer.rasterize_motion(
			Vector2(20.0, 20.0), Vector2(60.0, 20.0), grid_rect, Vector2i(4, 4), Vector2i(1, 0)
		),
		[],
		"The supplied previous cell is not repeated"
	)


func _test_reverse_axis_crossings() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var grid_rect := Rect2(Vector2.ZERO, Vector2(160.0, 160.0))
	assert_equal(
		rasterizer.rasterize_motion(
			Vector2(140.0, 20.0), Vector2(20.0, 20.0), grid_rect, Vector2i(4, 4), Vector2i(3, 0)
		),
		[Vector2i(2, 0), Vector2i(1, 0), Vector2i(0, 0)],
		"Reverse horizontal motion preserves every crossed cell"
	)
	assert_equal(
		rasterizer.rasterize_motion(
			Vector2(20.0, 140.0), Vector2(20.0, 20.0), grid_rect, Vector2i(4, 4), Vector2i(0, 3)
		),
		[Vector2i(0, 2), Vector2i(0, 1), Vector2i(0, 0)],
		"Reverse vertical motion preserves every crossed cell"
	)


func _test_exact_boundary_and_reverse_suppression() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var grid_rect := Rect2(Vector2.ZERO, Vector2(160.0, 160.0))
	assert_equal(
		rasterizer.rasterize_motion(
			Vector2(80.0, 20.0), Vector2(20.0, 20.0), grid_rect, Vector2i(4, 4), Vector2i(2, 0)
		),
		[Vector2i(1, 0), Vector2i(0, 0)],
		"Reverse motion crosses a boundary at the exact start time"
	)
	assert_equal(
		rasterizer.rasterize_motion(
			Vector2(20.0, 20.0), Vector2(80.0, 20.0), grid_rect, Vector2i(4, 4), Vector2i(0, 0)
		),
		[Vector2i(1, 0), Vector2i(2, 0)],
		"Forward motion includes a boundary at the exact endpoint"
	)
	assert_equal(
		rasterizer.rasterize_motion(
			Vector2(20.0, 20.0), Vector2(-60.0, 20.0), grid_rect, Vector2i(4, 4), Vector2i(0, 0)
		),
		[],
		"Leaving the left edge emits no outside cell"
	)
	assert_equal(
		rasterizer.rasterize_motion(
			Vector2(20.0, 20.0), Vector2(20.0, -60.0), grid_rect, Vector2i(4, 4), Vector2i(0, 0)
		),
		[],
		"Leaving the top edge emits no outside cell"
	)
	assert_equal(
		rasterizer.rasterize_motion(
			Vector2(140.0, 20.0), Vector2(100.0, 20.0), grid_rect, Vector2i(4, 4), Vector2i(2, 0)
		),
		[],
		"Reverse motion does not repeat the supplied previous cell"
	)


func _test_horizontal_dominant_corner() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var result: Array[Vector2i] = rasterizer.rasterize_motion(
		Vector2(20.0, 20.0),
		Vector2(140.0, 60.0),
		Rect2(Vector2.ZERO, Vector2(160.0, 160.0)),
		Vector2i(4, 4),
		Vector2i(0, 0)
	)
	assert_equal(
		result,
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(3, 1)],
		"A horizontal-dominant corner crosses horizontally first"
	)


func _test_vertical_dominant_corner() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var result: Array[Vector2i] = rasterizer.rasterize_motion(
		Vector2(20.0, 20.0),
		Vector2(60.0, 140.0),
		Rect2(Vector2.ZERO, Vector2(160.0, 160.0)),
		Vector2i(4, 4),
		Vector2i(0, 0)
	)
	assert_equal(
		result,
		[Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(1, 3)],
		"A vertical-dominant corner crosses vertically first"
	)


func _test_equal_axis_corner_is_horizontal_first() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var result: Array[Vector2i] = rasterizer.rasterize_motion(
		Vector2(20.0, 20.0),
		Vector2(100.0, 100.0),
		Rect2(Vector2.ZERO, Vector2(160.0, 160.0)),
		Vector2i(4, 4),
		Vector2i(0, 0)
	)
	assert_equal(
		result,
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],
		"An equal-axis corner crosses horizontally first"
	)


func _test_reverse_equal_axis_corner_is_horizontal_first() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var result: Array[Vector2i] = rasterizer.rasterize_motion(
		Vector2(140.0, 140.0),
		Vector2(60.0, 60.0),
		Rect2(Vector2.ZERO, Vector2(160.0, 160.0)),
		Vector2i(4, 4),
		Vector2i(3, 3)
	)
	assert_equal(
		result,
		[Vector2i(2, 3), Vector2i(2, 2), Vector2i(1, 2), Vector2i(1, 1)],
		"A reverse equal-axis corner crosses horizontally first"
	)


func _test_mixed_direction_dominant_corners() -> void:
	var rasterizer = GridPointerRasterizerScript.new()
	var grid_rect := Rect2(Vector2.ZERO, Vector2(160.0, 160.0))
	assert_equal(
		rasterizer.rasterize_motion(
			Vector2(20.0, 140.0), Vector2(140.0, 100.0), grid_rect, Vector2i(4, 4), Vector2i(0, 3)
		),
		[Vector2i(1, 3), Vector2i(2, 3), Vector2i(2, 2), Vector2i(3, 2)],
		"A mixed horizontal-dominant corner crosses horizontally first"
	)
	assert_equal(
		rasterizer.rasterize_motion(
			Vector2(140.0, 20.0), Vector2(100.0, 140.0), grid_rect, Vector2i(4, 4), Vector2i(3, 0)
		),
		[Vector2i(3, 1), Vector2i(3, 2), Vector2i(2, 2), Vector2i(2, 3)],
		"A mixed vertical-dominant corner crosses vertically first"
	)
