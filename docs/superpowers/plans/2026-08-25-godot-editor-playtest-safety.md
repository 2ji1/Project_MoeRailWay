# Godot Editor Playtest Safety Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a deterministic, safe Godot editor playtest launcher that mirrors only tracked HEAD files into an isolated temporary environment, validates byte-identical mirrors, runs the canonical Godot 4.7.1 GUI editor with fully overridden child-only environment variables, scans editor and game logs for prohibited diagnostics (including the exact gutter incident), preserves the exact mirror on any failure for inspection, and cleans up only after full revalidation on success. No runtime or gameplay changes; no generalized framework; no process enumeration/termination; no copy-back; no Steam 4.7.2.

**Architecture:** Two PowerShell scripts — a launcher (`launch_editor_playtest.ps1`) and its behavior test (`test_launch_editor_playtest.ps1`) — operating on the Godot project at `godot-project-moe-rail-way`. The launcher uses `git archive` + `tar` for byte-safe mirror materialization from a pinned HEAD, `System.Diagnostics.Process` with `UseShellExecute=false` and `ArgumentList` for controlled visible GUI editor execution with child-only `APPDATA`/`LOCALAPPDATA`/`TEMP`/`TMP` overrides, SHA-256 manifests for source integrity verification before and after, and anchored log scanning for `FAIL:`, `ERROR:`, `SCRIPT ERROR:`, `FATAL:`, `WARNING:`, `CRASH:`, exact gutter diagnostic, and established RID/ObjectDB leak terms from the disposable-mirror amendment.

**Tech Stack:** PowerShell 7.4+ (`pwsh`) on modern .NET, .NET SDK 9.0.100 with an installed compatible .NET 9 runtime (`dotnet publish` for a framework-dependent test executable plus its runtime metadata only), Git for Windows, Git Bash 5.2.37 at `C:\Program Files\Git\bin\bash.exe`, tar (bsdtar 3.8.4), Godot 4.7.1.stable.official.a13da4feb (canonical GUI executable at `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64.exe`; console sibling at `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe`).

**Spec:** `docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md`

## Global Constraints

- authoring model `nvidia/nvidia-nemotron-3-ultra-550b-a55b`; web `gpt-5.6-luna`; all specification, quality, and code reviews `gpt-5.6-sol`.
- primary worktree protected and must remain clean at SHA `38d091476c0d940c3118e1e9635deadd225be80d`; feature worktree is `D:\godot\MoeRailWay-worktrees\feature-godot-editor-playtest-safety` on `feature/godot-editor-playtest-safety` based on `origin/main`.
- exact GUI `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64.exe` and console sibling ending `_console.exe`, version `4.7.1.stable.official.a13da4feb`.
- no gameplay/runtime changes, generalized framework, process enumeration/termination/reset, copy-back, user environment mutation, Steam 4.7.2, push, PR, merge, tag, or worktree cleanup.
- every task: real RED before production implementation, minimal GREEN, tooling test, five exact Godot regressions, exact allowlist, focused commit, separate independent Sol specification review and Sol quality review. Rejected review requires a focused follow-up commit and rerunning every affected gate.

---

## Reviewed Documentation Preflight (before Task 1)

**Files:**
- `docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md`
- `docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md`

**Consumes:**
- `docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md` (design spec)
- `docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md` (this plan)

**Produces:**
- Commit `docs: add editor playtest safety plan` on feature branch `feature/godot-editor-playtest-safety`
- SDD ledger initialized under ignored `.superpowers/sdd/2026-08-25-godot-editor-playtest-safety/`

- [ ] Independently review the design at `docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md` and this plan for completeness, internal consistency, and adherence to all requirements listed above. Record findings in a temporary review note (not staged).
- [ ] Run the installed SDD workspace script to initialize the ledger:
  ```powershell
  & 'C:\Program Files\Git\bin\bash.exe' 'C:\Users\noisy\.codex\plugins\cache\openai-curated-remote\superpowers\6.3.0\skills\subagent-driven-development\scripts\sdd-workspace' 'docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md'
  ```
- [ ] Run the installed SDD task-brief script for Task 1:
  ```powershell
  & 'C:\Program Files\Git\bin\bash.exe' 'C:\Users\noisy\.codex\plugins\cache\openai-curated-remote\superpowers\6.3.0\skills\subagent-driven-development\scripts\task-brief' 'docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md' 1
  ```
  The ledger is created under the ignored path `.superpowers/sdd/2026-08-25-godot-editor-playtest-safety/` (repository `.sdd` is not used).
- [ ] Run two separate Sol document reviews (specification review and quality review) on the two documentation files before any commit.
- [ ] Before staging, compare the full porcelain output with the exact two-document allowlist:
  ```powershell
  $expectedDocs = @(
      'docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md',
      'docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md'
  ) | Sort-Object
  $porcelain = @(git status --porcelain=v1 -u)
  $actualDocs = @($porcelain | ForEach-Object {
      if ($_.Length -lt 4) { throw "Malformed porcelain entry: $_" }
      $_.Substring(3).Replace('\','/')
  } | Sort-Object)
  if (($actualDocs -join "`n") -ne ($expectedDocs -join "`n")) { exit 1 }
  ```
- [ ] Stage exactly two paths:
  ```powershell
  git add -- docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md
  ```
- [ ] Verify staged set:
  ```powershell
  git diff --cached --name-only
  ```
  Expected exact output (order-insensitive):
  ```
  docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md
  docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md
  ```
- [ ] Commit with exact message:
  ```powershell
  git commit -m "docs: add editor playtest safety plan"
  ```
- [ ] Verify feature worktree is clean (no unstaged, staged, or untracked changes outside the two committed paths):
  ```powershell
  git status --porcelain=v1 -u
  ```
  Expected: empty output.
- [ ] Stop and report evidence on any mismatch (design/plan drift, staging extras, worktree dirt, SDD init failure, review findings).

---

## Task 1: Safety Core + VerifyMirror Mode

**Files:**
- **Create** `godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1`
- **Create** `godot-project-moe-rail-way/tools/playtest/launch_editor_playtest.ps1`

**Interfaces:**

- Consumes:
  - `docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md`
  - `docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md`
  - Repository at `D:\godot\MoeRailWay-worktrees\feature-godot-editor-playtest-safety` (feature worktree)
  - Canonical Godot executable at `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64.exe`
- Produces:
  - Commit `test: add safe editor mirror verification` on feature branch
  - Launcher supporting `VerifyMirror` mode only
  - Tooling test covering preflight, mirror validation, temp root validation, success/cleanup

### Core Function Signatures

```text
function Invoke-NativeText(
    [string]$Executable,
    [string[]]$Arguments,
    [string]$WorkingDirectory
) -> [pscustomobject]@{ ExitCode = [int]; Stdout = [string]; Stderr = [string] }

function Get-GitBlobBytes(
    [string]$GitExecutable,
    [string]$RepositoryRoot,
    [string]$Oid
) -> [byte[]]

function Get-PinnedManifest(
    [string]$GitExecutable,
    [string]$RepositoryRoot,
    [string]$SourceHead
) -> [ordered]@{ [string] = [string] }  # project-relative path -> lowercase SHA-256

function Get-SourceSnapshot(
    [string]$RepositoryRoot,
    [string]$GitExecutable,
    [string]$SourceHead,
    [Collections.IDictionary]$PinnedManifest
) -> [pscustomobject]@{
    Branch = [string]
    Upstream = [string]
    Head = [string]
    Status = [string]
    Hashes = [ordered]@{ [string] = [string] }  # project-relative path -> lowercase SHA-256
}

function Assert-SourceSnapshotUnchanged(
    [pscustomobject]$Before,
    [pscustomobject]$After
) -> [void]

function Assert-ExistingOrdinaryPathChain(
    [string]$Path,
    [string]$Boundary
) -> [string]  # canonical path

function Assert-OwnedRoot(
    [string]$Root,
    [string]$ResolvedTempParent,
    [bool]$RequireExists
) -> [string]  # canonical root

function Remove-OwnedRoot(
    [string]$Root,
    [string]$ResolvedTempParent
) -> [void]

function Compare-MirrorToPinnedManifest(
    [string]$MirrorRoot,
    [ordered]$PinnedManifest
) -> [void]
```

### Implementation Steps

- [ ] **RED** Create test file first: `godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1`
- [ ] **RED** Run test while launcher missing: `pwsh -NoProfile -File godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1`; require nonzero exit and exact output `FAIL: launcher is missing`
- [ ] **GREEN** Create minimal launcher: `godot-project-moe-rail-way/tools/playtest/launch_editor_playtest.ps1` implementing VerifyMirror only
- [ ] **GREEN** Run tooling test; require exit 0 and exact output `PASS: editor playtest tooling tests`
- [ ] **REGRESSION** Run exact five Godot regressions (both markers required per session)
- [ ] **ALLOWLIST** Stage exact two paths; verify `git diff --cached --name-only` matches allowlist
- [ ] **COMMIT** `git commit -m "test: add safe editor mirror verification"`
- [ ] **CLEAN STATUS** Verify empty `git status --porcelain=v1 -u`
- [ ] **SOL SPEC REVIEW** Independent Sol specification review
- [ ] **SOL QUALITY REVIEW** Independent Sol quality review
- [ ] **FOLLOW-UP** Any findings → focused follow-up commit + rerun affected gates
- [ ] **HANDOFF** Run exact `task-brief` command for Task 2

---

### RED: Test File Creation (Actual PowerShell Code)

```powershell
# godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1
#requires -Version 7.4
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

function Get-CanonicalPath {
    param([string]$Path)
    $full = [IO.Path]::GetFullPath($Path)
    $volumeRoot = [IO.Path]::GetPathRoot($full)
    if ($full.Equals($volumeRoot,[StringComparison]::OrdinalIgnoreCase)) { return $volumeRoot }
    return $full.TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
}

function Assert-Equal {
    param([string]$Expected, [string]$Actual, [string]$Message = '')
    if ($Expected -ne $Actual) {
        throw "Assertion failed${Message}: expected '$Expected' but got '$Actual'"
    }
}

function Assert-ExitCode {
    param([int]$Expected, [int]$Actual, [string]$Message = '')
    if ($Expected -ne $Actual) {
        throw "Exit code assertion failed${Message}: expected $Expected but got $Actual"
    }
}

function Assert-OutputContains {
    param([string]$Needle, [string]$Haystack, [string]$Message = '')
    if ($Haystack -notmatch [regex]::Escape($Needle)) {
        throw "Output assertion failed${Message}: expected to contain '$Needle'"
    }
}

function Assert-DirectorySetUnchanged {
    param([string]$TempParent, [string[]]$Before, [string[]]$After, [string]$Message = '')
    $beforeSet = $Before | Sort-Object | ForEach-Object { [IO.Path]::GetFullPath($_) }
    $afterSet = $After | Sort-Object | ForEach-Object { [IO.Path]::GetFullPath($_) }
    if (-not [Linq.Enumerable]::SequenceEqual([string[]]$beforeSet, [string[]]$afterSet)) {
        throw "Directory set changed${Message}: before=$($beforeSet -join ';') after=$($afterSet -join ';')"
    }
}

function Assert-ExistingOrdinaryPathChain {
    param([string]$Path, [string]$Boundary)
    $canonicalPath = Get-CanonicalPath -Path $Path
    $canonicalBoundary = Get-CanonicalPath -Path $Boundary
    $comparison = [StringComparison]::OrdinalIgnoreCase
    $boundaryPrefix = $canonicalBoundary
    if (-not $boundaryPrefix.EndsWith([IO.Path]::DirectorySeparatorChar) -and
        -not $boundaryPrefix.EndsWith([IO.Path]::AltDirectorySeparatorChar)) {
        $boundaryPrefix += [IO.Path]::DirectorySeparatorChar
    }
    if ($canonicalPath -ne $canonicalBoundary -and
        -not $canonicalPath.StartsWith($boundaryPrefix, $comparison)) {
        throw "Path escapes boundary: $canonicalPath"
    }
    if (-not (Test-Path -LiteralPath $canonicalPath)) { throw "Path does not exist: $canonicalPath" }
    $cursor = $canonicalPath
    while ($true) {
        $item = Get-Item -LiteralPath $cursor -Force -ErrorAction Stop
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Reparse point rejected: $cursor"
        }
        if ($cursor.Equals($canonicalBoundary, $comparison)) { break }
        $parent = [IO.Path]::GetDirectoryName($cursor)
        if ([string]::IsNullOrEmpty($parent) -or $parent.Equals($cursor, $comparison)) {
            throw "Boundary was not reached from: $canonicalPath"
        }
        $cursor = Get-CanonicalPath -Path $parent
    }
    return $canonicalPath
}

function Assert-TestOwnedRoot {
    param([string]$Root, [string]$ResolvedTempParent, [bool]$RequireExists)
    $parent = Get-CanonicalPath -Path $ResolvedTempParent
    Assert-ExistingOrdinaryPathChain -Path $parent -Boundary ([IO.Path]::GetPathRoot($parent)) | Out-Null
    $canonicalRoot = Get-CanonicalPath -Path $Root
    if (-not [IO.Path]::GetDirectoryName($canonicalRoot).Equals($parent, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Test root immediate parent mismatch: $canonicalRoot"
    }
    if (-not [IO.Path]::GetFileName($canonicalRoot).StartsWith('moerail-playtest-test-', [StringComparison]::Ordinal)) {
        throw "Test root prefix mismatch: $canonicalRoot"
    }
    $exists = Test-Path -LiteralPath $canonicalRoot
    if ($RequireExists -ne $exists) { throw "Test root existence mismatch: $canonicalRoot" }
    if ($RequireExists) {
        Assert-ExistingOrdinaryPathChain -Path $canonicalRoot -Boundary $parent | Out-Null
        foreach ($item in Get-ChildItem -LiteralPath $canonicalRoot -Recurse -Force -ErrorAction Stop) {
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Test root descendant reparse point rejected: $($item.FullName)"
            }
        }
    }
    return $canonicalRoot
}

function New-TestBareOrigin {
    param([string]$Path)
    if (Test-Path $Path) { throw "Bare origin target already exists: $Path" }
    [IO.Directory]::CreateDirectory($Path) | Out-Null
    & git.exe init --bare --initial-branch=main -- $Path
}

function New-TestClone {
    param([string]$OriginPath, [string]$ClonePath, [string]$UserName, [string]$UserEmail)
    if (Test-Path $ClonePath) { throw "Clone target already exists: $ClonePath" }
    & git.exe clone $OriginPath $ClonePath
    & git.exe -C $ClonePath config user.name $UserName
    & git.exe -C $ClonePath config user.email $UserEmail
    return $ClonePath
}

function Write-ProjectGodot {
    param([string]$ProjectRoot)
    $content = @"
[application]
config/name="MoeRailWay"
run/main_scene="res://scenes/main.tscn"
"@
    [IO.File]::WriteAllText((Join-Path $ProjectRoot 'project.godot'), $content, [Text.Encoding]::UTF8)
}

function Write-BinaryFixture {
    param([string]$ProjectRoot, [string]$RelativePath, [byte[]]$Bytes)
    $full = Join-Path $ProjectRoot $RelativePath
    $dir = [IO.Path]::GetDirectoryName($full)
    if (-not (Test-Path $dir)) { [IO.Directory]::CreateDirectory($dir) | Out-Null }
    [IO.File]::WriteAllBytes($full, $Bytes)
}

function Compile-FakeGodotConsole {
    param([string]$OutputPath)
    $source = @'
using System;
public class FakeGodot {
    public static int Main(string[] args) {
        if (args.Length == 1 && args[0] == "--version") {
            string version = Environment.GetEnvironmentVariable("MOERAIL_FAKE_VERSION");
            Console.WriteLine(String.IsNullOrEmpty(version) ? "4.7.1.stable.official.a13da4feb" : version);
            return 0;
        }
        Console.Error.WriteLine("Usage: FakeGodot --version");
        return 1;
    }
}
'@
    $outputParent = Get-CanonicalPath -Path ([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($OutputPath)))
    Assert-ExistingOrdinaryPathChain -Path $outputParent -Boundary ([IO.Path]::GetPathRoot($outputParent)) | Out-Null
    $buildRoot = Join-Path $outputParent "fake-build-$(New-Guid)"
    if (Test-Path -LiteralPath $buildRoot) { throw "Fake build root already exists: $buildRoot" }
    [IO.Directory]::CreateDirectory($buildRoot) | Out-Null
    $buildItem = Get-Item -LiteralPath $buildRoot -Force -ErrorAction Stop
    if (($buildItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Fake build root is a reparse point: $buildRoot" }
    if (-not [IO.Path]::GetDirectoryName((Get-CanonicalPath -Path $buildRoot)).Equals($outputParent,[StringComparison]::OrdinalIgnoreCase)) { throw 'Fake build parent mismatch' }
    if (-not [IO.Path]::GetFileName($buildRoot).StartsWith('fake-build-',[StringComparison]::Ordinal)) { throw 'Fake build prefix mismatch' }
    $projectFile = Join-Path $buildRoot 'FakeGodot.csproj'
    $sourceFile = Join-Path $buildRoot 'Program.cs'
    $publishDir = Join-Path $buildRoot 'publish'
    $dotnetHome = Join-Path $buildRoot 'dotnet-home'
    $nugetPackages = Join-Path $buildRoot 'nuget-packages'
    $dotnetTemp = Join-Path $buildRoot 'temp'
    $nugetHttpCache = Join-Path $buildRoot 'nuget-http-cache'
    $nugetPluginsCache = Join-Path $buildRoot 'nuget-plugins-cache'
    $nugetScratch = Join-Path $buildRoot 'nuget-scratch'
    foreach ($directory in @($dotnetHome,$nugetPackages,$dotnetTemp,$nugetHttpCache,$nugetPluginsCache,$nugetScratch)) {
        [IO.Directory]::CreateDirectory($directory) | Out-Null
    }
    $nugetConfig = Join-Path $buildRoot 'NuGet.Config'
    $project = @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net9.0</TargetFramework>
    <RuntimeIdentifier>win-x64</RuntimeIdentifier>
    <SelfContained>false</SelfContained>
    <PublishSingleFile>false</PublishSingleFile>
    <DebugType>none</DebugType>
    <DebugSymbols>false</DebugSymbols>
    <AssemblyName>FakeGodot</AssemblyName>
  </PropertyGroup>
</Project>
'@
    [IO.File]::WriteAllText($projectFile,$project,[Text.Encoding]::UTF8)
    [IO.File]::WriteAllText($sourceFile,$source,[Text.Encoding]::UTF8)
    $nugetConfiguration = @'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
  </packageSources>
</configuration>
'@
    [IO.File]::WriteAllText($nugetConfig,$nugetConfiguration,[Text.Encoding]::UTF8)

    $assertBuildTree = {
        Assert-ExistingOrdinaryPathChain -Path $buildRoot -Boundary $outputParent | Out-Null
        foreach ($entry in Get-ChildItem -LiteralPath $buildRoot -Recurse -Force -ErrorAction Stop) {
            if (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Fake build reparse point: $($entry.FullName)"
            }
        }
    }

    $dotnetExe = (Get-Command dotnet.exe -ErrorAction Stop).Source
    $invokeDotnet = {
        param([string[]]$Arguments)
        $psi = [Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = $dotnetExe
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.WorkingDirectory = $buildRoot
        foreach ($entry in @{
            DOTNET_CLI_HOME=$dotnetHome; NUGET_PACKAGES=$nugetPackages; TEMP=$dotnetTemp; TMP=$dotnetTemp;
            NUGET_HTTP_CACHE_PATH=$nugetHttpCache; NUGET_PLUGINS_CACHE_PATH=$nugetPluginsCache; NUGET_SCRATCH=$nugetScratch;
            DOTNET_SKIP_FIRST_TIME_EXPERIENCE='1'; DOTNET_CLI_TELEMETRY_OPTOUT='1'; DOTNET_NOLOGO='1'
        }.GetEnumerator()) { $psi.Environment[$entry.Key] = [string]$entry.Value }
        foreach ($argument in $Arguments) { $psi.ArgumentList.Add($argument) }
        $process = [Diagnostics.Process]::Start($psi)
        try {
            $stdoutTask = $process.StandardOutput.ReadToEndAsync()
            $stderrTask = $process.StandardError.ReadToEndAsync()
            $process.WaitForExit()
            $stdoutTask.Wait()
            $stderrTask.Wait()
            return [pscustomobject]@{ ExitCode=$process.ExitCode; Stdout=$stdoutTask.Result; Stderr=$stderrTask.Result }
        }
        finally {
            $process.Dispose()
        }
    }

    & $assertBuildTree
    $versionResult = & $invokeDotnet -Arguments @('--version')
    if ($versionResult.ExitCode -ne 0 -or $versionResult.Stdout.Trim() -ne '9.0.100') {
        throw "dotnet SDK mismatch: $($versionResult.Stdout) $($versionResult.Stderr)"
    }
    $restoreResult = & $invokeDotnet -Arguments @(
        'restore',$projectFile,'--configfile',$nugetConfig,'--no-http-cache'
    )
    if ($restoreResult.ExitCode -ne 0) { throw "dotnet restore failed: $($restoreResult.Stdout) $($restoreResult.Stderr)" }
    & $assertBuildTree
    $publishResult = & $invokeDotnet -Arguments @(
        'publish',$projectFile,'-c','Release','-r','win-x64','--self-contained','false','--no-restore',
        '-p:PublishSingleFile=false','-p:DebugType=none','-p:DebugSymbols=false','-o',$publishDir
    )
    if ($publishResult.ExitCode -ne 0) { throw "dotnet publish failed: $($publishResult.Stdout) $($publishResult.Stderr)" }
    & $assertBuildTree
    if (-not [IO.Path]::GetFileName($OutputPath).Equals('FakeGodot.exe',[StringComparison]::OrdinalIgnoreCase)) {
        throw "Fake output name mismatch: $OutputPath"
    }
    $requiredPublishedNames = @(
        'FakeGodot.exe',
        'FakeGodot.dll',
        'FakeGodot.deps.json',
        'FakeGodot.runtimeconfig.json'
    )
    $allowedPublishedNames = @($requiredPublishedNames) + @('FakeGodot.pdb')
    $publishedEntries = @(Get-ChildItem -LiteralPath $publishDir -Force -ErrorAction Stop)
    $actualPublishedNames = @($publishedEntries | ForEach-Object { $_.Name })
    foreach ($requiredName in $requiredPublishedNames) {
        if ($requiredName -notin $actualPublishedNames) { throw "Missing published file: $requiredName" }
    }
    # Validate the complete set and every destination before moving any file.
    foreach ($entry in $publishedEntries) {
        if ($entry.PSIsContainer) { throw "Published directory is prohibited: $($entry.FullName)" }
        if (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Published reparse point is prohibited: $($entry.FullName)"
        }
        if ($entry.Name -notin $allowedPublishedNames) { throw "Unexpected published file: $($entry.Name)" }
        $destination = Join-Path $outputParent $entry.Name
        if (Test-Path -LiteralPath $destination) { throw "Fake output collision: $destination" }
    }
    foreach ($entry in $publishedEntries) {
        $destination = Join-Path $outputParent $entry.Name
        Move-Item -LiteralPath $entry.FullName -Destination $destination -ErrorAction Stop
    }
    foreach ($publishedName in $actualPublishedNames) {
        $destination = Join-Path $outputParent $publishedName
        $destinationItem = Get-Item -LiteralPath $destination -Force -ErrorAction Stop
        if ($destinationItem.PSIsContainer) { throw "Fake output is not a leaf: $destination" }
        if (($destinationItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Fake output reparse point: $destination"
        }
    }
    $outputItem = Get-Item -LiteralPath $OutputPath -Force -ErrorAction Stop
    if ($outputItem.PSIsContainer -or ($outputItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Fake output is not an ordinary leaf: $OutputPath"
    }
    # Build intermediates intentionally remain inside the validated test-owned
    # root and are removed only by the final revalidated root cleanup.
}

function Invoke-Launcher {
    param(
        [string]$LauncherPath,
        [string]$RepositoryRoot,
        [string]$GodotExecutable,
        [string]$GitExecutable,
        [string]$TarExecutable,
        [string]$Mode = 'VerifyMirror',
        [string]$TempParent,
        [Collections.IDictionary]$EnvOverrides = @{}
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'pwsh.exe'
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.ArgumentList.Add('-NoProfile')
    $psi.ArgumentList.Add('-File')
    $psi.ArgumentList.Add($LauncherPath)
    $psi.ArgumentList.Add('-RepositoryRoot')
    $psi.ArgumentList.Add($RepositoryRoot)
    $psi.ArgumentList.Add('-GodotExecutable')
    $psi.ArgumentList.Add($GodotExecutable)
    $psi.ArgumentList.Add('-GitExecutable')
    $psi.ArgumentList.Add($GitExecutable)
    $psi.ArgumentList.Add('-TarExecutable')
    $psi.ArgumentList.Add($TarExecutable)
    $psi.ArgumentList.Add('-Mode')
    $psi.ArgumentList.Add($Mode)
    if ($TempParent) {
        $psi.ArgumentList.Add('-TempParent')
        $psi.ArgumentList.Add($TempParent)
    }
    foreach ($kv in $EnvOverrides.GetEnumerator()) {
        $psi.Environment[$kv.Key] = $kv.Value
    }
    $proc = [System.Diagnostics.Process]::Start($psi)
    try {
        $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
        $stderrTask = $proc.StandardError.ReadToEndAsync()
        $proc.WaitForExit()
        $stdoutTask.Wait()
        $stderrTask.Wait()
        return [pscustomobject]@{
            ExitCode = $proc.ExitCode
            Stdout = $stdoutTask.Result
            Stderr = $stderrTask.Result
        }
    }
    finally {
        $proc.Dispose()
    }
}

function Get-MoerailDirs {
    param([string]$TempParent)
    if (-not (Test-Path $TempParent)) { return @() }
    return Get-ChildItem -LiteralPath $TempParent -Directory -Filter 'moerail-editor-playtest-*' -ErrorAction Stop |
        ForEach-Object { $_.FullName } | Sort-Object
}

function Get-FixtureSnapshot {
    param([string]$RepositoryRoot)
    $branch = (& git.exe -C $RepositoryRoot symbolic-ref --short HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Fixture branch query failed' }
    $upstream = (& git.exe -C $RepositoryRoot rev-parse --abbrev-ref --symbolic-full-name '@{u}').Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Fixture upstream query failed' }
    $head = (& git.exe -C $RepositoryRoot rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Fixture HEAD query failed' }
    $status = (& git.exe -C $RepositoryRoot status --porcelain=v1 -u) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw 'Fixture status query failed' }
    $hashes = [ordered]@{}
    $tracked = & git.exe -C $RepositoryRoot ls-tree -r --name-only HEAD -- 'godot-project-moe-rail-way/'
    if ($LASTEXITCODE -ne 0) { throw 'Fixture tracked path query failed' }
    foreach ($relative in $tracked) {
        $full = Join-Path $RepositoryRoot $relative
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "Fixture tracked file missing: $relative" }
        $hashes[$relative.Replace('\','/')] = (Get-FileHash -LiteralPath $full -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
    }
    return [pscustomobject]@{ Branch=$branch; Upstream=$upstream; Head=$head; Status=$status; Hashes=$hashes }
}

function Assert-FixtureSnapshotUnchanged {
    param([pscustomobject]$Before, [pscustomobject]$After)
    foreach ($property in @('Branch','Upstream','Head','Status')) {
        if ($Before.$property -ne $After.$property) { throw "Fixture $property changed" }
    }
    $beforeKeys = @($Before.Hashes.Keys | Sort-Object)
    $afterKeys = @($After.Hashes.Keys | Sort-Object)
    if (($beforeKeys -join "`n") -ne ($afterKeys -join "`n")) { throw 'Fixture tracked path set changed' }
    foreach ($key in $beforeKeys) {
        if ($Before.Hashes[$key] -ne $After.Hashes[$key]) { throw "Fixture bytes changed: $key" }
    }
}

# ===== TEST CASES =====

$launcherPath = Join-Path $PSScriptRoot '..\..\tools\playtest\launch_editor_playtest.ps1'
if (-not (Test-Path -LiteralPath $launcherPath -PathType Leaf)) {
    Write-Host 'FAIL: launcher is missing'
    exit 1
}

$systemTempParent = Get-CanonicalPath -Path ([IO.Path]::GetTempPath())
Assert-ExistingOrdinaryPathChain -Path $systemTempParent -Boundary ([IO.Path]::GetPathRoot($systemTempParent)) | Out-Null
$testTempParent = Join-Path $systemTempParent "moerail-playtest-test-$(New-Guid)"
Assert-TestOwnedRoot -Root $testTempParent -ResolvedTempParent $systemTempParent -RequireExists $false | Out-Null
[IO.Directory]::CreateDirectory($testTempParent) | Out-Null
Assert-TestOwnedRoot -Root $testTempParent -ResolvedTempParent $systemTempParent -RequireExists $true | Out-Null
$bareOrigin = Join-Path $testTempParent 'origin.git'
$cloneRoot = Join-Path $testTempParent 'clone'
$fakeGodotDir = Join-Path $testTempParent 'fake-godot'
$fakeGodotExe = Join-Path $fakeGodotDir 'FakeGodot.exe'

# Setup: compile fake godot once
[IO.Directory]::CreateDirectory($fakeGodotDir) | Out-Null
Compile-FakeGodotConsole -OutputPath $fakeGodotExe

# Setup: bare origin + clone + initial commit
New-TestBareOrigin -Path $bareOrigin
New-TestClone -OriginPath $bareOrigin -ClonePath $cloneRoot -UserName 'Test User' -UserEmail 'test@example.com'
$projectRoot = Join-Path $cloneRoot 'godot-project-moe-rail-way'
[IO.Directory]::CreateDirectory($projectRoot) | Out-Null
Write-ProjectGodot -ProjectRoot $projectRoot
Write-BinaryFixture -ProjectRoot $projectRoot -RelativePath 'assets/test.bin' -Bytes @(0x01,0x02,0x03,0x04)
& git.exe -C $cloneRoot add --all
& git.exe -C $cloneRoot commit -m 'Initial commit'
& git.exe -C $cloneRoot push -u origin main

# Helper to capture moerail dirs before/after
function CaptureMoerailDirs { return Get-MoerailDirs -TempParent $testTempParent }

# ---- CASE 1: Wrong version -> exit 2, no root ----
$dirsBefore = CaptureMoerailDirs
$result = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TarExecutable (Get-Command tar.exe).Source -TempParent $testTempParent -EnvOverrides @{ MOERAIL_FAKE_VERSION = '4.7.2.stable.steam.ed1daf0bf' }
$dirsAfter = CaptureMoerailDirs
Assert-ExitCode -Expected 2 -Actual $result.ExitCode -Message ' (wrong version)'
Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $dirsBefore -After $dirsAfter -Message ' (wrong version)'

# ---- CASE 2: Feature branch -> exit 2, no root ----
& git.exe -C $cloneRoot checkout -b feature-branch
$dirsBefore = CaptureMoerailDirs
$result = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TarExecutable (Get-Command tar.exe).Source -TempParent $testTempParent
$dirsAfter = CaptureMoerailDirs
Assert-ExitCode -Expected 2 -Actual $result.ExitCode -Message ' (feature branch)'
Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $dirsBefore -After $dirsAfter -Message ' (feature branch)'
& git.exe -C $cloneRoot checkout main
& git.exe -C $cloneRoot branch -D feature-branch

# ---- CASE 3: Dirty tracked + untracked -> exit 2, no root ----
Write-BinaryFixture -ProjectRoot $projectRoot -RelativePath 'assets/test.bin' -Bytes @(0xFF)
[IO.File]::WriteAllText((Join-Path $projectRoot 'untracked.txt'), 'untracked', [Text.Encoding]::UTF8)
$dirsBefore = CaptureMoerailDirs
$result = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TarExecutable (Get-Command tar.exe).Source -TempParent $testTempParent
$dirsAfter = CaptureMoerailDirs
Assert-ExitCode -Expected 2 -Actual $result.ExitCode -Message ' (dirty)'
Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $dirsBefore -After $dirsAfter -Message ' (dirty)'
& git.exe -C $cloneRoot checkout -- .
if ($LASTEXITCODE -ne 0) { throw 'Fixture tracked reset failed' }
Remove-Item -LiteralPath (Join-Path $projectRoot 'untracked.txt') -Force -ErrorAction Stop

# ---- CASE 4: Local-ahead divergence -> exit 2, no root ----
Write-BinaryFixture -ProjectRoot $projectRoot -RelativePath 'assets/ahead.bin' -Bytes @(0xAA)
& git.exe -C $cloneRoot add --all
& git.exe -C $cloneRoot commit -m 'Local ahead commit'
$dirsBefore = CaptureMoerailDirs
$result = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TarExecutable (Get-Command tar.exe).Source -TempParent $testTempParent
$dirsAfter = CaptureMoerailDirs
Assert-ExitCode -Expected 2 -Actual $result.ExitCode -Message ' (local ahead)'
Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $dirsBefore -After $dirsAfter -Message ' (local ahead)'
& git.exe -C $cloneRoot reset --hard HEAD~1
if ($LASTEXITCODE -ne 0) { throw 'Fixture local-ahead reset failed' }

# ---- CASE 5: TempParent junction -> exit 2, no root ----
$junctionParent = Join-Path $testTempParent 'junction-parent'
$junctionTarget = Join-Path $testTempParent 'junction-target'
[IO.Directory]::CreateDirectory($junctionTarget) | Out-Null
New-Item -ItemType Junction -Path $junctionParent -Target $junctionTarget -ErrorAction Stop | Out-Null
$dirsBefore = CaptureMoerailDirs
$result = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TarExecutable (Get-Command tar.exe).Source -TempParent $junctionParent
$dirsAfter = CaptureMoerailDirs
Assert-ExitCode -Expected 2 -Actual $result.ExitCode -Message ' (junction temp parent)'
Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $dirsBefore -After $dirsAfter -Message ' (junction temp parent)'
Remove-Item -LiteralPath $junctionParent -Force -ErrorAction Stop
Remove-Item -LiteralPath $junctionTarget -Recurse -Force -ErrorAction Stop

# ---- CASE 6: Success -> exit 0, marker, source invariants, cleanup ----
$fixtureBefore = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
$dirsBefore = CaptureMoerailDirs
$result = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TarExecutable (Get-Command tar.exe).Source -TempParent $testTempParent
$dirsAfter = CaptureMoerailDirs
Assert-ExitCode -Expected 0 -Actual $result.ExitCode -Message ' (success)'
Assert-OutputContains -Needle 'PASS: editor playtest mirror verified' -Haystack $result.Stdout -Message ' (success marker)'
Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $dirsBefore -After $dirsAfter -Message ' (success cleanup)'
$fixtureAfter = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
Assert-FixtureSnapshotUnchanged -Before $fixtureBefore -After $fixtureAfter

Assert-TestOwnedRoot -Root $testTempParent -ResolvedTempParent $systemTempParent -RequireExists $true | Out-Null
Remove-Item -LiteralPath $testTempParent -Recurse -Force -ErrorAction Stop
if (Test-Path -LiteralPath $testTempParent) { throw "Test temp parent still exists after cleanup: $testTempParent" }
Write-Host 'PASS: editor playtest tooling tests'
```

---

### GREEN: Launcher Implementation (Actual PowerShell Code)

```powershell
# godot-project-moe-rail-way/tools/playtest/launch_editor_playtest.ps1
#requires -Version 7.4
param(
    [string]$RepositoryRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))),
    [string]$GodotExecutable = "D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64.exe",
    [string]$GitExecutable,
    [string]$TarExecutable,
    [ValidateSet('VerifyMirror')]
    [string]$Mode = 'VerifyMirror',
    [string]$TempParent = $null
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

function Get-CanonicalPath {
    param([string]$Path)
    $full = [IO.Path]::GetFullPath($Path)
    $volumeRoot = [IO.Path]::GetPathRoot($full)
    if ($full.Equals($volumeRoot,[StringComparison]::OrdinalIgnoreCase)) { return $volumeRoot }
    return $full.TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
}

# Resolve GitExecutable and TarExecutable with controlled preflight
try {
    if ($null -eq $GitExecutable) { $GitExecutable = (Get-Command git.exe -ErrorAction Stop).Source }
    if ($null -eq $TarExecutable) { $TarExecutable = (Get-Command tar.exe -ErrorAction Stop).Source }
}
catch {
    [Console]::Error.WriteLine("Preflight failed: required tool not found - $($_.Exception.Message)")
    exit 2
}

function Invoke-NativeText {
    param(
        [string]$Executable,
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Executable
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.WorkingDirectory = $WorkingDirectory
    foreach ($arg in $Arguments) {
        $psi.ArgumentList.Add($arg)
    }
    $proc = [System.Diagnostics.Process]::Start($psi)
    try {
        $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
        $stderrTask = $proc.StandardError.ReadToEndAsync()
        $proc.WaitForExit()
        $stdoutTask.Wait()
        $stderrTask.Wait()
        return [pscustomobject]@{
            ExitCode = $proc.ExitCode
            Stdout = $stdoutTask.Result
            Stderr = $stderrTask.Result
        }
    }
    finally {
        $proc.Dispose()
    }
}

function Get-GitBlobBytes {
    param(
        [string]$GitExecutable,
        [string]$RepositoryRoot,
        [string]$Oid
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $GitExecutable
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.WorkingDirectory = $RepositoryRoot
    $psi.ArgumentList.Add('cat-file')
    $psi.ArgumentList.Add('blob')
    $psi.ArgumentList.Add($Oid)
    $proc = [System.Diagnostics.Process]::Start($psi)
    $ms = [IO.MemoryStream]::new()
    try {
        $stderrTask = $proc.StandardError.ReadToEndAsync()
        $copyTask = $proc.StandardOutput.BaseStream.CopyToAsync($ms)
        $proc.WaitForExit()
        $copyTask.Wait()
        $stderrTask.Wait()
        if ($proc.ExitCode -ne 0) { throw "git cat-file blob $Oid failed: $($stderrTask.Result)" }
        return $ms.ToArray()
    }
    finally {
        $ms.Dispose()
        $proc.Dispose()
    }
}

function Get-Sha256Hex {
    param([byte[]]$Bytes)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return [BitConverter]::ToString($sha256.ComputeHash($Bytes)).Replace('-','').ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

function Get-PinnedManifest {
    param(
        [string]$GitExecutable,
        [string]$RepositoryRoot,
        [string]$SourceHead
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $GitExecutable
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.WorkingDirectory = $RepositoryRoot
    $psi.ArgumentList.Add('ls-tree')
    $psi.ArgumentList.Add('-r')
    $psi.ArgumentList.Add('--full-tree')
    $psi.ArgumentList.Add($SourceHead)
    $psi.ArgumentList.Add('--')
    $psi.ArgumentList.Add('godot-project-moe-rail-way/')
    $proc = [System.Diagnostics.Process]::Start($psi)
    try {
        $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
        $stderrTask = $proc.StandardError.ReadToEndAsync()
        $proc.WaitForExit()
        $stdoutTask.Wait()
        $stderrTask.Wait()
        if ($proc.ExitCode -ne 0) { throw "git ls-tree failed: $($stderrTask.Result)" }
        $treeText = $stdoutTask.Result
    }
    finally {
        $proc.Dispose()
    }
    $lines = $treeText -split "`r?`n" | Where-Object { $_ -ne '' }
    if ($lines.Count -eq 0) {
        throw "Pinned manifest empty: no tracked files under godot-project-moe-rail-way/"
    }
    $manifest = [ordered]@{}
    $seen = @{}
    foreach ($line in $lines) {
        $parts = $line -split "`t", 2
        if ($parts.Count -ne 2) { throw "Malformed ls-tree line: $line" }
        $meta = $parts[0]
        $path = $parts[1]
        $metaParts = $meta -split ' '
        if ($metaParts.Count -ne 3) { throw "Malformed ls-tree meta: $meta" }
        $mode = $metaParts[0]
        $type = $metaParts[1]
        $oid = $metaParts[2]
        if ($type -ne 'blob') { throw "Non-blob entry in manifest: $path (type=$type)" }
        if ($mode -ne '100644' -and $mode -ne '100755') { throw "Invalid mode $mode for $path" }
        if ($path -match '(^|/)\.git($|/)|(^|/)\.godot($|/)') { throw "Forbidden component in path: $path" }
        if ($path -match '[\r\n\t]') { throw "Path contains CR/LF/TAB: $path" }
        if ($path -match '^[\/\\]|^\.\.\\|/\.\./|\\\.\.\\') { throw "Rooted or escape path: $path" }
        if ($seen.ContainsKey($path)) { throw "Duplicate path in manifest: $path" }
        $seen[$path] = $true
        if (-not $path.StartsWith('godot-project-moe-rail-way/')) { throw "Path missing expected prefix: $path" }
        $relPath = $path.Substring('godot-project-moe-rail-way/'.Length)
        $bytes = Get-GitBlobBytes -GitExecutable $GitExecutable -RepositoryRoot $RepositoryRoot -Oid $oid
        $hash = Get-Sha256Hex -Bytes $bytes
        $manifest[$relPath] = $hash
    }
    return $manifest
}

function Get-SourceSnapshot {
    param(
        [string]$RepositoryRoot,
        [string]$GitExecutable,
        [string]$SourceHead,
        [Collections.IDictionary]$PinnedManifest
    )
    $branch = (& $GitExecutable -C $RepositoryRoot symbolic-ref --short HEAD).Trim()
    $upstream = (& $GitExecutable -C $RepositoryRoot rev-parse --abbrev-ref --symbolic-full-name '@{u}').Trim()
    $head = (& $GitExecutable -C $RepositoryRoot rev-parse HEAD).Trim()
    $status = (@(& $GitExecutable -C $RepositoryRoot status --porcelain=v1 -u) -join "`n")
    if ($branch -ne 'main') { throw "Snapshot branch drifted: $branch" }
    if ($upstream -ne 'origin/main') { throw "Snapshot upstream drifted: $upstream" }
    if ($head -ne $SourceHead) { throw "Snapshot HEAD drifted: expected $SourceHead got $head" }
    if ($status -ne '') { throw "Snapshot status is dirty: $status" }
    $projectRoot = Join-Path $RepositoryRoot 'godot-project-moe-rail-way'
    $hashes = [ordered]@{}
    foreach ($relPath in $PinnedManifest.Keys) {
        $fullPath = Join-Path $projectRoot $relPath
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            throw "Pinned path missing in working tree: $relPath"
        }
        $canonical = Assert-ExistingOrdinaryPathChain -Path $fullPath -Boundary $projectRoot
        $bytes = [IO.File]::ReadAllBytes($canonical)
        $hash = Get-Sha256Hex -Bytes $bytes
        $hashes[$relPath] = $hash
    }
    return [pscustomobject]@{
        Branch = $branch
        Upstream = $upstream
        Head = $head
        Status = $status
        Hashes = $hashes
    }
}

function Assert-SourceSnapshotUnchanged {
    param(
        [pscustomobject]$Before,
        [pscustomobject]$After
    )
    if ($Before.Branch -ne $After.Branch) { throw "Branch changed: $($Before.Branch) -> $($After.Branch)" }
    if ($Before.Upstream -ne $After.Upstream) { throw "Upstream changed: $($Before.Upstream) -> $($After.Upstream)" }
    if ($Before.Head -ne $After.Head) { throw "HEAD changed: $($Before.Head) -> $($After.Head)" }
    if ($Before.Status -ne $After.Status) { throw "Status changed" }
    $beforeKeys = $Before.Hashes.Keys | Sort-Object
    $afterKeys = $After.Hashes.Keys | Sort-Object
    if (-not [Linq.Enumerable]::SequenceEqual([string[]]$beforeKeys, [string[]]$afterKeys)) { throw "Tracked file set changed" }
    foreach ($key in $beforeKeys) {
        if ($Before.Hashes[$key] -ne $After.Hashes[$key]) { throw "Hash changed for ${key}: $($Before.Hashes[$key]) -> $($After.Hashes[$key])" }
    }
}

function Assert-ExistingOrdinaryPathChain {
    param(
        [string]$Path,
        [string]$Boundary
    )
    $canonicalPath = Get-CanonicalPath -Path $Path
    $canonicalBoundary = Get-CanonicalPath -Path $Boundary
    $comparison = [StringComparison]::OrdinalIgnoreCase
    $boundaryPrefix = $canonicalBoundary
    if (-not $boundaryPrefix.EndsWith([IO.Path]::DirectorySeparatorChar) -and
        -not $boundaryPrefix.EndsWith([IO.Path]::AltDirectorySeparatorChar)) {
        $boundaryPrefix += [IO.Path]::DirectorySeparatorChar
    }
    if ($canonicalPath -ne $canonicalBoundary -and
        -not $canonicalPath.StartsWith($boundaryPrefix, $comparison)) {
        throw "Path escapes boundary: $canonicalPath not under $canonicalBoundary"
    }
    if (-not (Test-Path -LiteralPath $canonicalPath)) { throw "Path missing: $canonicalPath" }
    $current = $canonicalPath
    while ($true) {
        $attrs = [IO.File]::GetAttributes($current)
        if ($attrs.HasFlag([IO.FileAttributes]::ReparsePoint)) {
            throw "ReparsePoint in path chain: $current"
        }
        if ($current.Equals($canonicalBoundary, $comparison)) { break }
        $parent = [IO.Path]::GetDirectoryName($current)
        if ([string]::IsNullOrEmpty($parent) -or $parent.Equals($current, $comparison)) {
            throw "Boundary was not reached from: $canonicalPath"
        }
        $current = Get-CanonicalPath -Path $parent
    }
    return $canonicalPath
}

function Assert-OwnedRoot {
    param(
        [string]$Root,
        [string]$ResolvedTempParent,
        [bool]$RequireExists
    )
    $canonicalRoot = Get-CanonicalPath -Path $Root
    $canonicalTempParent = Get-CanonicalPath -Path $ResolvedTempParent
    if (-not [IO.Path]::GetDirectoryName($canonicalRoot).Equals($canonicalTempParent, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Root immediate parent mismatch: $canonicalRoot"
    }
    $leaf = [IO.Path]::GetFileName($canonicalRoot)
    if (-not $leaf.StartsWith('moerail-editor-playtest-', [StringComparison]::Ordinal)) { throw "Root leaf prefix mismatch: $leaf" }
    $exists = Test-Path -LiteralPath $canonicalRoot
    if ($RequireExists -ne $exists) { throw "Root existence mismatch: $canonicalRoot" }
    if ($RequireExists) {
        if (-not (Test-Path -LiteralPath $canonicalRoot -PathType Container)) { throw "Root is not a directory: $canonicalRoot" }
        Assert-ExistingOrdinaryPathChain -Path $canonicalRoot -Boundary $canonicalTempParent | Out-Null
        $dirs = @($canonicalRoot)
        $idx = 0
        while ($idx -lt $dirs.Count) {
            $dir = $dirs[$idx]
            $attrs = [IO.File]::GetAttributes($dir)
            if ($attrs.HasFlag([IO.FileAttributes]::ReparsePoint)) {
                throw "ReparsePoint in owned root tree: $dir"
            }
            try {
                $children = [IO.Directory]::GetFileSystemEntries($dir)
                foreach ($child in $children) {
                    $childAttrs = [IO.File]::GetAttributes($child)
                    if ($childAttrs.HasFlag([IO.FileAttributes]::ReparsePoint)) {
                        throw "ReparsePoint in owned root tree: $child"
                    }
                    if ($childAttrs.HasFlag([IO.FileAttributes]::Directory)) {
                        $dirs += $child
                    }
                }
            }
            catch {
                throw "Failed to enumerate ${dir}: $($_.Exception.Message)"
            }
            $idx++
        }
    }
    return $canonicalRoot
}

function Remove-OwnedRoot {
    param(
        [string]$Root,
        [string]$ResolvedTempParent
    )
    $canonicalRoot = Assert-OwnedRoot -Root $Root -ResolvedTempParent $ResolvedTempParent -RequireExists $true
    Remove-Item -LiteralPath $canonicalRoot -Recurse -Force -ErrorAction Stop
    if (Test-Path -LiteralPath $canonicalRoot) {
        throw "Root still exists after removal: $canonicalRoot"
    }
}

function Compare-MirrorToPinnedManifest {
    param(
        [string]$MirrorRoot,
        [Collections.IDictionary]$PinnedManifest
    )
    $mirrorFiles = @{}
    $dirs = @($MirrorRoot)
    $idx = 0
    while ($idx -lt $dirs.Count) {
        $dir = $dirs[$idx]
        $attrs = [IO.File]::GetAttributes($dir)
        if ($attrs.HasFlag([IO.FileAttributes]::ReparsePoint)) {
            throw "ReparsePoint in mirror: $dir"
        }
        try {
            $children = [IO.Directory]::GetFileSystemEntries($dir)
            foreach ($child in $children) {
                $childAttrs = [IO.File]::GetAttributes($child)
                if ($childAttrs.HasFlag([IO.FileAttributes]::ReparsePoint)) {
                    throw "ReparsePoint in mirror: $child"
                }
                if ($childAttrs.HasFlag([IO.FileAttributes]::Directory)) {
                    $dirs += $child
                }
                else {
                    $rel = $child.Substring($MirrorRoot.Length + 1).Replace('\','/')
                    if ($mirrorFiles.ContainsKey($rel)) { throw "Duplicate mirror path after separator normalization: $rel" }
                    $mirrorFiles[$rel] = $child
                }
            }
        }
        catch {
            throw "Failed to enumerate mirror ${dir}: $($_.Exception.Message)"
        }
        $idx++
    }
    $pinnedKeys = $PinnedManifest.Keys | Sort-Object
    $mirrorKeys = $mirrorFiles.Keys | Sort-Object
    if (-not [Linq.Enumerable]::SequenceEqual([string[]]$pinnedKeys, [string[]]$mirrorKeys)) {
        throw "Mirror file set mismatch. Pinned: $($pinnedKeys -join ',') Mirror: $($mirrorKeys -join ',')"
    }
    foreach ($key in $pinnedKeys) {
        $bytes = [IO.File]::ReadAllBytes($mirrorFiles[$key])
        $hash = Get-Sha256Hex -Bytes $bytes
        if ($hash -ne $PinnedManifest[$key]) {
            throw "Hash mismatch for ${key}: expected $($PinnedManifest[$key]) got $hash"
        }
    }
}

# ===== MAIN EXECUTION =====

# PRE-ROOT PHASE: every failure is controlled exit 2 and no temp root exists.
$Root = $null
try {
# 1. Resolve RepositoryRoot, tools, exact Godot version
$RepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot)
if ($null -eq $TempParent) { $TempParent = [IO.Path]::GetTempPath() }
$TempParent = Get-CanonicalPath -Path $TempParent

# Validate Godot version
if (-not (Test-Path -LiteralPath $GodotExecutable -PathType Leaf)) { throw 'Godot executable missing' }
$versionResult = Invoke-NativeText -Executable $GodotExecutable -Arguments @('--version') -WorkingDirectory $RepositoryRoot
if ($versionResult.ExitCode -ne 0) {
    throw "Godot version check failed: $($versionResult.Stderr)"
}
$firstLine = ($versionResult.Stdout -split "`r?`n" | Where-Object { $_ -ne '' })[0].Trim()
if ($firstLine -ne '4.7.1.stable.official.a13da4feb') {
    throw "Godot version mismatch: expected '4.7.1.stable.official.a13da4feb' got '$firstLine'"
}

# 2. Require normal worktree, branch main, upstream origin/main, divergence 0/0, empty porcelain
$isWorktree = & $GitExecutable -C $RepositoryRoot rev-parse --is-inside-work-tree
if ($isWorktree.Trim() -ne 'true') { throw 'Not a worktree' }
$branch = & $GitExecutable -C $RepositoryRoot symbolic-ref --short HEAD
if ($branch.Trim() -ne 'main') { throw "Branch is not main: $branch" }
$upstream = & $GitExecutable -C $RepositoryRoot rev-parse --abbrev-ref --symbolic-full-name '@{u}'
if ($upstream.Trim() -ne 'origin/main') { throw "Upstream is not origin/main: $upstream" }
$divergence = & $GitExecutable -C $RepositoryRoot rev-list --left-right --count '@{u}...HEAD'
if ($divergence.Trim() -ne "0`t0") { throw "Divergence not 0/0: $divergence" }
$status = @(& $GitExecutable -C $RepositoryRoot status --porcelain=v1 -u)
if ($status.Count -ne 0) { throw "Working tree not clean: $($status -join '; ')" }
$projectPath = Join-Path $RepositoryRoot 'godot-project-moe-rail-way'
if (-not (Test-Path -LiteralPath $projectPath -PathType Container)) { throw 'Project path missing' }

# 3. Pin SourceHead
$SourceHead = & $GitExecutable -C $RepositoryRoot rev-parse HEAD

# 4. Build PinnedManifest from HEAD blobs
$PinnedManifest = Get-PinnedManifest -GitExecutable $GitExecutable -RepositoryRoot $RepositoryRoot -SourceHead $SourceHead

# 5. Build SourceSnapshotBefore from actual working-tree bytes
$SnapshotBefore = Get-SourceSnapshot -RepositoryRoot $RepositoryRoot -GitExecutable $GitExecutable -SourceHead $SourceHead -PinnedManifest $PinnedManifest

# 6. Resolve TempParent and validate its entire existing path chain non-reparse; capture pre-root directory set
Assert-ExistingOrdinaryPathChain -Path $TempParent -Boundary ([IO.Path]::GetPathRoot($TempParent)) | Out-Null
$preRootDirs = @()
if (Test-Path $TempParent) {
    $preRootDirs = Get-ChildItem -LiteralPath $TempParent -Directory -Filter 'moerail-editor-playtest-*' -ErrorAction Stop | ForEach-Object { $_.FullName }
}

# Create unique Root
$Root = Join-Path $TempParent "moerail-editor-playtest-$(New-Guid)"
Assert-OwnedRoot -Root $Root -ResolvedTempParent $TempParent -RequireExists $false | Out-Null
}
catch {
    [Console]::Error.WriteLine("Preflight failed: $($_.Exception.Message)")
    exit 2
}

# POST-ROOT PHASE: any materialized root/remnants are preserved and reported.
try {
[IO.Directory]::CreateDirectory($Root) | Out-Null
Assert-OwnedRoot -Root $Root -ResolvedTempParent $TempParent -RequireExists $true | Out-Null
$projectMirror = Join-Path $Root 'project'
$envAppData = Join-Path $Root 'environment\appdata'
$envLocalAppData = Join-Path $Root 'environment\localappdata'
$envTemp = Join-Path $Root 'environment\temp'
$logsDir = Join-Path $Root 'logs'
[IO.Directory]::CreateDirectory($projectMirror) | Out-Null
[IO.Directory]::CreateDirectory($envAppData) | Out-Null
[IO.Directory]::CreateDirectory($envLocalAppData) | Out-Null
[IO.Directory]::CreateDirectory($envTemp) | Out-Null
[IO.Directory]::CreateDirectory($logsDir) | Out-Null

# Revalidate again after creating every initial descendant.
Assert-OwnedRoot -Root $Root -ResolvedTempParent $TempParent -RequireExists $true | Out-Null

    # Archive
    $archivePath = Join-Path $Root 'mirror.tar'
    $archiveResult = Invoke-NativeText -Executable $GitExecutable -Arguments @('archive', '--format=tar', "--output=$archivePath", $SourceHead, '--', 'godot-project-moe-rail-way/') -WorkingDirectory $RepositoryRoot
    if ($archiveResult.ExitCode -ne 0) { throw "git archive failed: $($archiveResult.Stderr)" }
    Assert-ExistingOrdinaryPathChain -Path $archivePath -Boundary $Root | Out-Null

    # Extract
    $extractResult = Invoke-NativeText -Executable $TarExecutable -Arguments @('-xf', $archivePath, '-C', $projectMirror, '--strip-components', '1') -WorkingDirectory $Root
    if ($extractResult.ExitCode -ne 0) { throw "tar extract failed: $($extractResult.Stderr)" }

    # Reject archive-created links before any recursive traversal.
    Assert-OwnedRoot -Root $Root -ResolvedTempParent $TempParent -RequireExists $true | Out-Null

    # Delete only the archive ordinary file
    Remove-Item -LiteralPath $archivePath -Force -ErrorAction Stop

    # Compare mirror to pinned HEAD manifest
    Compare-MirrorToPinnedManifest -MirrorRoot $projectMirror -PinnedManifest $PinnedManifest

    # Build SourceSnapshotAfterCopy from actual worktree and compare to Before
    $SnapshotAfterCopy = Get-SourceSnapshot -RepositoryRoot $RepositoryRoot -GitExecutable $GitExecutable -SourceHead $SourceHead -PinnedManifest $PinnedManifest
    Assert-SourceSnapshotUnchanged -Before $SnapshotBefore -After $SnapshotAfterCopy

    # Before success cleanup: build final SourceSnapshotAfter, compare Before, call Remove-OwnedRoot, confirm absence
    $SnapshotAfter = Get-SourceSnapshot -RepositoryRoot $RepositoryRoot -GitExecutable $GitExecutable -SourceHead $SourceHead -PinnedManifest $PinnedManifest
    Assert-SourceSnapshotUnchanged -Before $SnapshotBefore -After $SnapshotAfter
    Remove-OwnedRoot -Root $Root -ResolvedTempParent $TempParent
    if (Test-Path -LiteralPath $Root) { throw "Root still exists after cleanup: $Root" }

    Write-Host "PASS: editor playtest mirror verified"
    exit 0
}
catch {
    if (Test-Path -LiteralPath $Root) {
        Write-Host "PRESERVED_MIRROR: $Root"
    } else {
        Write-Host "MIRROR_CREATION_FAILED: $Root"
    }
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
```

---

### REGRESSION: Exact Five Godot Regressions (Actual PowerShell Block)

```powershell
$MoeRailGodot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailProject = 'D:\godot\MoeRailWay-worktrees\feature-godot-editor-playtest-safety\godot-project-moe-rail-way'

# 1. Prototype test suite
$out = & $MoeRailGodot --headless --path $MoeRailProject --script res://tests/run_all.gd 2>&1
if ($LASTEXITCODE -ne 0 -or $out -match '(?m)^(ERROR:|SCRIPT ERROR:|FATAL:|WARNING:|CRASH:)') { exit 1 }
if ($out -notmatch 'PASS: 19 prototype test suite\(s\)') { exit 1 }

# 2. Session shell integration (layout + lifecycle from single run)
$out = & $MoeRailGodot --headless --path $MoeRailProject --script res://tests/integration/run_session_shell_integration.gd 2>&1
if ($LASTEXITCODE -ne 0 -or $out -match '(?m)^(ERROR:|SCRIPT ERROR:|FATAL:|WARNING:|CRASH:)') { exit 1 }
if ($out -notmatch 'PASS: session shell layout integration') { exit 1 }
if ($out -notmatch 'PASS: session shell lifecycle integration') { exit 1 }

# 3. Logical track field integration
$out = & $MoeRailGodot --headless --path $MoeRailProject --script res://tests/integration/run_logical_track_field_integration.gd 2>&1
if ($LASTEXITCODE -ne 0 -or $out -match '(?m)^(ERROR:|SCRIPT ERROR:|FATAL:|WARNING:|CRASH:)') { exit 1 }
if ($out -notmatch 'PASS: logical track field integration') { exit 1 }

# 4. Track train input integration
$out = & $MoeRailGodot --headless --path $MoeRailProject --script res://tests/integration/run_track_train_input_integration.gd 2>&1
if ($LASTEXITCODE -ne 0 -or $out -match '(?m)^(ERROR:|SCRIPT ERROR:|FATAL:|WARNING:|CRASH:)') { exit 1 }
if ($out -notmatch 'PASS: track train input integration') { exit 1 }

# 5. Track train app integration
$out = & $MoeRailGodot --headless --path $MoeRailProject --script res://tests/integration/run_track_train_app_integration.gd 2>&1
if ($LASTEXITCODE -ne 0 -or $out -match '(?m)^(ERROR:|SCRIPT ERROR:|FATAL:|WARNING:|CRASH:)') { exit 1 }
if ($out -notmatch 'PASS: track train app integration') { exit 1 }
```

---

### ALLOWLIST: Staging and Commit

- [ ] Run tooling test (GREEN) and exact five regressions (all pass) **before** staging
- [ ] Before staging, compare the **full** feature-worktree porcelain output with the exact Task 1 allowlist (do not path-limit the status command):
  ```powershell
  $expectedTask1Paths = @(
      'godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1',
      'godot-project-moe-rail-way/tools/playtest/launch_editor_playtest.ps1'
  ) | Sort-Object
  $porcelain = @(git status --porcelain=v1 -u)
  if ($LASTEXITCODE -ne 0) { exit 1 }
  $actualTask1Paths = @($porcelain | ForEach-Object {
      if ($_.Length -lt 4) { throw "Malformed porcelain entry: $_" }
      $_.Substring(3).Replace('\','/')
  } | Sort-Object)
  if (($actualTask1Paths -join "`n") -ne ($expectedTask1Paths -join "`n")) { exit 1 }
  ```
- [ ] Stage exactly the two Task 1 files:
  ```powershell
  git add -- godot-project-moe-rail-way/tools/playtest/launch_editor_playtest.ps1 godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1
  ```
- [ ] Verify staged set:
  ```powershell
  git diff --cached --name-only
  ```
  Expected exact output (order-insensitive):
  ```
  godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1
  godot-project-moe-rail-way/tools/playtest/launch_editor_playtest.ps1
  ```
- [ ] Commit with exact message:
  ```powershell
  git commit -m "test: add safe editor mirror verification"
  ```
- [ ] After the commit and before either review, require the **full** feature-worktree porcelain output to be empty:
  ```powershell
  $porcelain = @(git status --porcelain=v1 -u)
  if ($LASTEXITCODE -ne 0 -or $porcelain.Count -ne 0) { exit 1 }
  ```

---

### SOL SPEC REVIEW & SOL QUALITY REVIEW

- [ ] Separate Sol specification review after the focused commit
- [ ] Separate Sol quality review after the focused commit
- [ ] Findings require focused follow-up commit plus rerun affected RED/GREEN/regression gates

---

### CLEAN STATUS

- [ ] Verify empty `git status --porcelain=v1 -u`

---

### HANDOFF: Task 1 to Task 2

- [ ] After Task 1 reviews/follow-up gates, run the exact installed `task-brief` command for Task 2 with final argument 2 and verify the ignored ledger before dispatching Task 2:
  ```powershell
  & 'C:\Program Files\Git\bin\bash.exe' 'C:\Users\noisy\.codex\plugins\cache\openai-curated-remote\superpowers\6.3.0\skills\subagent-driven-development\scripts\task-brief' 'docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md' 2
  ```

---

## Task 2: Launch Mode + Diagnostics + README

**Files:**
- **Modify** `godot-project-moe-rail-way/tools/playtest/launch_editor_playtest.ps1`
- **Modify** `godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1`
- **Modify** `README.md`

**Interfaces:**

- Consumes:
  - Task 1 commit `test: add safe editor mirror verification`
  - `docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md`
  - `docs/superpowers/specs/2026-08-22-prototype-track-train-disposable-editor-mirror-amendment-design.md` (for established RID/ObjectDB leak terms)
  - `README.md` (existing)
- Produces:
  - Commit `fix: add isolated Godot editor playtest` on feature branch
  - Launcher supporting `Launch` and `VerifyMirror` modes (default `Launch`)
  - Extended tooling test covering Launch mode, diagnostics, fake child
  - `README.md` with Editor Playtest Safety section

Task 2 expands `Mode` to `Launch` and `VerifyMirror`, default `Launch`.

### Task 2 RED and Fake Child

- [ ] **TDD Order (executable):**
  1. Modify the test file first (`test_launch_editor_playtest.ps1`) to add failing Launch-mode cases.
  2. Run it against the Task 1 launcher (which only supports `VerifyMirror`); the test converts the expected `Mode` parameter rejection into nonzero exit plus the exact line `FAIL: Launch mode is unavailable`.
  3. Only then modify the production launcher (`launch_editor_playtest.ps1`) and `README.md`.
  4. Rerun for GREEN.
- [ ] **Explicitly prohibit creating/modifying production files before the RED evidence.**
- [ ] Fake executable `--version` returns `MOERAIL_FAKE_VERSION` (via `ProcessStartInfo` with separate `ArgumentList` and controlled text capture; **do not include `--version` in launch**).
- [ ] On launch (arguments contain `--editor` or `--path`):
  - Parses arguments and writes a simple **line-based capture** to `MOERAIL_TEST_CAPTURE_PATH`. **No JSON.**
  - Capture keys (exact, one per line): `ARG=<value>`, `APPDATA=<value>`, `LOCALAPPDATA=<value>`, `TEMP=<value>`, `TMP=<value>`.
  - `MOERAIL_TEST_DIAGNOSTIC` accepts exactly `stdout`, `stderr`, `editor`, or `game` and selects the diagnostic destination. With no explicit line override, it writes the gutter incident core:
    ```
    scene/gui/text_edit.cpp:6981 - Index p_gutter = -1 is out of bounds (gutters.size() = 4)
    ```
    The `editor` destination is the value of `--log-file`; the `game` destination is under child `APPDATA` at:
    ```
    Godot\app_userdata\Moe Rail Way\logs\godot.log
    ```
  - Optional `MOERAIL_TEST_DIAGNOSTIC_LINE` replaces the default gutter line so the table-driven test can exercise every strict marker and crash/leak alternative without changing production paths.
  - The fake creates editor/game log parent directories safely (`[IO.Directory]::CreateDirectory`).
- [ ] The test capture path (`MOERAIL_TEST_CAPTURE_PATH`) must be **outside the launcher's success-cleaned mirror** but **within the separately validated test-owned fixture root**.
- [ ] `MOERAIL_TEST_DIAGNOSTIC`, `MOERAIL_TEST_DIAGNOSTIC_LINE`, capture, and ready/release variables are fake-executable test seams only. The production launcher has no corresponding switch or failure-injection branch; inherited variables affect only the separately compiled fake child.

### Task 2 Production Launch

- [ ] `ProcessStartInfo` configuration:
  - `UseShellExecute = false`
  - `CreateNoWindow = false` (visible GUI)
  - Separate `ArgumentList` (no string command line)
  - Child-only `APPDATA`, `LOCALAPPDATA`, `TEMP`, `TMP` overrides in `Environment` dictionary (pointing to `$Root/environment/appdata`, `$Root/environment/localappdata`, `$Root/environment/temp`, `$Root/environment/temp` respectively)
  - **Do not mutate controller environment.**
- [ ] Visible GUI executable (`Godot_v4.7.1-stable_win64.exe`).
- [ ] **Exact launch argument order** (via `ArgumentList`):
  ```
  --editor
  --path
  $ProjectMirror
  --log-file
  $EditorLog = Join-Path $LogsDir 'editor.log'
  ```
- [ ] Redirect `stdout`/`stderr`; **immediately** call `ReadToEndAsync` for both in the controller process; then `WaitForExit` with **no timeout and no kill**.
- [ ] Only after natural process exit, require each already-running read task to drain within **five seconds**.
- [ ] If drain tasks fail/timeout, **do not kill a process because it has already exited**; preserve mirror and exit 1.
- [ ] After natural child exit, revalidate exact `$Root` and the complete ordinary, non-reparse `$LogsDir` path chain **before** writing captured strings to `stdout.log` and `stderr.log`; revalidate again after writing and before recursive collection.
- [ ] Require `stdout.log`, `stderr.log`, and `editor.log` each to exist as ordinary readable non-reparse files, then add every ordinary `.log` file recursively below child `APPDATA`.
  - Deduplicate by canonical absolute path (`[IO.Path]::GetFullPath`).
  - Reject traversal escape, duplicate canonical paths, unreadable entries, or any `ReparsePoint`.
  - Scan line-by-line using `[IO.File]::ReadLines`; no optional timestamp prefix is permitted.
  - Reject the literal line-start anchored markers `FAIL:`, `SCRIPT ERROR:`, `ERROR:`, `FATAL:`, `WARNING:`, and `CRASH:`.
  - Reject the exact core substring `Index p_gutter = -1 is out of bounds` anywhere in any line, independently of source/prefix.
  - Reuse the established actual Godot crash/leak pattern exactly:
    ```powershell
    $StrictDiagnosticPattern = '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:|FATAL:|WARNING:|CRASH:)'
    $CrashLeakPattern = '(?i)(CrashHandlerException|Program crashed|signal\s+\d+|Scan thread aborted|RID[^\r\n]*(?:leak|allocation)|ObjectDB[^\r\n]*(?:leaked at exit|still alive)|Resources?[^\r\n]*still in use)'
    ```
- [ ] **Nonzero child exit**, **drain failure**, **scan failure/match**, or **any source branch/upstream/HEAD/status/actual-hash drift** (from pinned expected path set) → **exit 1** and **preserve mirror** (print `PRESERVED_MIRROR: <absolute path>`).
- [ ] **Never copy back** any files from mirror to source.
- [ ] On success: revalidate exact owned root and all descendants, cleanup, confirm absence (`Test-Path $Root` → `False`), then print:
  ```
  PASS: editor playtest completed
  DIAGNOSTICS_SCANNED: <count>
  ```
  and **exit 0**.

### Task 2 Production Functions (Actual PowerShell Code)

Replace Task 1's `Mode` parameter with `[ValidateSet('Launch','VerifyMirror')] [string]$Mode = 'Launch'`. Add these functions, then replace Task 1's terminal snapshot/cleanup block with the mode branch and launch flow below, all inside the existing guarded `try`/`catch`:

```powershell
function Invoke-VisibleEditor {
    param(
        [string]$GodotExecutable,
        [string]$ProjectMirror,
        [string]$EditorLog,
        [string]$EnvAppData,
        [string]$EnvLocalAppData,
        [string]$EnvTemp
    )
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $GodotExecutable
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    foreach ($argument in @('--editor','--path',$ProjectMirror,'--log-file',$EditorLog)) {
        $psi.ArgumentList.Add($argument)
    }
    $psi.Environment['APPDATA'] = $EnvAppData
    $psi.Environment['LOCALAPPDATA'] = $EnvLocalAppData
    $psi.Environment['TEMP'] = $EnvTemp
    $psi.Environment['TMP'] = $EnvTemp

    $process = [Diagnostics.Process]::Start($psi)
    if ($null -eq $process) { throw 'Godot editor process did not start' }
    try {
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit() # natural exit only; no timeout and no termination
        if (-not [Threading.Tasks.Task]::WaitAll(
            [Threading.Tasks.Task[]]@($stdoutTask, $stderrTask),
            [TimeSpan]::FromSeconds(5)
        )) { throw 'Redirected stream drain exceeded five seconds after child exit' }
        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            Stdout = $stdoutTask.Result
            Stderr = $stderrTask.Result
        }
    }
    finally {
        $process.Dispose()
    }
}

function Assert-CanonicalPathWithin {
    param([string]$Path, [string]$Boundary)
    $canonical = Get-CanonicalPath -Path $Path
    $canonicalBoundary = Get-CanonicalPath -Path $Boundary
    $comparison = [StringComparison]::OrdinalIgnoreCase
    $boundaryPrefix = $canonicalBoundary
    if (-not $boundaryPrefix.EndsWith([IO.Path]::DirectorySeparatorChar) -and
        -not $boundaryPrefix.EndsWith([IO.Path]::AltDirectorySeparatorChar)) {
        $boundaryPrefix += [IO.Path]::DirectorySeparatorChar
    }
    if ($canonical -ne $canonicalBoundary -and
        -not $canonical.StartsWith($boundaryPrefix, $comparison)) {
        throw "Path escapes boundary: $canonical"
    }
    return $canonical
}

function Get-DiagnosticFiles {
    param(
        [string]$Root,
        [string]$ResolvedTempParent,
        [string]$LogsDir,
        [string]$EnvAppData,
        [string]$StdoutLog,
        [string]$StderrLog,
        [string]$EditorLog
    )
    Assert-OwnedRoot -Root $Root -ResolvedTempParent $ResolvedTempParent -RequireExists $true | Out-Null
    foreach ($directory in @($LogsDir, $EnvAppData)) {
        $canonicalDirectory = Assert-CanonicalPathWithin -Path $directory -Boundary $Root
        Assert-ExistingOrdinaryPathChain -Path $canonicalDirectory -Boundary $Root | Out-Null
        if (-not (Test-Path -LiteralPath $canonicalDirectory -PathType Container)) {
            throw "Required diagnostic directory is not ordinary: $canonicalDirectory"
        }
    }

    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $files = [Collections.Generic.List[string]]::new()
    foreach ($candidate in @($StdoutLog, $StderrLog, $EditorLog)) {
        $canonical = Assert-CanonicalPathWithin -Path $candidate -Boundary $Root
        Assert-ExistingOrdinaryPathChain -Path $canonical -Boundary $Root | Out-Null
        if (-not (Test-Path -LiteralPath $canonical -PathType Leaf)) { throw "Required log is not an ordinary file: $canonical" }
        $probe = [IO.File]::Open($canonical, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        $probe.Dispose()
        if (-not $seen.Add($canonical)) { throw "Duplicate canonical diagnostic path: $canonical" }
        $files.Add($canonical)
    }

    Assert-OwnedRoot -Root $Root -ResolvedTempParent $ResolvedTempParent -RequireExists $true | Out-Null
    foreach ($entry in Get-ChildItem -LiteralPath $EnvAppData -Filter '*.log' -File -Recurse -Force -ErrorAction Stop) {
        $canonical = Assert-CanonicalPathWithin -Path $entry.FullName -Boundary $Root
        Assert-ExistingOrdinaryPathChain -Path $canonical -Boundary $Root | Out-Null
        if (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Log reparse point rejected: $canonical" }
        $probe = [IO.File]::Open($canonical, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        $probe.Dispose()
        if (-not $seen.Add($canonical)) { throw "Duplicate canonical diagnostic path: $canonical" }
        $files.Add($canonical)
    }
    return @($files | Sort-Object)
}

function Scan-Diagnostics {
    param([string[]]$Files)
    $StrictDiagnosticPattern = '(?m)^(FAIL:|SCRIPT ERROR:|ERROR:|FATAL:|WARNING:|CRASH:)'
    $CrashLeakPattern = '(?i)(CrashHandlerException|Program crashed|signal\s+\d+|Scan thread aborted|RID[^\r\n]*(?:leak|allocation)|ObjectDB[^\r\n]*(?:leaked at exit|still alive)|Resources?[^\r\n]*still in use)'
    foreach ($file in $Files) {
        $lineNumber = 0
        foreach ($line in [IO.File]::ReadLines($file)) {
            $lineNumber++
            if ($line.Contains('Index p_gutter = -1 is out of bounds', [StringComparison]::Ordinal) -or
                $line -match $StrictDiagnosticPattern -or $line -match $CrashLeakPattern) {
                throw "Rejected diagnostic at ${file}:${lineNumber}: $line"
            }
        }
    }
    return $Files.Count
}

# Preserve Task 1 behavior as an explicit branch after mirror verification.
if ($Mode -eq 'VerifyMirror') {
    $SnapshotAfter = Get-SourceSnapshot -RepositoryRoot $RepositoryRoot -GitExecutable $GitExecutable -SourceHead $SourceHead -PinnedManifest $PinnedManifest
    Assert-SourceSnapshotUnchanged -Before $SnapshotBefore -After $SnapshotAfter
    Remove-OwnedRoot -Root $Root -ResolvedTempParent $TempParent
    if (Test-Path -LiteralPath $Root) { throw "Root still exists after cleanup: $Root" }
    Write-Host 'PASS: editor playtest mirror verified'
    exit 0
}

# Launch-mode main flow after mirror creation and validation.
$launchFailures = [Collections.Generic.List[string]]::new()
$diagnosticsScanned = 0
try {
    $EditorLog = Join-Path $logsDir 'editor.log'
    $editorResult = Invoke-VisibleEditor `
        -GodotExecutable $GodotExecutable `
        -ProjectMirror $projectMirror `
        -EditorLog $EditorLog `
        -EnvAppData $envAppData `
        -EnvLocalAppData $envLocalAppData `
        -EnvTemp $envTemp

    # The child has exited naturally. Revalidate before writing either capture.
    Assert-OwnedRoot -Root $Root -ResolvedTempParent $TempParent -RequireExists $true | Out-Null
    Assert-ExistingOrdinaryPathChain -Path $logsDir -Boundary $Root | Out-Null
    if (-not (Test-Path -LiteralPath $logsDir -PathType Container)) { throw 'Logs directory is not ordinary' }
    $stdoutLog = Join-Path $logsDir 'stdout.log'
    $stderrLog = Join-Path $logsDir 'stderr.log'
    [IO.File]::WriteAllText($stdoutLog, $editorResult.Stdout, [Text.Encoding]::UTF8)
    [IO.File]::WriteAllText($stderrLog, $editorResult.Stderr, [Text.Encoding]::UTF8)

    Assert-OwnedRoot -Root $Root -ResolvedTempParent $TempParent -RequireExists $true | Out-Null
    Assert-ExistingOrdinaryPathChain -Path $logsDir -Boundary $Root | Out-Null
    $diagnosticFiles = Get-DiagnosticFiles `
        -Root $Root -ResolvedTempParent $TempParent -LogsDir $logsDir -EnvAppData $envAppData `
        -StdoutLog $stdoutLog -StderrLog $stderrLog -EditorLog $EditorLog
    $diagnosticsScanned = Scan-Diagnostics -Files $diagnosticFiles
    if ($editorResult.ExitCode -ne 0) { $launchFailures.Add("Godot editor exited $($editorResult.ExitCode)") }
}
catch {
    $launchFailures.Add($_.Exception.Message)
}

# Source preservation is checked even when launch, drain, write, scan, or child exit failed.
try {
    $SnapshotAfter = Get-SourceSnapshot -RepositoryRoot $RepositoryRoot -GitExecutable $GitExecutable -SourceHead $SourceHead -PinnedManifest $PinnedManifest
    Assert-SourceSnapshotUnchanged -Before $SnapshotBefore -After $SnapshotAfter
}
catch {
    $launchFailures.Add("Source preservation failed: $($_.Exception.Message)")
}
if ($launchFailures.Count -ne 0) { throw ($launchFailures -join [Environment]::NewLine) }

Remove-OwnedRoot -Root $Root -ResolvedTempParent $TempParent
if (Test-Path -LiteralPath $Root) { throw "Root still exists after cleanup: $Root" }
Write-Host 'PASS: editor playtest completed'
Write-Host "DIAGNOSTICS_SCANNED: $diagnosticsScanned"
exit 0
```

### Task 2 Tests

- [ ] **Clean fake**: validates exact args (order and values), all four child env paths point below mirror, source unchanged, diagnostics count, success cleanup.
- [ ] **Editor gutter**: causes exit 1, reports `PRESERVED_MIRROR`, preserves it. Test validates exact owned preserved root before cleanup.
- [ ] **Game gutter**: causes exit 1, reports `PRESERVED_MIRROR`, preserves it. Test validates exact owned preserved root before cleanup.
- [ ] **Parameterized diagnostic targets**: inject the gutter core independently into `stdout`, `stderr`, `editor`, and `game`; each case must exit 1, identify the matched file/line, and preserve the exact mirror.
- [ ] **Cleanup revalidation failure**: start the launcher asynchronously with a fake-child ready/release handshake, create a PowerShell junction descendant inside the exact validated mirror before release, then require exit 1 and preservation without path escape; remove only the junction after independent validation.
- [ ] **Cleanup removal failure**: use the same handshake, open an ordinary non-log mirror file with `[IO.File]::Open(..., [IO.FileShare]::Read)` so delete sharing is denied, release the fake child, require exit 1 and exact preservation, then dispose the handle before test-owned cleanup.
- [ ] Verify **no controller environment mutation** and **no source mutation**.
- [ ] Tests restore/reset only their own fixtures between cases using `git reset --hard` and removal only within an exact revalidated test-owned fixture, never primary/feature.
- [ ] Tests pass `MOERAIL_TEST_DIAGNOSTIC` and `MOERAIL_TEST_CAPTURE_PATH` only through the separately spawned launcher process's `ProcessStartInfo.Environment`; they never set or mutate the controller process environment.

### Task 2 Test Harness (Actual PowerShell Code)

Replace the Task 1 fake source with this runtime-capable body, still compiled once by the existing `Compile-FakeGodotConsole` function:

```powershell
$source = @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;

public class FakeGodot {
    public static int Main(string[] args) {
        string version = Environment.GetEnvironmentVariable("MOERAIL_FAKE_VERSION");
        if (args.Length == 1 && args[0] == "--version") {
            Console.WriteLine(String.IsNullOrEmpty(version) ? "4.7.1.stable.official.a13da4feb" : version);
            return 0;
        }

        string capture = Environment.GetEnvironmentVariable("MOERAIL_TEST_CAPTURE_PATH");
        if (String.IsNullOrEmpty(capture)) return 4;
        var lines = new List<string>();
        foreach (string argument in args) lines.Add("ARG=" + argument);
        foreach (string name in new [] { "APPDATA", "LOCALAPPDATA", "TEMP", "TMP" }) {
            lines.Add(name + "=" + Environment.GetEnvironmentVariable(name));
        }
        Directory.CreateDirectory(Path.GetDirectoryName(capture));
        File.WriteAllLines(capture, lines.ToArray());

        int logIndex = Array.IndexOf(args, "--log-file");
        if (logIndex < 0 || logIndex + 1 >= args.Length) return 5;
        string editorLog = args[logIndex + 1];
        Directory.CreateDirectory(Path.GetDirectoryName(editorLog));
        File.WriteAllText(editorLog, String.Empty);
        string gutter = "scene/gui/text_edit.cpp:6981 - Index p_gutter = -1 is out of bounds (gutters.size() = 4)";
        string diagnostic = Environment.GetEnvironmentVariable("MOERAIL_TEST_DIAGNOSTIC_LINE");
        if (String.IsNullOrEmpty(diagnostic)) diagnostic = gutter;
        string target = Environment.GetEnvironmentVariable("MOERAIL_TEST_DIAGNOSTIC");
        if (target == "stdout") Console.WriteLine(diagnostic);
        if (target == "stderr") Console.Error.WriteLine(diagnostic);
        if (target == "editor") File.AppendAllText(editorLog, diagnostic + Environment.NewLine);
        if (target == "game") {
            string gameLog = Path.Combine(
                Environment.GetEnvironmentVariable("APPDATA"),
                "Godot", "app_userdata", "Moe Rail Way", "logs", "godot.log");
            Directory.CreateDirectory(Path.GetDirectoryName(gameLog));
            File.WriteAllText(gameLog, diagnostic + Environment.NewLine);
        }

        string ready = Environment.GetEnvironmentVariable("MOERAIL_TEST_READY_PATH");
        string release = Environment.GetEnvironmentVariable("MOERAIL_TEST_RELEASE_PATH");
        if (!String.IsNullOrEmpty(ready)) {
            File.WriteAllText(ready, "ready");
            DateTime deadline = DateTime.UtcNow.AddSeconds(30);
            while (!File.Exists(release)) {
                if (DateTime.UtcNow >= deadline) return 6;
                Thread.Sleep(25);
            }
        }
        return 0;
    }
}
'@
```

Add these process and ownership helpers to the test. They invoke the launcher, not the fake directly, and mutate only the spawned launcher's environment:

```powershell
function Start-LauncherAsync {
    param(
        [string]$LauncherPath, [string]$RepositoryRoot, [string]$GodotExecutable,
        [string]$GitExecutable, [string]$TarExecutable, [string]$TempParent,
        [Collections.IDictionary]$EnvOverrides
    )
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = (Get-Command pwsh.exe -ErrorAction Stop).Source
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    foreach ($argument in @(
        '-NoProfile','-File',$LauncherPath,
        '-RepositoryRoot',$RepositoryRoot,'-GodotExecutable',$GodotExecutable,
        '-GitExecutable',$GitExecutable,'-TarExecutable',$TarExecutable,
        '-TempParent',$TempParent,'-Mode','Launch'
    )) { $psi.ArgumentList.Add($argument) }
    foreach ($entry in $EnvOverrides.GetEnumerator()) { $psi.Environment[$entry.Key] = [string]$entry.Value }
    $process = [Diagnostics.Process]::Start($psi)
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    return [pscustomobject]@{ Process=$process; StdoutTask=$stdoutTask; StderrTask=$stderrTask }
}

function Complete-LauncherAsync {
    param([pscustomobject]$Running)
    try {
        $Running.Process.WaitForExit()
        if (-not [Threading.Tasks.Task]::WaitAll(
            [Threading.Tasks.Task[]]@($Running.StdoutTask,$Running.StderrTask),
            [TimeSpan]::FromSeconds(5)
        )) { throw 'Launcher capture drain timed out' }
        return [pscustomobject]@{
            ExitCode=$Running.Process.ExitCode
            Stdout=$Running.StdoutTask.Result
            Stderr=$Running.StderrTask.Result
        }
    }
    finally {
        $Running.Process.Dispose()
    }
}

function Wait-TestSignal {
    param([string]$Path)
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    while (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        if ([DateTime]::UtcNow -ge $deadline) { throw "Timed out waiting for test signal: $Path" }
        Start-Sleep -Milliseconds 25
    }
}

function Get-OnlyNewMirrorRoot {
    param([string[]]$Before, [string]$TempParent)
    $after = @(Get-MoerailDirs -TempParent $TempParent)
    $newRoots = @($after | Where-Object { $_ -notin $Before })
    if ($newRoots.Count -ne 1) { throw "Expected one new mirror, found $($newRoots.Count)" }
    return $newRoots[0]
}

function Assert-TestMirrorRoot {
    param([string]$Root, [string]$ResolvedTempParent)
    $canonical = Get-CanonicalPath -Path $Root
    $parent = Get-CanonicalPath -Path $ResolvedTempParent
    if (-not [IO.Path]::GetDirectoryName($canonical).Equals($parent,[StringComparison]::OrdinalIgnoreCase)) { throw 'Mirror parent mismatch' }
    if (-not [IO.Path]::GetFileName($canonical).StartsWith('moerail-editor-playtest-',[StringComparison]::Ordinal)) { throw 'Mirror prefix mismatch' }
    if (-not (Test-Path -LiteralPath $canonical -PathType Container)) { throw 'Mirror root is not a directory' }
    Assert-ExistingOrdinaryPathChain -Path $canonical -Boundary $parent | Out-Null
    foreach ($entry in Get-ChildItem -LiteralPath $canonical -Recurse -Force -ErrorAction Stop) {
        if (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Mirror reparse point: $($entry.FullName)" }
    }
    return $canonical
}

function Remove-TestMirrorRoot {
    param([string]$Root, [string]$ResolvedTempParent)
    $canonical = Assert-TestMirrorRoot -Root $Root -ResolvedTempParent $ResolvedTempParent
    Remove-Item -LiteralPath $canonical -Recurse -Force -ErrorAction Stop
    if (Test-Path -LiteralPath $canonical) { throw "Preserved mirror cleanup failed: $canonical" }
}
```

Add the following executable assertions before final test-fixture cleanup:

```powershell
$gitExe = (Get-Command git.exe -ErrorAction Stop).Source
$tarExe = (Get-Command tar.exe -ErrorAction Stop).Source

# This is the Task 2 RED against the committed Task 1 launcher. After Launch
# exists, the same probe is a clean success and its mirror must be removed.
$availabilityCapture = Join-Path $testTempParent 'launch-availability-capture.txt'
$controllerEnvironmentBefore = [ordered]@{
    APPDATA=$env:APPDATA; LOCALAPPDATA=$env:LOCALAPPDATA; TEMP=$env:TEMP; TMP=$env:TMP
}
$availabilityRootsBefore = @(Get-MoerailDirs -TempParent $testTempParent)
$availabilitySourceBefore = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
$availability = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot `
    -GodotExecutable $fakeGodotExe -GitExecutable $gitExe -TarExecutable $tarExe `
    -Mode Launch -TempParent $testTempParent -EnvOverrides @{
        MOERAIL_TEST_CAPTURE_PATH=$availabilityCapture
    }
if ($availability.ExitCode -ne 0 -and
    ($availability.Stdout+$availability.Stderr).Contains("Cannot validate argument on parameter 'Mode'",[StringComparison]::Ordinal)) {
    Write-Host 'FAIL: Launch mode is unavailable'
    exit 1
}
Assert-ExitCode -Expected 0 -Actual $availability.ExitCode -Message ' (Launch availability GREEN)'
Assert-OutputContains -Needle 'PASS: editor playtest completed' -Haystack $availability.Stdout
Assert-OutputContains -Needle 'DIAGNOSTICS_SCANNED: 3' -Haystack $availability.Stdout
$availabilityRootsAfter = @(Get-MoerailDirs -TempParent $testTempParent)
Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $availabilityRootsBefore -After $availabilityRootsAfter -Message ' (clean Launch cleanup)'
$availabilitySourceAfter = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
Assert-FixtureSnapshotUnchanged -Before $availabilitySourceBefore -After $availabilitySourceAfter
$captureLines = @(Get-Content -LiteralPath $availabilityCapture -ErrorAction Stop)
if ($captureLines.Count -ne 9) { throw "Unexpected capture line count: $($captureLines.Count)" }
Assert-Equal -Expected 'ARG=--editor' -Actual $captureLines[0]
Assert-Equal -Expected 'ARG=--path' -Actual $captureLines[1]
$capturedProject = $captureLines[2].Substring(4)
Assert-Equal -Expected 'ARG=--log-file' -Actual $captureLines[3]
$capturedEditorLog = $captureLines[4].Substring(4)
$capturedRoot = Get-CanonicalPath -Path ([IO.Path]::GetDirectoryName($capturedProject))
if (-not [IO.Path]::GetDirectoryName($capturedRoot).Equals($testTempParent,[StringComparison]::OrdinalIgnoreCase)) { throw 'Captured mirror parent mismatch' }
if (-not [IO.Path]::GetFileName($capturedRoot).StartsWith('moerail-editor-playtest-',[StringComparison]::Ordinal)) { throw 'Captured mirror prefix mismatch' }
Assert-Equal -Expected (Join-Path $capturedRoot 'project') -Actual $capturedProject
Assert-Equal -Expected (Join-Path $capturedRoot 'logs\editor.log') -Actual $capturedEditorLog
Assert-Equal -Expected "APPDATA=$(Join-Path $capturedRoot 'environment\appdata')" -Actual $captureLines[5]
Assert-Equal -Expected "LOCALAPPDATA=$(Join-Path $capturedRoot 'environment\localappdata')" -Actual $captureLines[6]
Assert-Equal -Expected "TEMP=$(Join-Path $capturedRoot 'environment\temp')" -Actual $captureLines[7]
Assert-Equal -Expected "TMP=$(Join-Path $capturedRoot 'environment\temp')" -Actual $captureLines[8]
$controllerEnvironmentAfter = [ordered]@{
    APPDATA=$env:APPDATA; LOCALAPPDATA=$env:LOCALAPPDATA; TEMP=$env:TEMP; TMP=$env:TMP
}
foreach ($name in $controllerEnvironmentBefore.Keys) {
    Assert-Equal -Expected $controllerEnvironmentBefore[$name] -Actual $controllerEnvironmentAfter[$name] -Message " (controller $name)"
}
Remove-Item -LiteralPath $availabilityCapture -Force -ErrorAction Stop

foreach ($target in @('stdout','stderr','editor','game')) {
    $beforeRoots = @(Get-MoerailDirs -TempParent $testTempParent)
    $beforeSource = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
    $capture = Join-Path $testTempParent "capture-$target.txt"
    $result = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot `
        -GodotExecutable $fakeGodotExe -GitExecutable $gitExe -TarExecutable $tarExe `
        -Mode Launch -TempParent $testTempParent -EnvOverrides @{
            MOERAIL_TEST_CAPTURE_PATH=$capture
            MOERAIL_TEST_DIAGNOSTIC=$target
        }
    Assert-ExitCode -Expected 1 -Actual $result.ExitCode -Message " ($target gutter)"
    $combined = $result.Stdout + $result.Stderr
    Assert-OutputContains -Needle 'Index p_gutter = -1 is out of bounds' -Haystack $combined -Message " ($target gutter)"
    Assert-OutputContains -Needle 'PRESERVED_MIRROR:' -Haystack $combined -Message " ($target preservation)"
    $preserved = Get-OnlyNewMirrorRoot -Before $beforeRoots -TempParent $testTempParent
    Assert-TestMirrorRoot -Root $preserved -ResolvedTempParent $testTempParent | Out-Null
    $expectedLog = switch ($target) {
        'stdout' { Join-Path $preserved 'logs\stdout.log' }
        'stderr' { Join-Path $preserved 'logs\stderr.log' }
        'editor' { Join-Path $preserved 'logs\editor.log' }
        'game' { Join-Path $preserved 'environment\appdata\Godot\app_userdata\Moe Rail Way\logs\godot.log' }
    }
    Assert-OutputContains -Needle "Rejected diagnostic at ${expectedLog}:1:" -Haystack $combined -Message " ($target file/line)"
    $afterSource = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
    Assert-FixtureSnapshotUnchanged -Before $beforeSource -After $afterSource
    Remove-TestMirrorRoot -Root $preserved -ResolvedTempParent $testTempParent
    Remove-Item -LiteralPath $capture -Force -ErrorAction Stop
}

# Every strict marker and every established crash/leak alternative is executable.
$diagnosticCases = @(
    @{ Name='fail'; Line='FAIL: fixture failure' },
    @{ Name='script-error'; Line='SCRIPT ERROR: fixture failure' },
    @{ Name='error'; Line='ERROR: fixture failure' },
    @{ Name='fatal'; Line='FATAL: fixture failure' },
    @{ Name='warning'; Line='WARNING: fixture failure' },
    @{ Name='crash'; Line='CRASH: fixture failure' },
    @{ Name='crash-handler'; Line='CrashHandlerException raised' },
    @{ Name='program-crashed'; Line='Program crashed unexpectedly' },
    @{ Name='signal'; Line='signal 11' },
    @{ Name='scan-aborted'; Line='Scan thread aborted' },
    @{ Name='rid-allocation'; Line='RID allocations still active' },
    @{ Name='rid-leak'; Line='RID leaked at exit' },
    @{ Name='objectdb-leak'; Line='ObjectDB instances leaked at exit' },
    @{ Name='objectdb-alive'; Line='ObjectDB instances still alive' },
    @{ Name='resource-use'; Line='Resources still in use' }
)
foreach ($case in $diagnosticCases) {
    $beforeRoots = @(Get-MoerailDirs -TempParent $testTempParent)
    $beforeSource = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
    $capture = Join-Path $testTempParent "capture-$($case.Name).txt"
    $result = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot `
        -GodotExecutable $fakeGodotExe -GitExecutable $gitExe -TarExecutable $tarExe `
        -Mode Launch -TempParent $testTempParent -EnvOverrides @{
            MOERAIL_TEST_CAPTURE_PATH=$capture
            MOERAIL_TEST_DIAGNOSTIC='editor'
            MOERAIL_TEST_DIAGNOSTIC_LINE=$case.Line
        }
    Assert-ExitCode -Expected 1 -Actual $result.ExitCode -Message " ($($case.Name))"
    $combined = $result.Stdout + $result.Stderr
    Assert-OutputContains -Needle 'PRESERVED_MIRROR:' -Haystack $combined -Message " ($($case.Name) preservation)"
    $preserved = Get-OnlyNewMirrorRoot -Before $beforeRoots -TempParent $testTempParent
    Assert-TestMirrorRoot -Root $preserved -ResolvedTempParent $testTempParent | Out-Null
    $expectedLog = Join-Path $preserved 'logs\editor.log'
    Assert-OutputContains -Needle "Rejected diagnostic at ${expectedLog}:1: $($case.Line)" -Haystack $combined -Message " ($($case.Name) file/line)"
    $afterSource = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
    Assert-FixtureSnapshotUnchanged -Before $beforeSource -After $afterSource
    Remove-TestMirrorRoot -Root $preserved -ResolvedTempParent $testTempParent
    Remove-Item -LiteralPath $capture -Force -ErrorAction Stop
}

# Cleanup pre-removal revalidation: a junction descendant must preserve the mirror.
$beforeRoots = @(Get-MoerailDirs -TempParent $testTempParent)
$ready = Join-Path $testTempParent 'junction-ready'
$release = Join-Path $testTempParent 'junction-release'
$capture = Join-Path $testTempParent 'junction-capture.txt'
$running = Start-LauncherAsync -LauncherPath $launcherPath -RepositoryRoot $cloneRoot `
    -GodotExecutable $fakeGodotExe -GitExecutable $gitExe -TarExecutable $tarExe `
    -TempParent $testTempParent -EnvOverrides @{
        MOERAIL_TEST_CAPTURE_PATH=$capture; MOERAIL_TEST_READY_PATH=$ready; MOERAIL_TEST_RELEASE_PATH=$release
    }
Wait-TestSignal -Path $ready
$preserved = Get-OnlyNewMirrorRoot -Before $beforeRoots -TempParent $testTempParent
Assert-TestMirrorRoot -Root $preserved -ResolvedTempParent $testTempParent | Out-Null
$junctionTarget = Join-Path $testTempParent 'junction-cleanup-target'
[IO.Directory]::CreateDirectory($junctionTarget) | Out-Null
$junction = Join-Path $preserved 'cleanup-junction'
New-Item -ItemType Junction -Path $junction -Target $junctionTarget -ErrorAction Stop | Out-Null
[IO.File]::WriteAllText($release,'release',[Text.Encoding]::UTF8)
$result = Complete-LauncherAsync -Running $running
Assert-ExitCode -Expected 1 -Actual $result.ExitCode -Message ' (cleanup revalidation)'
Assert-OutputContains -Needle 'PRESERVED_MIRROR:' -Haystack ($result.Stdout+$result.Stderr)
Remove-Item -LiteralPath $junction -Force -ErrorAction Stop
Remove-Item -LiteralPath $junctionTarget -Recurse -Force -ErrorAction Stop
Remove-TestMirrorRoot -Root $preserved -ResolvedTempParent $testTempParent
foreach ($path in @($ready,$release,$capture)) { Remove-Item -LiteralPath $path -Force -ErrorAction Stop }

# Cleanup removal failure: an ordinary non-log file denies delete sharing.
$beforeRoots = @(Get-MoerailDirs -TempParent $testTempParent)
$ready = Join-Path $testTempParent 'held-ready'
$release = Join-Path $testTempParent 'held-release'
$capture = Join-Path $testTempParent 'held-capture.txt'
$running = Start-LauncherAsync -LauncherPath $launcherPath -RepositoryRoot $cloneRoot `
    -GodotExecutable $fakeGodotExe -GitExecutable $gitExe -TarExecutable $tarExe `
    -TempParent $testTempParent -EnvOverrides @{
        MOERAIL_TEST_CAPTURE_PATH=$capture; MOERAIL_TEST_READY_PATH=$ready; MOERAIL_TEST_RELEASE_PATH=$release
    }
Wait-TestSignal -Path $ready
$preserved = Get-OnlyNewMirrorRoot -Before $beforeRoots -TempParent $testTempParent
Assert-TestMirrorRoot -Root $preserved -ResolvedTempParent $testTempParent | Out-Null
$heldPath = Join-Path $preserved 'project\project.godot'
$held = [IO.File]::Open($heldPath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::Read)
try {
    [IO.File]::WriteAllText($release,'release',[Text.Encoding]::UTF8)
    $result = Complete-LauncherAsync -Running $running
    Assert-ExitCode -Expected 1 -Actual $result.ExitCode -Message ' (cleanup removal)'
    Assert-OutputContains -Needle 'PRESERVED_MIRROR:' -Haystack ($result.Stdout+$result.Stderr)
} finally {
    $held.Dispose()
}
Remove-TestMirrorRoot -Root $preserved -ResolvedTempParent $testTempParent
foreach ($path in @($ready,$release,$capture)) { Remove-Item -LiteralPath $path -Force -ErrorAction Stop }
```

### README.md Modifications

- [ ] Edit happens **after Task 2 RED and alongside minimal GREEN**.
- [ ] Keep the existing five headless script commands **separate and unchanged**; do not replace them.
- [ ] Add section **Editor Playtest Safety** with exact usage. **Show the README insertion with a four-backtick outer fence** (do not put a Markdown fence inside another same-length fence):
  ````markdown
  ## Editor Playtest Safety

  From a clean synchronized `main`:

  ```powershell
  pwsh -NoProfile -File .\godot-project-moe-rail-way\tools\playtest\launch_editor_playtest.ps1
  ```

  - Uses the canonical GUI executable at `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64.exe`.
  - Press **F6** in the editor to start the session; stop the game through the editor UI; close the editor normally.
  - On success: launcher exits 0, prints `PASS: editor playtest completed` and `DIAGNOSTICS_SCANNED: <count>`, and cleans up the temporary mirror.
  - On failure: launcher exits 1, prints `PRESERVED_MIRROR: <path>`, and leaves the mirror intact for inspection.
  - Steam 4.7.2 is not used and not supported.
  ````

### Task 2 Exact Full Regression

Run with `$MoeRailGodot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'` and `$MoeRailProject = 'D:\godot\MoeRailWay-worktrees\feature-godot-editor-playtest-safety\godot-project-moe-rail-way'`. Each script runs **separately**, must exit 0, and must reject line-anchored `ERROR:|SCRIPT ERROR:|FATAL:|WARNING:|CRASH:`.

```powershell
$MoeRailGodot = 'D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
$MoeRailProject = 'D:\godot\MoeRailWay-worktrees\feature-godot-editor-playtest-safety\godot-project-moe-rail-way'

# 1. Prototype test suite
$out = & $MoeRailGodot --headless --path $MoeRailProject --script res://tests/run_all.gd 2>&1
if ($LASTEXITCODE -ne 0 -or $out -match '(?m)^(ERROR:|SCRIPT ERROR:|FATAL:|WARNING:|CRASH:)') { exit 1 }
if ($out -notmatch 'PASS: 19 prototype test suite\(s\)') { exit 1 }

# 2. Session shell integration (layout + lifecycle from single run)
$out = & $MoeRailGodot --headless --path $MoeRailProject --script res://tests/integration/run_session_shell_integration.gd 2>&1
if ($LASTEXITCODE -ne 0 -or $out -match '(?m)^(ERROR:|SCRIPT ERROR:|FATAL:|WARNING:|CRASH:)') { exit 1 }
if ($out -notmatch 'PASS: session shell layout integration') { exit 1 }
if ($out -notmatch 'PASS: session shell lifecycle integration') { exit 1 }

# 3. Logical track field integration
$out = & $MoeRailGodot --headless --path $MoeRailProject --script res://tests/integration/run_logical_track_field_integration.gd 2>&1
if ($LASTEXITCODE -ne 0 -or $out -match '(?m)^(ERROR:|SCRIPT ERROR:|FATAL:|WARNING:|CRASH:)') { exit 1 }
if ($out -notmatch 'PASS: logical track field integration') { exit 1 }

# 4. Track train input integration
$out = & $MoeRailGodot --headless --path $MoeRailProject --script res://tests/integration/run_track_train_input_integration.gd 2>&1
if ($LASTEXITCODE -ne 0 -or $out -match '(?m)^(ERROR:|SCRIPT ERROR:|FATAL:|WARNING:|CRASH:)') { exit 1 }
if ($out -notmatch 'PASS: track train input integration') { exit 1 }

# 5. Track train app integration
$out = & $MoeRailGodot --headless --path $MoeRailProject --script res://tests/integration/run_track_train_app_integration.gd 2>&1
if ($LASTEXITCODE -ne 0 -or $out -match '(?m)^(ERROR:|SCRIPT ERROR:|FATAL:|WARNING:|CRASH:)') { exit 1 }
if ($out -notmatch 'PASS: track train app integration') { exit 1 }
```

**README's existing five script list remains unchanged.**

### Task 2 Staging and Commit

- [ ] Run tooling test (GREEN) and exact five regressions (all pass) **before** staging.
- [ ] Before staging, compare the **full** porcelain output with the exact Task 2 allowlist:
  ```powershell
  $expectedTask2Paths = @(
      'README.md',
      'godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1',
      'godot-project-moe-rail-way/tools/playtest/launch_editor_playtest.ps1'
  ) | Sort-Object
  $porcelain = @(git status --porcelain=v1 -u)
  if ($LASTEXITCODE -ne 0) { exit 1 }
  $actualTask2Paths = @($porcelain | ForEach-Object {
      if ($_.Length -lt 4) { throw "Malformed porcelain entry: $_" }
      $_.Substring(3).Replace('\','/')
  } | Sort-Object)
  if (($actualTask2Paths -join "`n") -ne ($expectedTask2Paths -join "`n")) { exit 1 }
  ```
- [ ] Stage **exactly** the three Task 2 files:
  ```powershell
  git add -- godot-project-moe-rail-way/tools/playtest/launch_editor_playtest.ps1 godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1 README.md
  ```
- [ ] Verify staged set:
  ```powershell
  git diff --cached --name-only
  ```
  Expected exact output (order-insensitive):
  ```
  README.md
  godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1
  godot-project-moe-rail-way/tools/playtest/launch_editor_playtest.ps1
  ```
- [ ] Commit with exact message:
  ```powershell
  git commit -m "fix: add isolated Godot editor playtest"
  ```
- [ ] Run tooling test and exact five regressions again after commit.
- [ ] Require full porcelain empty after the commit:
  ```powershell
  $porcelain = @(git status --porcelain=v1 -u)
  if ($LASTEXITCODE -ne 0 -or $porcelain.Count -ne 0) { exit 1 }
  ```
- [ ] Continue to manual verification before requesting either review so reviewers receive its evidence.

---

### Task 2 Manual Verification (after Task 2 commit, before reviews)

- [ ] In one persistent PowerShell PTY, validate the existing system temp chain before creating either manual root. Then create a local bare `main` and clone only after the exact absent-target checks:
  ```powershell
  function Get-ManualCanonicalPath {
      param([string]$Path)
      $full = [IO.Path]::GetFullPath($Path)
      $volumeRoot = [IO.Path]::GetPathRoot($full)
      if ($full.Equals($volumeRoot,[StringComparison]::OrdinalIgnoreCase)) { return $volumeRoot }
      return $full.TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
  }

  function Assert-ManualOwnedRoot {
      param([string]$Root,[string]$ResolvedTempParent,[string]$Prefix,[bool]$RequireExists)
      $parent = Get-ManualCanonicalPath -Path $ResolvedTempParent
      $cursor = $parent
      while ($true) {
          $item = Get-Item -LiteralPath $cursor -Force -ErrorAction Stop
          if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Manual parent reparse point: $cursor" }
          $next = [IO.Path]::GetDirectoryName($cursor)
          if ([string]::IsNullOrEmpty($next) -or $next -eq $cursor) { break }
          $cursor = $next
      }
      $canonical = Get-ManualCanonicalPath -Path $Root
      if (-not [IO.Path]::GetDirectoryName($canonical).Equals($parent,[StringComparison]::OrdinalIgnoreCase)) { throw 'Manual root parent mismatch' }
      if (-not [IO.Path]::GetFileName($canonical).StartsWith($Prefix,[StringComparison]::Ordinal)) { throw 'Manual root prefix mismatch' }
      $exists = Test-Path -LiteralPath $canonical
      if ($RequireExists -ne $exists) { throw 'Manual root existence mismatch' }
      if ($RequireExists) {
          if (-not (Test-Path -LiteralPath $canonical -PathType Container)) { throw 'Manual root is not a directory' }
          $rootItem = Get-Item -LiteralPath $canonical -Force -ErrorAction Stop
          if (($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Manual root reparse point rejected' }
          foreach ($entry in Get-ChildItem -LiteralPath $canonical -Recurse -Force -ErrorAction Stop) {
              if (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Manual descendant reparse point: $($entry.FullName)" }
          }
      }
      return $canonical
  }

  $manualTempParent = Get-ManualCanonicalPath -Path ([IO.Path]::GetTempPath())
  $manualBare = Join-Path $manualTempParent "moerail-manual-bare-$(New-Guid)"
  $manualFixture = Join-Path $manualTempParent "moerail-manual-fixture-$(New-Guid)"
  Assert-ManualOwnedRoot -Root $manualBare -ResolvedTempParent $manualTempParent -Prefix 'moerail-manual-bare-' -RequireExists $false | Out-Null
  Assert-ManualOwnedRoot -Root $manualFixture -ResolvedTempParent $manualTempParent -Prefix 'moerail-manual-fixture-' -RequireExists $false | Out-Null

  git init --bare --initial-branch=main -- $manualBare
  if ($LASTEXITCODE -ne 0) { exit 1 }
  Assert-ManualOwnedRoot -Root $manualBare -ResolvedTempParent $manualTempParent -Prefix 'moerail-manual-bare-' -RequireExists $true | Out-Null
  $Task2Head = (git rev-parse HEAD).Trim()
  if ($LASTEXITCODE -ne 0 -or $Task2Head -notmatch '^[0-9a-f]{40}$') { exit 1 }
  git push -- $manualBare "${Task2Head}:refs/heads/main"
  if ($LASTEXITCODE -ne 0) { exit 1 }
  git clone --branch main --single-branch -- $manualBare $manualFixture
  if ($LASTEXITCODE -ne 0) { exit 1 }
  Assert-ManualOwnedRoot -Root $manualFixture -ResolvedTempParent $manualTempParent -Prefix 'moerail-manual-fixture-' -RequireExists $true | Out-Null
  git -C $manualFixture branch --set-upstream-to=origin/main main
  if ($LASTEXITCODE -ne 0) { exit 1 }
  $fixtureHead = (git -C $manualFixture rev-parse HEAD).Trim()
  $fixtureOriginMain = (git -C $manualFixture rev-parse origin/main).Trim()
  $fixtureStatus = @(git -C $manualFixture status --porcelain=v1 -u)
  if ($fixtureHead -ne $Task2Head -or $fixtureOriginMain -ne $Task2Head -or $fixtureStatus.Count -ne 0) { exit 1 }
  ```
- [ ] Still in the same PTY, capture exact pre-launch snapshots for the manual fixture, feature worktree, and protected primary worktree:
  ```powershell
  function Get-ManualSourceSnapshot {
      param([string]$RepositoryRoot)
      $branch = (git -C $RepositoryRoot symbolic-ref --short HEAD).Trim()
      if ($LASTEXITCODE -ne 0) { throw "Branch query failed: $RepositoryRoot" }
      $upstream = (git -C $RepositoryRoot rev-parse --abbrev-ref --symbolic-full-name '@{u}').Trim()
      if ($LASTEXITCODE -ne 0) { throw "Upstream query failed: $RepositoryRoot" }
      $head = (git -C $RepositoryRoot rev-parse HEAD).Trim()
      if ($LASTEXITCODE -ne 0) { throw "HEAD query failed: $RepositoryRoot" }
      $status = @(git -C $RepositoryRoot status --porcelain=v1 -u)
      if ($LASTEXITCODE -ne 0) { throw "Status query failed: $RepositoryRoot" }
      $hashes = [ordered]@{}
      $tracked = @(git -C $RepositoryRoot ls-files -- 'godot-project-moe-rail-way/')
      if ($LASTEXITCODE -ne 0) { throw "Tracked path query failed: $RepositoryRoot" }
      foreach ($relative in $tracked) {
          $full = Join-Path $RepositoryRoot $relative
          if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "Tracked file missing: $full" }
          $hashes[$relative.Replace('\','/')] = (Get-FileHash -LiteralPath $full -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
      }
      return [pscustomobject]@{ Branch=$branch; Upstream=$upstream; Head=$head; Status=@($status); Hashes=$hashes }
  }

  function Assert-ManualSourceSnapshotUnchanged {
      param([pscustomobject]$Before,[pscustomobject]$After,[string]$Name)
      foreach ($property in @('Branch','Upstream','Head')) {
          if ($Before.$property -ne $After.$property) { throw "$Name $property changed" }
      }
      if (($Before.Status -join "`n") -ne ($After.Status -join "`n")) { throw "$Name status changed" }
      $beforePaths = @($Before.Hashes.Keys | Sort-Object)
      $afterPaths = @($After.Hashes.Keys | Sort-Object)
      if (($beforePaths -join "`n") -ne ($afterPaths -join "`n")) { throw "$Name tracked path set changed" }
      foreach ($path in $beforePaths) {
          if ($Before.Hashes[$path] -ne $After.Hashes[$path]) { throw "$Name tracked bytes changed: $path" }
      }
  }

  $featureRoot = 'D:\godot\MoeRailWay-worktrees\feature-godot-editor-playtest-safety'
  $primaryRoot = 'D:\godot\MoeRailWay'
  $manualBefore = [ordered]@{
      Fixture = Get-ManualSourceSnapshot -RepositoryRoot $manualFixture
      Feature = Get-ManualSourceSnapshot -RepositoryRoot $featureRoot
      Primary = Get-ManualSourceSnapshot -RepositoryRoot $primaryRoot
  }
  $expectedManualState = [ordered]@{
      Fixture = @{ Branch='main'; Upstream='origin/main'; Head=$Task2Head }
      Feature = @{ Branch='feature/godot-editor-playtest-safety'; Upstream='origin/main'; Head=$Task2Head }
      Primary = @{ Branch='main'; Upstream='origin/main'; Head='38d091476c0d940c3118e1e9635deadd225be80d' }
  }
  foreach ($name in $expectedManualState.Keys) {
      $actual = $manualBefore[$name]
      $expected = $expectedManualState[$name]
      if ($actual.Branch -ne $expected.Branch -or $actual.Upstream -ne $expected.Upstream -or $actual.Head -ne $expected.Head) {
          throw "$name pre-launch branch/upstream/HEAD mismatch"
      }
      if ($actual.Status.Count -ne 0) { throw "$name pre-launch status is dirty" }
      if ($actual.Hashes.Count -eq 0) { throw "$name pre-launch tracked hash set is empty" }
  }
  ```
- [ ] **PTY phase A:** in that same persistent session, start the real launcher and both redirected reads, then return control immediately without waiting:
  ```powershell
  $launcherScript = Join-Path $manualFixture 'godot-project-moe-rail-way\tools\playtest\launch_editor_playtest.ps1'
  $psi = [Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = (Get-Command pwsh.exe -ErrorAction Stop).Source
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.WorkingDirectory = $manualFixture
  foreach ($argument in @('-NoProfile','-File',$launcherScript)) { $psi.ArgumentList.Add($argument) }
  $launcherProcess = [Diagnostics.Process]::Start($psi)
  $launcherStdoutTask = $launcherProcess.StandardOutput.ReadToEndAsync()
  $launcherStderrTask = $launcherProcess.StandardError.ReadToEndAsync()
  Write-Host 'MANUAL_EDITOR_READY_FOR_COMPUTER_USE'
  ```
- [ ] Use **Computer Use** to press **F6**, observe session-ready, stop the game through editor UI, and close the editor normally. Never enumerate, reset, or terminate any user process.
- [ ] **PTY phase B:** only after the UI actions, resume the same session and wait for natural exit; drain the already-running tasks and validate exact markers:
  ```powershell
  $launcherProcess.WaitForExit()
  if (-not [Threading.Tasks.Task]::WaitAll(
      [Threading.Tasks.Task[]]@($launcherStdoutTask,$launcherStderrTask),
      [TimeSpan]::FromSeconds(5)
  )) { exit 1 }
  $manualStdout = $launcherStdoutTask.Result
  $manualStderr = $launcherStderrTask.Result
  $manualExitCode = $launcherProcess.ExitCode
  $launcherProcess.Dispose()
  if ($manualExitCode -ne 0) { exit 1 }
  if ($manualStdout -notmatch '(?m)^PASS: editor playtest completed$') { exit 1 }
  if ($manualStdout -notmatch '(?m)^DIAGNOSTICS_SCANNED: \d+$') { exit 1 }
  ```
- [ ] Capture and compare exact post-launch snapshots. Expected result is no output and no exception; record the three before/after branch, upstream, HEAD, status, tracked path count, and hashes plus UI observations and launcher markers in English under ignored `.superpowers/sdd/2026-08-25-godot-editor-playtest-safety/task-2-report.md`:
  ```powershell
  $manualAfter = [ordered]@{
      Fixture = Get-ManualSourceSnapshot -RepositoryRoot $manualFixture
      Feature = Get-ManualSourceSnapshot -RepositoryRoot $featureRoot
      Primary = Get-ManualSourceSnapshot -RepositoryRoot $primaryRoot
  }
  foreach ($name in $manualBefore.Keys) {
      Assert-ManualSourceSnapshotUnchanged -Before $manualBefore[$name] -After $manualAfter[$name] -Name $name
  }
  ```
- [ ] Revalidate and remove only the two manual roots; preserve and report on any validation/removal failure. Never clean the launcher's success root directly:
  ```powershell
  foreach ($owned in @(
      @{ Root=$manualFixture; Prefix='moerail-manual-fixture-' },
      @{ Root=$manualBare; Prefix='moerail-manual-bare-' }
  )) {
      $canonical = Assert-ManualOwnedRoot -Root $owned.Root -ResolvedTempParent $manualTempParent -Prefix $owned.Prefix -RequireExists $true
      Remove-Item -LiteralPath $canonical -Recurse -Force -ErrorAction Stop
      if (Test-Path -LiteralPath $canonical) { throw "Manual cleanup failed: $canonical" }
  }
  ```

### Task 2 Reviews

- [ ] Give the committed Task 2 diff plus `task-2-report.md` to an independent `gpt-5.6-sol` specification reviewer.
- [ ] Give the same evidence independently to a `gpt-5.6-sol` quality reviewer.
- [ ] Findings require focused follow-up commits and rerunning every affected tooling, regression, manual, allowlist, and clean-status gate.
- [ ] After final reviews/follow-ups, require empty full porcelain before the feature completion gate.

---

## Feature Completion Gate

- [ ] Rerun fresh tooling test and exact five regressions.
- [ ] Verify primary worktree clean at original SHA `38d091476c0d940c3118e1e9635deadd225be80d`:
  ```powershell
  git -C 'D:\godot\MoeRailWay' branch --show-current
  git -C 'D:\godot\MoeRailWay' rev-parse HEAD
  git -C 'D:\godot\MoeRailWay' status --porcelain=v1 -u
  ```
  Expected branch: `main`; HEAD: `38d091476c0d940c3118e1e9635deadd225be80d`; status: empty.
- [ ] Verify feature worktree:
  - Merge-base with `origin/main` equals `38d091476c0d940c3118e1e9635deadd225be80d`:
    ```powershell
    git merge-base HEAD origin/main
    ```
  - Clean status:
    ```powershell
    git status --porcelain=v1 -u
    ```
  - Changed paths limited to exact allowlist of five paths:
    ```powershell
    git diff --name-only 38d091476c0d940c3118e1e9635deadd225be80d...HEAD
    ```
    Expected exact set (order-insensitive):
    ```
    docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md
    docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md
    README.md
    godot-project-moe-rail-way/tools/playtest/launch_editor_playtest.ps1
    godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1
    ```
- [ ] Obtain final whole-branch independent Sol specification review and Sol quality/code review.
- [ ] Apply findings in focused commits and rerun affected gates.
- [ ] Report clean `FEATURE_SHA` and evidence, then **stop**.
- [ ] **Do not push, create PR, merge, tag, or clean worktree.**
