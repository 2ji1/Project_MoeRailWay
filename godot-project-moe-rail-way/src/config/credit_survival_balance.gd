class_name CreditSurvivalBalance
extends Resource

const CompanyCreditBalanceScript = preload("res://src/config/company_credit_balance.gd")

@export var companies: Array[CompanyCreditBalanceScript] = [
	CompanyCreditBalanceScript.new(&"company_01", 400, 4, [Vector2i(0, 0), Vector2i(100, 100), Vector2i(300, 250), Vector2i(600, 500), Vector2i(1000, 800)]),
	CompanyCreditBalanceScript.new(&"company_02", 500, 4, [Vector2i(0, 0), Vector2i(100, 100), Vector2i(300, 275), Vector2i(600, 550), Vector2i(1000, 850)]),
	CompanyCreditBalanceScript.new(&"company_03", 600, 5, [Vector2i(0, 0), Vector2i(100, 125), Vector2i(300, 300), Vector2i(600, 575), Vector2i(1000, 900)]),
	CompanyCreditBalanceScript.new(&"company_04", 700, 5, [Vector2i(0, 0), Vector2i(100, 125), Vector2i(300, 325), Vector2i(600, 625), Vector2i(1000, 950)]),
	CompanyCreditBalanceScript.new(&"company_05", 800, 6, [Vector2i(0, 0), Vector2i(100, 150), Vector2i(300, 350), Vector2i(600, 675), Vector2i(1000, 1000)]),
	CompanyCreditBalanceScript.new(&"company_06", 900, 6, [Vector2i(0, 0), Vector2i(100, 150), Vector2i(300, 375), Vector2i(600, 725), Vector2i(1000, 1100)]),
]
func get_company(company_id: StringName):
	for company in companies:
		if company != null and company.company_id == company_id:
			return company
	return null


func get_credit_limit(company_id: StringName, trust_milli: int) -> int:
	var company = get_company(company_id)
	if company == null or trust_milli < 0 or company.trust_limit_knots.size() < 2:
		return -1
	var knots: Array[Vector2i] = company.trust_limit_knots
	if trust_milli >= knots[-1].x:
		return knots[-1].y
	for index in range(knots.size() - 1):
		var left := knots[index]
		var right := knots[index + 1]
		if trust_milli >= left.x and trust_milli < right.x:
			return left.y + ((trust_milli - left.x) * (right.y - left.y)) / (right.x - left.x)
	return -1


func get_next_limit_trust(company_id: StringName, trust_milli: int) -> int:
	var current_limit := get_credit_limit(company_id, trust_milli)
	var company = get_company(company_id)
	if current_limit < 0 or company == null or current_limit >= company.trust_limit_knots[-1].y:
		return -1
	for index in range(company.trust_limit_knots.size() - 1):
		var left: Vector2i = company.trust_limit_knots[index]
		var right: Vector2i = company.trust_limit_knots[index + 1]
		if right.y <= current_limit:
			continue
		var limit_delta := right.y - left.y
		var trust_delta := right.x - left.x
		var required_numerator := (current_limit - left.y + 1) * trust_delta
		var offset := (required_numerator + limit_delta - 1) / limit_delta
		var candidate := left.x + offset
		if candidate > trust_milli and candidate <= right.x:
			return candidate
	return -1


func get_rate_table(company_ids: Array[StringName]) -> Dictionary:
	var rates := {}
	for company_id in company_ids:
		var company = get_company(company_id)
		if company == null:
			return {}
		rates[company_id] = company.rate_basis_points
	return rates
