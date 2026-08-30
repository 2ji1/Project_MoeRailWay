class_name TrackInvestmentBalance
extends Resource

@export_range(0, 1000000, 1) var major_track_action_cost := 50
@export_range(0, 1000000, 1) var temporary_track_purchase_cost := 40
@export_range(1, 4096, 1) var temporary_track_cells_per_purchase := 5
@export_range(0, 100, 1) var maximum_temporary_track_purchases := 6
