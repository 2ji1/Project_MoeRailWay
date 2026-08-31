param(
    [Parameter(Mandatory = $true)]
    [string]$BaseCommit
)

$ErrorActionPreference = 'Stop'
$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$Allowlist = @(
    'docs/superpowers/plans/2026-08-30-credit-survival.md'
    'godot-project-moe-rail-way/data/credit_survival_balance.tres'
    'godot-project-moe-rail-way/data/prototype_balance.tres'
    'godot-project-moe-rail-way/src/app/prototype_app.gd'
    'godot-project-moe-rail-way/src/config/company_credit_balance.gd'
    'godot-project-moe-rail-way/src/config/company_credit_balance.gd.uid'
    'godot-project-moe-rail-way/src/config/credit_survival_balance.gd'
    'godot-project-moe-rail-way/src/config/credit_survival_balance.gd.uid'
    'godot-project-moe-rail-way/src/config/prototype_balance.gd'
    'godot-project-moe-rail-way/src/config/prototype_config_validator.gd'
    'godot-project-moe-rail-way/src/domain/credit/credit_quote.gd'
    'godot-project-moe-rail-way/src/domain/credit/credit_quote.gd.uid'
    'godot-project-moe-rail-way/src/domain/credit/credit_system.gd'
    'godot-project-moe-rail-way/src/domain/credit/credit_system.gd.uid'
    'godot-project-moe-rail-way/src/domain/credit/loan_record.gd'
    'godot-project-moe-rail-way/src/domain/credit/loan_record.gd.uid'
    'godot-project-moe-rail-way/src/domain/run/cycle_progression.gd'
    'godot-project-moe-rail-way/src/domain/run/cycle_progression.gd.uid'
    'godot-project-moe-rail-way/src/domain/run/prototype_run_controller.gd'
    'godot-project-moe-rail-way/src/domain/run/run_state.gd'
    'godot-project-moe-rail-way/src/domain/run/settlement_result.gd'
    'godot-project-moe-rail-way/src/domain/run/terminal_run_result.gd'
    'godot-project-moe-rail-way/src/domain/run/terminal_run_result.gd.uid'
    'godot-project-moe-rail-way/src/presentation/operations/operations_screen.gd'
    'godot-project-moe-rail-way/src/presentation/operations/operations_screen.tscn'
    'godot-project-moe-rail-way/src/presentation/results/contract_result_panel.gd'
    'godot-project-moe-rail-way/src/presentation/results/contract_result_panel.tscn'
    'godot-project-moe-rail-way/tests/fixtures/credit_survival_balance.tres'
    'godot-project-moe-rail-way/tests/integration/credit_survival_app.tscn'
    'godot-project-moe-rail-way/tests/integration/contract_economy_app.tscn'
    'godot-project-moe-rail-way/tests/integration/run_contract_economy_integration.gd'
    'godot-project-moe-rail-way/tests/integration/run_credit_survival_integration.gd'
    'godot-project-moe-rail-way/tests/integration/run_credit_survival_integration.gd.uid'
    'godot-project-moe-rail-way/tests/manual/credit_survival_windows.md'
    'godot-project-moe-rail-way/tests/run_all.gd'
    'godot-project-moe-rail-way/tests/smoke/test_track_train_app_composition.gd'
    'godot-project-moe-rail-way/tests/unit/test_contract_economy_presentation.gd'
    'godot-project-moe-rail-way/tests/unit/test_contract_session_controller.gd'
    'godot-project-moe-rail-way/tests/unit/test_credit_limit.gd'
    'godot-project-moe-rail-way/tests/unit/test_credit_limit.gd.uid'
    'godot-project-moe-rail-way/tests/unit/test_credit_settlement.gd'
    'godot-project-moe-rail-way/tests/unit/test_credit_settlement.gd.uid'
    'godot-project-moe-rail-way/tests/unit/test_credit_survival_presentation.gd'
    'godot-project-moe-rail-way/tests/unit/test_credit_survival_presentation.gd.uid'
    'godot-project-moe-rail-way/tests/unit/test_credit_system.gd'
    'godot-project-moe-rail-way/tests/unit/test_credit_system.gd.uid'
    'godot-project-moe-rail-way/tests/unit/test_cycle_progression.gd'
    'godot-project-moe-rail-way/tests/unit/test_cycle_progression.gd.uid'
    'godot-project-moe-rail-way/tests/unit/test_prototype_run_controller.gd'
    'godot-project-moe-rail-way/tests/unit/test_run_state.gd'
    'godot-project-moe-rail-way/tools/credit_survival/verify_feature.ps1'
)
$CreatePaths = @(
    'godot-project-moe-rail-way/src/config/company_credit_balance.gd'
    'godot-project-moe-rail-way/src/config/company_credit_balance.gd.uid'
    'godot-project-moe-rail-way/src/config/credit_survival_balance.gd'
    'godot-project-moe-rail-way/src/config/credit_survival_balance.gd.uid'
    'godot-project-moe-rail-way/data/credit_survival_balance.tres'
    'godot-project-moe-rail-way/tests/fixtures/credit_survival_balance.tres'
    'godot-project-moe-rail-way/tests/unit/test_credit_limit.gd'
    'godot-project-moe-rail-way/tests/unit/test_credit_limit.gd.uid'
    'godot-project-moe-rail-way/src/domain/credit/loan_record.gd'
    'godot-project-moe-rail-way/src/domain/credit/loan_record.gd.uid'
    'godot-project-moe-rail-way/src/domain/credit/credit_system.gd'
    'godot-project-moe-rail-way/src/domain/credit/credit_system.gd.uid'
    'godot-project-moe-rail-way/tests/unit/test_credit_system.gd'
    'godot-project-moe-rail-way/tests/unit/test_credit_system.gd.uid'
    'godot-project-moe-rail-way/src/domain/credit/credit_quote.gd'
    'godot-project-moe-rail-way/src/domain/credit/credit_quote.gd.uid'
    'godot-project-moe-rail-way/tests/unit/test_credit_settlement.gd'
    'godot-project-moe-rail-way/tests/unit/test_credit_settlement.gd.uid'
    'godot-project-moe-rail-way/src/domain/run/cycle_progression.gd'
    'godot-project-moe-rail-way/src/domain/run/cycle_progression.gd.uid'
    'godot-project-moe-rail-way/src/domain/run/terminal_run_result.gd'
    'godot-project-moe-rail-way/src/domain/run/terminal_run_result.gd.uid'
    'godot-project-moe-rail-way/tests/unit/test_cycle_progression.gd'
    'godot-project-moe-rail-way/tests/unit/test_cycle_progression.gd.uid'
    'godot-project-moe-rail-way/tests/unit/test_credit_survival_presentation.gd'
    'godot-project-moe-rail-way/tests/unit/test_credit_survival_presentation.gd.uid'
    'godot-project-moe-rail-way/tests/integration/credit_survival_app.tscn'
    'godot-project-moe-rail-way/tests/integration/run_credit_survival_integration.gd'
    'godot-project-moe-rail-way/tests/integration/run_credit_survival_integration.gd.uid'
    'godot-project-moe-rail-way/tests/manual/credit_survival_windows.md'
    'godot-project-moe-rail-way/tools/credit_survival/verify_feature.ps1'
)

Push-Location $RepositoryRoot
try {
    git cat-file -e "$BaseCommit^{commit}"
    if ($LASTEXITCODE -ne 0) { throw 'Base commit does not resolve.' }
    $Changed = @(git diff --name-only "$BaseCommit...HEAD")
    $Outside = @($Changed | Where-Object { $_ -notin $Allowlist })
    if ($Outside.Count -ne 0) { throw "Feature paths outside allowlist: $($Outside -join ', ')" }
    foreach ($Path in $CreatePaths) {
        git cat-file -e "HEAD:$Path"
        if ($LASTEXITCODE -ne 0) { throw "Missing planned Credit create path: $Path" }
    }
    $RenameDelete = @(git diff --name-status --diff-filter=RD "$BaseCommit...HEAD")
    if ($RenameDelete.Count -ne 0) { throw "Rename/delete audit failed: $($RenameDelete -join ', ')" }
    git diff --check "$BaseCommit...HEAD"
    if ($LASTEXITCODE -ne 0) { throw 'Feature diff check failed.' }
    $Tracked = @(git ls-files)
    $Scripts = @($Tracked | Where-Object { $_.EndsWith('.gd') })
    $Uids = @($Tracked | Where-Object { $_.EndsWith('.gd.uid') })
    foreach ($Script in $Scripts) {
        if ("$Script.uid" -notin $Uids) { throw "Missing UID for $Script" }
    }
    foreach ($Uid in $Uids) {
        if ($Uid.Substring(0, $Uid.Length - 4) -notin $Scripts) { throw "Orphan UID $Uid" }
    }
    Write-Output "PASS: credit survival structural verification ($($Scripts.Count) scripts)"
}
finally {
    Pop-Location
}
