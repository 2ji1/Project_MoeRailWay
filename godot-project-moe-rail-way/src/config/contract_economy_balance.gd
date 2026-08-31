class_name ContractEconomyBalance
extends Resource

const CompanyContractBalanceScript = preload("res://src/config/company_contract_balance.gd")

@export_range(0, 1000000, 1) var initial_run_cash := 300
@export_range(0, 1000000, 1) var base_operating_cost := 50
@export var companies: Array[CompanyContractBalanceScript] = [
	CompanyContractBalanceScript.new(&"company_01", "Company 1"),
	CompanyContractBalanceScript.new(&"company_02", "Company 2"),
	CompanyContractBalanceScript.new(&"company_03", "Company 3"),
	CompanyContractBalanceScript.new(&"company_04", "Company 4"),
	CompanyContractBalanceScript.new(&"company_05", "Company 5"),
	CompanyContractBalanceScript.new(&"company_06", "Company 6"),
]
