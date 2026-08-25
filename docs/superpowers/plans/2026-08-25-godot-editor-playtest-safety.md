# Godot Editor Playtest Safety Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a deterministic, safe Godot editor playtest launcher that mirrors only tracked HEAD files into an isolated temporary environment, validates byte-identical mirrors, runs the canonical Godot 4.7.1 GUI editor with fully overridden child-only environment variables, scans editor and game logs for prohibited diagnostics (including the exact gutter incident), preserves an intact mirror when failure occurs before removal, reports possibly partial remnants when removal itself fails, and cleans up only after full revalidation on success. No runtime or gameplay changes; no generalized framework; no process enumeration/termination; no copy-back; no Steam 4.7.2.

**Architecture:** Two PowerShell scripts — a launcher (`launch_editor_playtest.ps1`) and its behavior test (`test_launch_editor_playtest.ps1`) — operating on the Godot project at `godot-project-moe-rail-way`. The launcher uses pinned `git archive` output plus `.NET System.Formats.Tar.TarFile` for Unicode-safe mirror materialization from `HEAD`, `System.Diagnostics.Process` with `UseShellExecute=false` and `ArgumentList` for controlled visible GUI editor execution with child-only `APPDATA`/`LOCALAPPDATA`/`TEMP`/`TMP` overrides, SHA-256 manifests for source integrity verification before and after, and anchored log scanning for `FAIL:`, `ERROR:`, `SCRIPT ERROR:`, `FATAL:`, `WARNING:`, `CRASH:`, exact gutter diagnostic, and established RID/ObjectDB leak terms from the disposable-mirror amendment.

**Tech Stack:** PowerShell 7.4+ (`pwsh`) on modern .NET with `System.Formats.Tar`, .NET SDK 9.0.100 with an installed compatible .NET 9 runtime (`dotnet publish` for a framework-dependent test executable plus its runtime metadata only), Git for Windows, Git Bash 5.2.37 at `C:\Program Files\Git\bin\bash.exe`, read-only Windows `fsutil.exe file queryfileid` directory identity checks, Godot 4.7.1.stable.official.a13da4feb (canonical GUI executable at `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64.exe`; console sibling at `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe`).

**Spec:** `docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md`

## Global Constraints

- authoring model `nvidia/nvidia-nemotron-3-ultra-550b-a55b`; web `gpt-5.6-luna`; all specification, quality, and code reviews `gpt-5.6-sol`.
- primary worktree protected and must remain clean at SHA `38d091476c0d940c3118e1e9635deadd225be80d`; feature worktree is `D:\godot\MoeRailWay-worktrees\feature-godot-editor-playtest-safety` on `feature/godot-editor-playtest-safety` based on `origin/main`.
- exact GUI `D:\godot\p-h\.tools\godot\4.7.1\Godot_v4.7.1-stable_win64.exe` and console sibling ending `_console.exe`, version `4.7.1.stable.official.a13da4feb`.
- no gameplay/runtime changes, generalized framework, copy-back, user environment mutation, Steam 4.7.2, push, PR, merge, tag, or worktree cleanup. Never enumerate, terminate, or reset user-owned, Godot, or Steam processes. The only termination exception is bounded failure cleanup through the exact handle of the test-owned `pwsh` process tree and separately compiled fake child created by this tooling test.
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
  - Tooling test covering ambient Git routing rejection, granular clean-state rejection, repository ordinary-chain/identity and external temp-parent enforcement, ambient fake-version sanitization, strict UTF-8/NUL Git paths, synthetic non-ordinary Git mode rejection, deterministic early child-exit diagnostics, directory identity, Unicode-safe managed extraction, mirror validation, temp root validation, and success/cleanup

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

function Get-DirectoryIdentity(
    [string]$Path
) -> [string]  # uppercase volume root + lowercase 128-bit file ID

function Assert-CleanGitEnvironment(
    [Collections.IDictionary]$Environment
) -> [void]

function Assert-TempParentOutsideRepositoryIdentity(
    [string]$TempParent,
    [string]$RepositoryIdentity
) -> [void]

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

function Assert-CleanGitEnvironment {
    param([Collections.IDictionary]$Environment)
    $exactNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($name in @(
        'GIT_DIR','GIT_WORK_TREE','GIT_COMMON_DIR','GIT_INDEX_FILE',
        'GIT_OBJECT_DIRECTORY','GIT_ALTERNATE_OBJECT_DIRECTORIES','GIT_NAMESPACE',
        'GIT_CEILING_DIRECTORIES','GIT_DISCOVERY_ACROSS_FILESYSTEM',
        'GIT_CONFIG','GIT_CONFIG_PARAMETERS','GIT_CONFIG_COUNT','GIT_CONFIG_SYSTEM',
        'GIT_CONFIG_GLOBAL','GIT_CONFIG_NOSYSTEM','GIT_EXEC_PATH','GIT_PREFIX',
        'GIT_INTERNAL_SUPER_PREFIX'
    )) { $exactNames.Add($name) | Out-Null }
    foreach ($keyObject in @($Environment.Keys | Sort-Object)) {
        $key = [string]$keyObject
        if ($exactNames.Contains($key) -or
            $key.StartsWith('GIT_CONFIG_KEY_',[StringComparison]::OrdinalIgnoreCase) -or
            $key.StartsWith('GIT_CONFIG_VALUE_',[StringComparison]::OrdinalIgnoreCase)) {
            throw "Prohibited Git environment variable: $key"
        }
    }
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
    $beforeSet = @($Before | Sort-Object | ForEach-Object { [IO.Path]::GetFullPath($_) })
    $afterSet = @($After | Sort-Object | ForEach-Object { [IO.Path]::GetFullPath($_) })
    $setsDiffer = $beforeSet.Count -ne $afterSet.Count
    if (-not $setsDiffer) {
        for ($index = 0; $index -lt $beforeSet.Count; $index++) {
            if (-not [string]::Equals($beforeSet[$index],$afterSet[$index],[StringComparison]::OrdinalIgnoreCase)) {
                $setsDiffer = $true
                break
            }
        }
    }
    if ($setsDiffer) {
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
    & git.exe -C $ClonePath config --local core.autocrlf true
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
        [string]$Mode = 'VerifyMirror',
        [string]$TempParent,
        [Collections.IDictionary]$InheritedEnvSeed = @{},
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
    $psi.ArgumentList.Add('-Mode')
    $psi.ArgumentList.Add($Mode)
    if ($TempParent) {
        $psi.ArgumentList.Add('-TempParent')
        $psi.ArgumentList.Add($TempParent)
    }
    foreach ($kv in $InheritedEnvSeed.GetEnumerator()) {
        $psi.Environment[$kv.Key] = $kv.Value
    }
    $null = $psi.Environment.Remove('MOERAIL_FAKE_VERSION')
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

function Wait-TestLauncherReadyOrThrow {
    param(
        [Threading.EventWaitHandle]$ReadyEvent,
        [Diagnostics.Process]$Process,
        [Threading.Tasks.Task]$StdoutTask,
        [Threading.Tasks.Task]$StderrTask
    )
    $readyClock = [Diagnostics.Stopwatch]::StartNew()
    while ($readyClock.Elapsed -lt [TimeSpan]::FromSeconds(30)) {
        if ($ReadyEvent.WaitOne([TimeSpan]::FromMilliseconds(50))) { return }
        if ($Process.HasExited) {
            $exitCode = $Process.ExitCode
            $earlyStderr = '<stdout/stderr streams did not drain within 5 seconds>'
            try {
                $streamsDrained = [Threading.Tasks.Task]::WaitAll(
                    [Threading.Tasks.Task[]]@($StdoutTask,$StderrTask),
                    [TimeSpan]::FromSeconds(5)
                )
                if ($streamsDrained) {
                    try {
                        $earlyStderr = $StderrTask.Result
                        if ([string]::IsNullOrEmpty($earlyStderr)) { $earlyStderr = '<empty>' }
                    }
                    catch {
                        $earlyStderr = "<stderr capture faulted: $($_.Exception.GetBaseException().Message)>"
                    }
                }
            }
            catch {
                $earlyStderr = "<stdout/stderr drain faulted: $($_.Exception.GetBaseException().Message)>"
            }
            throw "Launcher exited before ready: exit=$exitCode stderr=$earlyStderr"
        }
    }
    throw 'Identity fixture ready event timed out'
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
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = (Get-Command git.exe -ErrorAction Stop).Source
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    foreach ($argument in @('-C',$RepositoryRoot,'ls-tree','-rz','--name-only','HEAD','--','godot-project-moe-rail-way/')) {
        $psi.ArgumentList.Add($argument)
    }
    $process = [Diagnostics.Process]::Start($psi)
    $stdoutBytes = [IO.MemoryStream]::new()
    try {
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $copyTask = $process.StandardOutput.BaseStream.CopyToAsync($stdoutBytes)
        $process.WaitForExit()
        $copyTask.Wait()
        $stderrTask.Wait()
        if ($process.ExitCode -ne 0) { throw "Fixture tracked path query failed: $($stderrTask.Result)" }
        $trackedBytes = $stdoutBytes.ToArray()
    }
    finally {
        $stdoutBytes.Dispose()
        $process.Dispose()
    }
    try {
        $trackedText = [Text.UTF8Encoding]::new($false,$true).GetString($trackedBytes)
    }
    catch {
        throw "Fixture tracked path output is invalid UTF-8: $($_.Exception.Message)"
    }
    $tracked = @($trackedText -split "`0" | Where-Object { $_ -ne '' })
    if ($tracked.Count -eq 0) { throw 'Fixture tracked path query returned no files' }
    foreach ($relative in $tracked) {
        if ($relative -match '[\r\n\t]') { throw "Fixture tracked path contains CR/LF/TAB: $relative" }
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
Assert-CleanGitEnvironment -Environment ([Environment]::GetEnvironmentVariables([EnvironmentVariableTarget]::Process))
$gitConfigProbeError = $null
try {
    Assert-CleanGitEnvironment -Environment ([ordered]@{ GIT_CONFIG_KEY_0 = 'core.worktree' })
    throw 'Synthetic Git config environment was accepted'
}
catch {
    $gitConfigProbeError = $_.Exception.Message
}
Assert-OutputContains -Needle 'Prohibited Git environment variable: GIT_CONFIG_KEY_0' -Haystack $gitConfigProbeError -Message ' (Git config injection guard)'

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
Write-BinaryFixture -ProjectRoot $projectRoot -RelativePath 'assets/선로-🚆.bin' -Bytes @(0xF0,0x9F,0x9A,0x86)
& git.exe -C $cloneRoot add --all
& git.exe -C $cloneRoot commit -m 'Initial commit'
& git.exe -C $cloneRoot push -u origin main

# Helper to capture moerail dirs before/after
function CaptureMoerailDirs { return Get-MoerailDirs -TempParent $testTempParent }

# ---- CASE 1: Wrong version -> exit 2, no root ----
$dirsBefore = CaptureMoerailDirs
$result = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TempParent $testTempParent -EnvOverrides @{ MOERAIL_FAKE_VERSION = '4.7.2.stable.steam.ed1daf0bf' }
$dirsAfter = CaptureMoerailDirs
Assert-ExitCode -Expected 2 -Actual $result.ExitCode -Message ' (wrong version)'
Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $dirsBefore -After $dirsAfter -Message ' (wrong version)'

# ---- CASE 1A: Ambient fake version is removed unless intentionally overridden ----
$ambientFakeFixtureBefore = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
$ambientFakeDirsBefore = CaptureMoerailDirs
$ambientFakeResult = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TempParent $testTempParent -InheritedEnvSeed @{
    MOERAIL_FAKE_VERSION = '4.7.2.stable.steam.ed1daf0bf'
}
$ambientFakeDirsAfter = CaptureMoerailDirs
Assert-ExitCode -Expected 0 -Actual $ambientFakeResult.ExitCode -Message ' (ambient fake version sanitization)'
Assert-OutputContains -Needle 'PASS: editor playtest mirror verified' -Haystack $ambientFakeResult.Stdout -Message ' (ambient fake version sanitization marker)'
Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $ambientFakeDirsBefore -After $ambientFakeDirsAfter -Message ' (ambient fake version sanitization)'
$ambientFakeFixtureAfter = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
Assert-FixtureSnapshotUnchanged -Before $ambientFakeFixtureBefore -After $ambientFakeFixtureAfter

# ---- CASE 1B: Child exits before ready -> exact exit/stderr diagnostic ----
$earlyFixtureBefore = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
$earlyDirsBefore = CaptureMoerailDirs
$earlyReadyEventName = "Local\moerail-early-ready-$(New-Guid)"
$earlyReleaseEventName = "Local\moerail-early-release-$(New-Guid)"
$earlyReadyEvent = $null
$earlyReleaseEvent = $null
$earlyProcess = $null
$earlyStdoutTask = $null
$earlyStderrTask = $null
$earlyDiagnostic = $null
$earlyCleanupErrors = [Collections.Generic.List[string]]::new()
try {
    $earlyReadyEvent = [Threading.EventWaitHandle]::new($false,[Threading.EventResetMode]::ManualReset,$earlyReadyEventName)
    $earlyReleaseEvent = [Threading.EventWaitHandle]::new($false,[Threading.EventResetMode]::ManualReset,$earlyReleaseEventName)
    $earlyPsi = [Diagnostics.ProcessStartInfo]::new()
    $earlyPsi.FileName = 'pwsh.exe'
    $earlyPsi.UseShellExecute = $false
    $earlyPsi.RedirectStandardOutput = $true
    $earlyPsi.RedirectStandardError = $true
    foreach ($argument in @(
        '-NoProfile','-File',$launcherPath,
        '-RepositoryRoot',$cloneRoot,
        '-GodotExecutable',$fakeGodotExe,
        '-GitExecutable',(Get-Command git.exe).Source,
        '-Mode','VerifyMirror',
        '-TempParent',$testTempParent,
        '-TestReadyEventName',$earlyReadyEventName,
        '-TestReleaseEventName',$earlyReleaseEventName
    )) { $earlyPsi.ArgumentList.Add($argument) }
    $null = $earlyPsi.Environment.Remove('MOERAIL_FAKE_VERSION')
    $earlyPsi.Environment['MOERAIL_FAKE_VERSION'] = '4.7.2.stable.steam.ed1daf0bf'
    $earlyProcess = [Diagnostics.Process]::Start($earlyPsi)
    $earlyStdoutTask = $earlyProcess.StandardOutput.ReadToEndAsync()
    $earlyStderrTask = $earlyProcess.StandardError.ReadToEndAsync()
    Wait-TestLauncherReadyOrThrow -ReadyEvent $earlyReadyEvent -Process $earlyProcess -StdoutTask $earlyStdoutTask -StderrTask $earlyStderrTask
    throw 'Early-exit fixture unexpectedly reached ready'
}
catch {
    $earlyDiagnostic = $_.Exception.Message
}
finally {
    if ($null -ne $earlyReleaseEvent) { $earlyReleaseEvent.Set() | Out-Null }
    if ($null -ne $earlyProcess) {
        if (-not $earlyProcess.HasExited -and -not $earlyProcess.WaitForExit(5000)) {
            try { $earlyProcess.Kill($true) }
            catch [InvalidOperationException] {
                # Natural exit won the race.
            }
            catch { $earlyCleanupErrors.Add("Early-exit fixture bounded cleanup failed: $($_.Exception.Message)") }
            if (-not $earlyProcess.HasExited -and -not $earlyProcess.WaitForExit(5000)) {
                $earlyCleanupErrors.Add('Early-exit fixture process remained alive after bounded cleanup')
            }
        }
        if ($null -ne $earlyStdoutTask -and $null -ne $earlyStderrTask) {
            try {
                if (-not [Threading.Tasks.Task]::WaitAll(
                    [Threading.Tasks.Task[]]@($earlyStdoutTask,$earlyStderrTask),
                    [TimeSpan]::FromSeconds(5)
                )) { $earlyCleanupErrors.Add('Early-exit fixture stream drain remained incomplete') }
            }
            catch { $earlyCleanupErrors.Add("Early-exit fixture stream drain failed: $($_.Exception.Message)") }
        }
        try { $earlyProcess.Dispose() } catch { $earlyCleanupErrors.Add("Early-exit fixture process dispose failed: $($_.Exception.Message)") }
    }
    if ($null -ne $earlyReleaseEvent) {
        try { $earlyReleaseEvent.Dispose() } catch { $earlyCleanupErrors.Add("Early release event dispose failed: $($_.Exception.Message)") }
    }
    if ($null -ne $earlyReadyEvent) {
        try { $earlyReadyEvent.Dispose() } catch { $earlyCleanupErrors.Add("Early ready event dispose failed: $($_.Exception.Message)") }
    }
}
if ($earlyCleanupErrors.Count -ne 0) {
    throw ((@("Early-exit diagnostic: $earlyDiagnostic") + @($earlyCleanupErrors)) -join [Environment]::NewLine)
}
if ($null -eq $earlyDiagnostic) { throw 'Early-exit fixture produced no diagnostic' }
Assert-OutputContains -Needle 'Launcher exited before ready: exit=2 stderr=Preflight failed: Godot version mismatch:' -Haystack $earlyDiagnostic -Message ' (early exit code/reason)'
Assert-OutputContains -Needle '4.7.2.stable.steam.ed1daf0bf' -Haystack $earlyDiagnostic -Message ' (early exit actual version)'
$earlyDirsAfter = CaptureMoerailDirs
Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $earlyDirsBefore -After $earlyDirsAfter -Message ' (early exit)'
$earlyFixtureAfter = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
Assert-FixtureSnapshotUnchanged -Before $earlyFixtureBefore -After $earlyFixtureAfter

# ---- CASE 2: Feature branch -> exit 2, no root ----
& git.exe -C $cloneRoot checkout -b feature-branch
$dirsBefore = CaptureMoerailDirs
$result = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TempParent $testTempParent
$dirsAfter = CaptureMoerailDirs
Assert-ExitCode -Expected 2 -Actual $result.ExitCode -Message ' (feature branch)'
Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $dirsBefore -After $dirsAfter -Message ' (feature branch)'
& git.exe -C $cloneRoot checkout main
& git.exe -C $cloneRoot branch -D feature-branch

# ---- CASE 3: Repository-owned TempParent -> exit 2, no root, no source change ----
foreach ($insideTempParent in @($cloneRoot,$projectRoot)) {
    $fixtureBefore = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
    $dirsBefore = @(Get-MoerailDirs -TempParent $insideTempParent)
    $result = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TempParent $insideTempParent
    $dirsAfter = @(Get-MoerailDirs -TempParent $insideTempParent)
    Assert-ExitCode -Expected 2 -Actual $result.ExitCode -Message " (repository TempParent: $insideTempParent)"
    Assert-OutputContains -Needle 'TempParent must be outside RepositoryRoot:' -Haystack $result.Stderr -Message ' (repository TempParent reason)'
    Assert-DirectorySetUnchanged -TempParent $insideTempParent -Before $dirsBefore -After $dirsAfter -Message ' (repository TempParent)'
    $fixtureAfter = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
    Assert-FixtureSnapshotUnchanged -Before $fixtureBefore -After $fixtureAfter
}

# ---- CASE 3A: RepositoryRoot junction alias -> exit 2 before root ----
$repositoryAlias = Join-Path $testTempParent 'repository-alias'
$aliasFixtureBefore = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
$aliasDirsBefore = @(Get-MoerailDirs -TempParent $projectRoot)
$aliasResult = $null
New-Item -ItemType Junction -Path $repositoryAlias -Target $cloneRoot -ErrorAction Stop | Out-Null
try {
    $aliasResult = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $repositoryAlias -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TempParent $projectRoot
}
finally {
    if (Test-Path -LiteralPath $repositoryAlias) { Remove-Item -LiteralPath $repositoryAlias -Force -ErrorAction Stop }
}
Assert-ExitCode -Expected 2 -Actual $aliasResult.ExitCode -Message ' (repository junction alias)'
Assert-OutputContains -Needle "ReparsePoint in path chain: $repositoryAlias" -Haystack $aliasResult.Stderr -Message ' (repository junction reason)'
$aliasDirsAfter = @(Get-MoerailDirs -TempParent $projectRoot)
Assert-DirectorySetUnchanged -TempParent $projectRoot -Before $aliasDirsBefore -After $aliasDirsAfter -Message ' (repository junction alias)'
$aliasFixtureAfter = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
Assert-FixtureSnapshotUnchanged -Before $aliasFixtureBefore -After $aliasFixtureAfter

# ---- CASE 3B: Synthetic Git mode 120000 -> exit 2 before root ----
$modeOrigin = Join-Path $testTempParent 'mode-origin.git'
$modeClone = Join-Path $testTempParent 'mode-clone'
New-TestBareOrigin -Path $modeOrigin
New-TestClone -OriginPath $modeOrigin -ClonePath $modeClone -UserName 'Mode Test' -UserEmail 'mode@example.com'
& git.exe -C $modeClone config --local core.symlinks false
if ($LASTEXITCODE -ne 0) { throw 'Mode fixture core.symlinks configuration failed' }
$modeProjectRoot = Join-Path $modeClone 'godot-project-moe-rail-way'
[IO.Directory]::CreateDirectory($modeProjectRoot) | Out-Null
Write-ProjectGodot -ProjectRoot $modeProjectRoot
& git.exe -C $modeClone add --all
& git.exe -C $modeClone commit -m 'Initial mode fixture'
$hashPsi = [Diagnostics.ProcessStartInfo]::new()
$hashPsi.FileName = (Get-Command git.exe -ErrorAction Stop).Source
$hashPsi.UseShellExecute = $false
$hashPsi.RedirectStandardInput = $true
$hashPsi.RedirectStandardOutput = $true
$hashPsi.RedirectStandardError = $true
$hashPsi.WorkingDirectory = $modeClone
foreach ($argument in @('-C',$modeClone,'hash-object','-w','--stdin')) { $hashPsi.ArgumentList.Add($argument) }
$hashProcess = [Diagnostics.Process]::Start($hashPsi)
try {
    $hashStdoutTask = $hashProcess.StandardOutput.ReadToEndAsync()
    $hashStderrTask = $hashProcess.StandardError.ReadToEndAsync()
    $linkTargetBytes = [Text.UTF8Encoding]::new($false).GetBytes('assets/test.bin')
    $hashProcess.StandardInput.BaseStream.Write($linkTargetBytes,0,$linkTargetBytes.Length)
    $hashProcess.StandardInput.Close()
    $hashProcess.WaitForExit()
    $hashStdoutTask.Wait()
    $hashStderrTask.Wait()
    $linkOid = $hashStdoutTask.Result.Trim()
    if ($hashProcess.ExitCode -ne 0 -or $linkOid -notmatch '^[0-9a-f]{40,64}$') {
        throw "Mode fixture blob creation failed: exit=$($hashProcess.ExitCode) oid=$linkOid stderr=$($hashStderrTask.Result)"
    }
}
finally {
    $hashProcess.Dispose()
}
& git.exe -C $modeClone update-index --add --cacheinfo 120000 $linkOid 'godot-project-moe-rail-way/assets/link-fixture'
if ($LASTEXITCODE -ne 0) { throw 'Mode fixture index update failed' }
& git.exe -C $modeClone commit -m 'Add synthetic symlink mode'
if ($LASTEXITCODE -ne 0) { throw 'Mode fixture commit failed' }
& git.exe -C $modeClone checkout -- 'godot-project-moe-rail-way/assets/link-fixture'
if ($LASTEXITCODE -ne 0) { throw 'Mode fixture worktree materialization failed' }
$linkFixturePath = Join-Path $modeClone 'godot-project-moe-rail-way\assets\link-fixture'
$linkFixtureItem = Get-Item -LiteralPath $linkFixturePath -Force -ErrorAction Stop
if ($linkFixtureItem.PSIsContainer -or ($linkFixtureItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw "Mode fixture did not materialize as an ordinary leaf: $linkFixturePath"
}
& git.exe -C $modeClone push -u origin main
if ($LASTEXITCODE -ne 0) { throw 'Mode fixture push failed' }
$modeFixtureBefore = Get-FixtureSnapshot -RepositoryRoot $modeClone
$modeDirsBefore = CaptureMoerailDirs
$modeResult = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $modeClone -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TempParent $testTempParent
$modeDirsAfter = CaptureMoerailDirs
Assert-ExitCode -Expected 2 -Actual $modeResult.ExitCode -Message ' (synthetic mode 120000)'
Assert-OutputContains -Needle 'Invalid mode 120000 for godot-project-moe-rail-way/assets/link-fixture' -Haystack $modeResult.Stderr -Message ' (synthetic mode reason)'
Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $modeDirsBefore -After $modeDirsAfter -Message ' (synthetic mode)'
$modeFixtureAfter = Get-FixtureSnapshot -RepositoryRoot $modeClone
Assert-FixtureSnapshotUnchanged -Before $modeFixtureBefore -After $modeFixtureAfter

# ---- CASE 3C: Ambient Git routing/config injection -> exit 2, source and decoy unchanged ----
foreach ($gitEnvCase in @(
    @{ Name='GIT_DIR'; Value=(Join-Path $modeClone '.git') },
    @{ Name='GIT_CONFIG_KEY_0'; Value='core.worktree' }
)) {
    $gitEnvSourceBefore = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
    $gitEnvDecoyBefore = Get-FixtureSnapshot -RepositoryRoot $modeClone
    $gitEnvDirsBefore = CaptureMoerailDirs
    $gitEnvOverrides = @{}
    $gitEnvOverrides[$gitEnvCase.Name] = $gitEnvCase.Value
    $gitEnvResult = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TempParent $testTempParent -EnvOverrides $gitEnvOverrides
    $gitEnvDirsAfter = CaptureMoerailDirs
    Assert-ExitCode -Expected 2 -Actual $gitEnvResult.ExitCode -Message " (ambient Git variable $($gitEnvCase.Name))"
    Assert-OutputContains -Needle "Prohibited Git environment variable: $($gitEnvCase.Name)" -Haystack $gitEnvResult.Stderr -Message " (ambient Git variable reason $($gitEnvCase.Name))"
    Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $gitEnvDirsBefore -After $gitEnvDirsAfter -Message " (ambient Git variable $($gitEnvCase.Name))"
    $gitEnvSourceAfter = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
    $gitEnvDecoyAfter = Get-FixtureSnapshot -RepositoryRoot $modeClone
    Assert-FixtureSnapshotUnchanged -Before $gitEnvSourceBefore -After $gitEnvSourceAfter
    Assert-FixtureSnapshotUnchanged -Before $gitEnvDecoyBefore -After $gitEnvDecoyAfter
}

# ---- CASE 4: Tracked unstaged -> exit 2, exact reason/path, no root ----
$fixtureBefore = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
Write-BinaryFixture -ProjectRoot $projectRoot -RelativePath 'assets/test.bin' -Bytes @(0xFF)
$dirsBefore = CaptureMoerailDirs
$result = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TempParent $testTempParent
$dirsAfter = CaptureMoerailDirs
Assert-ExitCode -Expected 2 -Actual $result.ExitCode -Message ' (tracked unstaged)'
Assert-OutputContains -Needle 'Working tree not clean:' -Haystack $result.Stderr -Message ' (tracked unstaged reason)'
Assert-OutputContains -Needle 'godot-project-moe-rail-way/assets/test.bin' -Haystack $result.Stderr -Message ' (tracked unstaged path)'
Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $dirsBefore -After $dirsAfter -Message ' (tracked unstaged)'
& git.exe -C $cloneRoot checkout -- 'godot-project-moe-rail-way/assets/test.bin'
if ($LASTEXITCODE -ne 0) { throw 'Fixture tracked-unstaged restore failed' }
$fixtureAfter = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
Assert-FixtureSnapshotUnchanged -Before $fixtureBefore -After $fixtureAfter

# ---- CASE 5: Staged only -> exit 2, exact reason/path, no root ----
$fixtureBefore = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
Write-BinaryFixture -ProjectRoot $projectRoot -RelativePath 'assets/test.bin' -Bytes @(0xFE)
& git.exe -C $cloneRoot add -- 'godot-project-moe-rail-way/assets/test.bin'
$dirsBefore = CaptureMoerailDirs
$result = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TempParent $testTempParent
$dirsAfter = CaptureMoerailDirs
Assert-ExitCode -Expected 2 -Actual $result.ExitCode -Message ' (staged only)'
Assert-OutputContains -Needle 'Working tree not clean:' -Haystack $result.Stderr -Message ' (staged only reason)'
Assert-OutputContains -Needle 'godot-project-moe-rail-way/assets/test.bin' -Haystack $result.Stderr -Message ' (staged only path)'
Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $dirsBefore -After $dirsAfter -Message ' (staged only)'
& git.exe -C $cloneRoot reset --quiet HEAD -- 'godot-project-moe-rail-way/assets/test.bin'
if ($LASTEXITCODE -ne 0) { throw 'Fixture staged index restore failed' }
& git.exe -C $cloneRoot checkout -- 'godot-project-moe-rail-way/assets/test.bin'
if ($LASTEXITCODE -ne 0) { throw 'Fixture staged worktree restore failed' }
$fixtureAfter = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
Assert-FixtureSnapshotUnchanged -Before $fixtureBefore -After $fixtureAfter

# ---- CASE 6: Untracked only -> exit 2, exact reason/path, no root ----
$fixtureBefore = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
$untrackedPath = Join-Path $projectRoot 'untracked.txt'
[IO.File]::WriteAllText($untrackedPath,'untracked',[Text.Encoding]::UTF8)
$dirsBefore = CaptureMoerailDirs
$result = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TempParent $testTempParent
$dirsAfter = CaptureMoerailDirs
Assert-ExitCode -Expected 2 -Actual $result.ExitCode -Message ' (untracked only)'
Assert-OutputContains -Needle 'Working tree not clean:' -Haystack $result.Stderr -Message ' (untracked only reason)'
Assert-OutputContains -Needle 'godot-project-moe-rail-way/untracked.txt' -Haystack $result.Stderr -Message ' (untracked only path)'
Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $dirsBefore -After $dirsAfter -Message ' (untracked only)'
Remove-Item -LiteralPath $untrackedPath -Force -ErrorAction Stop
$fixtureAfter = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
Assert-FixtureSnapshotUnchanged -Before $fixtureBefore -After $fixtureAfter

# ---- CASE 7: Local-ahead divergence -> exit 2, no root ----
Write-BinaryFixture -ProjectRoot $projectRoot -RelativePath 'assets/ahead.bin' -Bytes @(0xAA)
& git.exe -C $cloneRoot add --all
& git.exe -C $cloneRoot commit -m 'Local ahead commit'
$dirsBefore = CaptureMoerailDirs
$result = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TempParent $testTempParent
$dirsAfter = CaptureMoerailDirs
Assert-ExitCode -Expected 2 -Actual $result.ExitCode -Message ' (local ahead)'
Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $dirsBefore -After $dirsAfter -Message ' (local ahead)'
& git.exe -C $cloneRoot reset --hard HEAD~1
if ($LASTEXITCODE -ne 0) { throw 'Fixture local-ahead reset failed' }

# ---- CASE 8: TempParent junction -> exit 2, no root ----
$junctionParent = Join-Path $testTempParent 'junction-parent'
$junctionTarget = Join-Path $testTempParent 'junction-target'
[IO.Directory]::CreateDirectory($junctionTarget) | Out-Null
New-Item -ItemType Junction -Path $junctionParent -Target $junctionTarget -ErrorAction Stop | Out-Null
$dirsBefore = CaptureMoerailDirs
$result = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TempParent $junctionParent
$dirsAfter = CaptureMoerailDirs
Assert-ExitCode -Expected 2 -Actual $result.ExitCode -Message ' (junction temp parent)'
Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $dirsBefore -After $dirsAfter -Message ' (junction temp parent)'
Remove-Item -LiteralPath $junctionParent -Force -ErrorAction Stop
Remove-Item -LiteralPath $junctionTarget -Recurse -Force -ErrorAction Stop

# ---- CASE 9: Ordinary ancestor replacement -> exit 1, deletion refused ----
$fixtureBefore = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
$identityParent = Join-Path $testTempParent 'identity-parent'
$identityTempParent = Join-Path $identityParent 'temp'
$identityOriginalParent = Join-Path $testTempParent 'identity-parent-original'
[IO.Directory]::CreateDirectory($identityTempParent) | Out-Null
$readyEventName = "Local\moerail-ready-$(New-Guid)"
$releaseEventName = "Local\moerail-release-$(New-Guid)"
$readyEvent = $null
$releaseEvent = $null
$identityProcess = $null
$identityStdoutTask = $null
$identityStderrTask = $null
$releaseSent = $false
$identityBodyError = $null
$identityCleanupErrors = [Collections.Generic.List[string]]::new()
try {
    $readyEvent = [Threading.EventWaitHandle]::new($false,[Threading.EventResetMode]::ManualReset,$readyEventName)
    $releaseEvent = [Threading.EventWaitHandle]::new($false,[Threading.EventResetMode]::ManualReset,$releaseEventName)
    $identityPsi = [Diagnostics.ProcessStartInfo]::new()
    $identityPsi.FileName = 'pwsh.exe'
    $identityPsi.UseShellExecute = $false
    $identityPsi.RedirectStandardOutput = $true
    $identityPsi.RedirectStandardError = $true
    foreach ($argument in @(
        '-NoProfile','-File',$launcherPath,
        '-RepositoryRoot',$cloneRoot,
        '-GodotExecutable',$fakeGodotExe,
        '-GitExecutable',(Get-Command git.exe).Source,
        '-Mode','VerifyMirror',
        '-TempParent',$identityTempParent,
        '-TestReadyEventName',$readyEventName,
        '-TestReleaseEventName',$releaseEventName
    )) { $identityPsi.ArgumentList.Add($argument) }
    $null = $identityPsi.Environment.Remove('MOERAIL_FAKE_VERSION')
    $identityProcess = [Diagnostics.Process]::Start($identityPsi)
    $identityStdoutTask = $identityProcess.StandardOutput.ReadToEndAsync()
    $identityStderrTask = $identityProcess.StandardError.ReadToEndAsync()
    Wait-TestLauncherReadyOrThrow -ReadyEvent $readyEvent -Process $identityProcess -StdoutTask $identityStdoutTask -StderrTask $identityStderrTask
    $identityRoots = @(Get-MoerailDirs -TempParent $identityTempParent)
    if ($identityRoots.Count -ne 1) { throw "Identity fixture expected one root, got $($identityRoots.Count)" }
    $rootLeaf = [IO.Path]::GetFileName($identityRoots[0])
    $rootIdBeforeText = (& fsutil.exe file queryfileid $identityRoots[0] 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "Identity fixture initial file ID query failed: $rootIdBeforeText" }
    $rootIdBeforeMatches = [regex]::Matches($rootIdBeforeText,'(?i)0x[0-9a-f]{32}')
    if ($rootIdBeforeMatches.Count -ne 1) { throw "Identity fixture initial file ID malformed: $rootIdBeforeText" }
    $rootIdBefore = $rootIdBeforeMatches[0].Value.ToLowerInvariant()
    $originalSentinelBeforeMove = Join-Path $identityRoots[0] 'original-sentinel.bin'
    [IO.File]::WriteAllBytes($originalSentinelBeforeMove,[byte[]]@(0xA1))
    Move-Item -LiteralPath $identityParent -Destination $identityOriginalParent -ErrorAction Stop
    [IO.Directory]::CreateDirectory($identityTempParent) | Out-Null
    $movedOriginalRoot = Join-Path (Join-Path $identityOriginalParent 'temp') $rootLeaf
    $restoredLexicalRoot = Join-Path $identityTempParent $rootLeaf
    Move-Item -LiteralPath $movedOriginalRoot -Destination $restoredLexicalRoot -ErrorAction Stop
    $rootIdAfterText = (& fsutil.exe file queryfileid $restoredLexicalRoot 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "Identity fixture restored file ID query failed: $rootIdAfterText" }
    $rootIdAfterMatches = [regex]::Matches($rootIdAfterText,'(?i)0x[0-9a-f]{32}')
    if ($rootIdAfterMatches.Count -ne 1) { throw "Identity fixture restored file ID malformed: $rootIdAfterText" }
    $rootIdAfter = $rootIdAfterMatches[0].Value.ToLowerInvariant()
    if ($rootIdAfter -cne $rootIdBefore) { throw 'Identity fixture did not preserve the original root object' }
    $replacementSentinel = Join-Path $restoredLexicalRoot 'replacement-parent-sentinel.bin'
    [IO.File]::WriteAllBytes($replacementSentinel,[byte[]]@(0xD1))
    $releaseEvent.Set() | Out-Null
    $releaseSent = $true
    if (-not $identityProcess.WaitForExit(35000)) { throw 'Identity fixture launcher did not exit after release' }
    if (-not [Threading.Tasks.Task]::WaitAll(
        [Threading.Tasks.Task[]]@($identityStdoutTask,$identityStderrTask),
        [TimeSpan]::FromSeconds(5)
    )) { throw 'Identity fixture stream drain timed out' }
    $identityExitCode = $identityProcess.ExitCode
    $identityStdout = $identityStdoutTask.Result
    $identityStderr = $identityStderrTask.Result
}
catch {
    $identityBodyError = $_.Exception
}
finally {
    if (-not $releaseSent -and $null -ne $releaseEvent) { $releaseEvent.Set() | Out-Null }
    if ($null -ne $identityProcess) {
        if (-not $identityProcess.HasExited -and -not $identityProcess.WaitForExit(5000)) {
            try {
                $identityProcess.Kill($true) # test-owned pwsh/fake child only; never user Godot or Steam
            }
            catch [InvalidOperationException] {
                # Natural exit won the race.
            }
            catch {
                $identityCleanupErrors.Add("Identity fixture kill failed: $($_.Exception.Message)")
            }
            if (-not $identityProcess.HasExited -and -not $identityProcess.WaitForExit(5000)) {
                $identityCleanupErrors.Add('Identity fixture process remained alive after bounded kill wait')
            }
        }
        if ($null -ne $identityStdoutTask -and $null -ne $identityStderrTask) {
            try {
                if (-not [Threading.Tasks.Task]::WaitAll(
                    [Threading.Tasks.Task[]]@($identityStdoutTask,$identityStderrTask),
                    [TimeSpan]::FromSeconds(5)
                )) { $identityCleanupErrors.Add('Identity fixture stream drain remained incomplete') }
            }
            catch {
                $identityCleanupErrors.Add("Identity fixture stream drain failed: $($_.Exception.Message)")
            }
        }
        try {
            $identityProcess.Dispose()
        }
        catch {
            $identityCleanupErrors.Add("Identity fixture process dispose failed: $($_.Exception.Message)")
        }
    }
    if ($null -ne $releaseEvent) {
        try { $releaseEvent.Dispose() } catch { $identityCleanupErrors.Add("Release event dispose failed: $($_.Exception.Message)") }
    }
    if ($null -ne $readyEvent) {
        try { $readyEvent.Dispose() } catch { $identityCleanupErrors.Add("Ready event dispose failed: $($_.Exception.Message)") }
    }
}
$identityErrors = [Collections.Generic.List[string]]::new()
if ($null -ne $identityBodyError) { $identityErrors.Add("Identity fixture body failed: $($identityBodyError.Message)") }
foreach ($cleanupError in $identityCleanupErrors) { $identityErrors.Add($cleanupError) }
if ($identityErrors.Count -ne 0) { throw ($identityErrors -join [Environment]::NewLine) }
Assert-ExitCode -Expected 1 -Actual $identityExitCode -Message ' (TempParent identity changed)'
Assert-OutputContains -Needle 'TempParent identity changed:' -Haystack $identityStderr -Message ' (identity reason)'
Assert-OutputContains -Needle "MIRROR_IDENTITY_LOST: last-known-path=$($identityRoots[0]) captured-identity=" -Haystack $identityStdout -Message ' (honest identity-loss marker)'
if ($identityStdout.Contains('PRESERVED_MIRROR:',[StringComparison]::Ordinal)) { throw 'Identity loss mislabeled the lexical root as preserved mirror' }
$originalSentinelAfterMove = Join-Path $restoredLexicalRoot 'original-sentinel.bin'
if (-not (Test-Path -LiteralPath $originalSentinelAfterMove -PathType Leaf)) { throw 'Original identity sentinel was removed' }
if (-not (Test-Path -LiteralPath $replacementSentinel -PathType Leaf)) { throw 'Replacement-parent sentinel was removed' }
$fixtureAfter = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
Assert-FixtureSnapshotUnchanged -Before $fixtureBefore -After $fixtureAfter

# ---- CASE 10: Success -> exit 0, marker, source invariants, cleanup ----
$fixtureBefore = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
$dirsBefore = CaptureMoerailDirs
$result = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot -GodotExecutable $fakeGodotExe -GitExecutable (Get-Command git.exe).Source -TempParent $testTempParent
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
    [ValidateSet('VerifyMirror')]
    [string]$Mode = 'VerifyMirror',
    [string]$TempParent = $null,
    [Parameter(DontShow)]
    [string]$TestReadyEventName = $null,
    [Parameter(DontShow)]
    [string]$TestReleaseEventName = $null
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$CapturedRepositoryIdentity = $null
$CapturedTempParentIdentity = $null
$CapturedRootIdentity = $null

function Get-CanonicalPath {
    param([string]$Path)
    $full = [IO.Path]::GetFullPath($Path)
    $volumeRoot = [IO.Path]::GetPathRoot($full)
    if ($full.Equals($volumeRoot,[StringComparison]::OrdinalIgnoreCase)) { return $volumeRoot }
    return $full.TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
}

function Assert-CleanGitEnvironment {
    param([Collections.IDictionary]$Environment)
    $exactNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($name in @(
        'GIT_DIR','GIT_WORK_TREE','GIT_COMMON_DIR','GIT_INDEX_FILE',
        'GIT_OBJECT_DIRECTORY','GIT_ALTERNATE_OBJECT_DIRECTORIES','GIT_NAMESPACE',
        'GIT_CEILING_DIRECTORIES','GIT_DISCOVERY_ACROSS_FILESYSTEM',
        'GIT_CONFIG','GIT_CONFIG_PARAMETERS','GIT_CONFIG_COUNT','GIT_CONFIG_SYSTEM',
        'GIT_CONFIG_GLOBAL','GIT_CONFIG_NOSYSTEM','GIT_EXEC_PATH','GIT_PREFIX',
        'GIT_INTERNAL_SUPER_PREFIX'
    )) { $exactNames.Add($name) | Out-Null }
    foreach ($keyObject in @($Environment.Keys | Sort-Object)) {
        $key = [string]$keyObject
        if ($exactNames.Contains($key) -or
            $key.StartsWith('GIT_CONFIG_KEY_',[StringComparison]::OrdinalIgnoreCase) -or
            $key.StartsWith('GIT_CONFIG_VALUE_',[StringComparison]::OrdinalIgnoreCase)) {
            throw "Prohibited Git environment variable: $key"
        }
    }
}

# Resolve GitExecutable and read-only fsutil with controlled preflight
try {
    if ([string]::IsNullOrWhiteSpace($GitExecutable)) { $GitExecutable = (Get-Command git.exe -ErrorAction Stop).Source }
    $FsutilExecutable = (Get-Command fsutil.exe -ErrorAction Stop).Source
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

function Get-DirectoryIdentity {
    param([string]$Path)
    $canonical = Get-CanonicalPath -Path $Path
    $result = Invoke-NativeText -Executable $FsutilExecutable -Arguments @('file','queryfileid',$canonical) -WorkingDirectory $canonical
    if ($result.ExitCode -ne 0) { throw "fsutil queryfileid failed for ${canonical}: $($result.Stderr)" }
    $identityMatches = [regex]::Matches($result.Stdout,'(?i)0x[0-9a-f]{32}')
    if ($identityMatches.Count -ne 1) { throw "Unexpected fsutil queryfileid output for ${canonical}: $($result.Stdout)" }
    $volumeRoot = [IO.Path]::GetPathRoot($canonical).ToUpperInvariant()
    return "$volumeRoot|$($identityMatches[0].Value.ToLowerInvariant())"
}

function Assert-TempParentOutsideRepositoryIdentity {
    param(
        [string]$TempParent,
        [string]$RepositoryIdentity
    )
    $cursor = Get-CanonicalPath -Path $TempParent
    while ($true) {
        $identity = Get-DirectoryIdentity -Path $cursor
        if ($identity -ceq $RepositoryIdentity) {
            throw "TempParent ancestor resolves to RepositoryRoot identity: $cursor"
        }
        $parent = [IO.Path]::GetDirectoryName($cursor)
        if ([string]::IsNullOrEmpty($parent) -or $parent.Equals($cursor,[StringComparison]::OrdinalIgnoreCase)) { break }
        $cursor = Get-CanonicalPath -Path $parent
    }
}

function Wait-TestCleanupBarrier {
    if ([string]::IsNullOrWhiteSpace($TestReadyEventName)) { return }
    $readyEvent = $null
    $releaseEvent = $null
    try {
        $readyEvent = [Threading.EventWaitHandle]::OpenExisting($TestReadyEventName)
        $releaseEvent = [Threading.EventWaitHandle]::OpenExisting($TestReleaseEventName)
        $readyEvent.Set() | Out-Null
        if (-not $releaseEvent.WaitOne([TimeSpan]::FromSeconds(30))) { throw 'Test release event timed out' }
    }
    finally {
        if ($null -ne $releaseEvent) { $releaseEvent.Dispose() }
        if ($null -ne $readyEvent) { $readyEvent.Dispose() }
    }
}

function Test-CapturedRootReachable {
    param([string]$Root,[string]$ResolvedTempParent)
    if ($null -eq $script:CapturedTempParentIdentity -or $null -eq $script:CapturedRootIdentity) { return $false }
    try {
        $canonicalTempParent = Get-CanonicalPath -Path $ResolvedTempParent
        Assert-ExistingOrdinaryPathChain -Path $canonicalTempParent -Boundary ([IO.Path]::GetPathRoot($canonicalTempParent)) | Out-Null
        if ((Get-DirectoryIdentity -Path $canonicalTempParent) -cne $script:CapturedTempParentIdentity) { return $false }
        $canonicalRoot = Get-CanonicalPath -Path $Root
        if (-not [IO.Path]::GetDirectoryName($canonicalRoot).Equals($canonicalTempParent,[StringComparison]::OrdinalIgnoreCase)) { return $false }
        if (-not [IO.Path]::GetFileName($canonicalRoot).StartsWith('moerail-editor-playtest-',[StringComparison]::Ordinal)) { return $false }
        if (-not (Test-Path -LiteralPath $canonicalRoot -PathType Container)) { return $false }
        Assert-ExistingOrdinaryPathChain -Path $canonicalRoot -Boundary $canonicalTempParent | Out-Null
        return (Get-DirectoryIdentity -Path $canonicalRoot) -ceq $script:CapturedRootIdentity
    }
    catch {
        return $false
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
    $psi.ArgumentList.Add('-rz')
    $psi.ArgumentList.Add('--full-tree')
    $psi.ArgumentList.Add($SourceHead)
    $psi.ArgumentList.Add('--')
    $psi.ArgumentList.Add('godot-project-moe-rail-way/')
    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdoutBytes = [IO.MemoryStream]::new()
    try {
        $stderrTask = $proc.StandardError.ReadToEndAsync()
        $copyTask = $proc.StandardOutput.BaseStream.CopyToAsync($stdoutBytes)
        $proc.WaitForExit()
        $copyTask.Wait()
        $stderrTask.Wait()
        if ($proc.ExitCode -ne 0) { throw "git ls-tree failed: $($stderrTask.Result)" }
        $treeBytes = $stdoutBytes.ToArray()
    }
    finally {
        $stdoutBytes.Dispose()
        $proc.Dispose()
    }
    try {
        $treeText = [Text.UTF8Encoding]::new($false,$true).GetString($treeBytes)
    }
    catch {
        throw "git ls-tree returned invalid UTF-8: $($_.Exception.Message)"
    }
    $records = @($treeText -split "`0" | Where-Object { $_ -ne '' })
    if ($records.Count -eq 0) {
        throw "Pinned manifest empty: no tracked files under godot-project-moe-rail-way/"
    }
    $manifest = [ordered]@{}
    $seen = @{}
    foreach ($record in $records) {
        $parts = $record -split "`t", 2
        if ($parts.Count -ne 2) { throw "Malformed ls-tree record: $record" }
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
    Assert-ExistingOrdinaryPathChain -Path $canonicalTempParent -Boundary ([IO.Path]::GetPathRoot($canonicalTempParent)) | Out-Null
    if ($null -ne $script:CapturedTempParentIdentity) {
        $currentTempParentIdentity = Get-DirectoryIdentity -Path $canonicalTempParent
        if ($currentTempParentIdentity -cne $script:CapturedTempParentIdentity) {
            throw "TempParent identity changed: $canonicalTempParent"
        }
    }
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
        if ($null -ne $script:CapturedRootIdentity) {
            $currentRootIdentity = Get-DirectoryIdentity -Path $canonicalRoot
            if ($currentRootIdentity -cne $script:CapturedRootIdentity) { throw "Root identity changed: $canonicalRoot" }
        }
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
Assert-CleanGitEnvironment -Environment ([Environment]::GetEnvironmentVariables([EnvironmentVariableTarget]::Process))
$RepositoryRoot = Get-CanonicalPath -Path $RepositoryRoot
if ([string]::IsNullOrWhiteSpace($TempParent)) { $TempParent = [IO.Path]::GetTempPath() }
$TempParent = Get-CanonicalPath -Path $TempParent
$hasTestReadyEvent = -not [string]::IsNullOrWhiteSpace($TestReadyEventName)
$hasTestReleaseEvent = -not [string]::IsNullOrWhiteSpace($TestReleaseEventName)
if ($hasTestReadyEvent -ne $hasTestReleaseEvent) { throw 'Test ready/release events must be supplied together' }
$repositoryPrefix = $RepositoryRoot
if (-not $repositoryPrefix.EndsWith([IO.Path]::DirectorySeparatorChar) -and
    -not $repositoryPrefix.EndsWith([IO.Path]::AltDirectorySeparatorChar)) {
    $repositoryPrefix += [IO.Path]::DirectorySeparatorChar
}
if ($TempParent.Equals($RepositoryRoot,[StringComparison]::OrdinalIgnoreCase) -or
    $TempParent.StartsWith($repositoryPrefix,[StringComparison]::OrdinalIgnoreCase)) {
    throw "TempParent must be outside RepositoryRoot: $TempParent"
}
Assert-ExistingOrdinaryPathChain -Path $RepositoryRoot -Boundary ([IO.Path]::GetPathRoot($RepositoryRoot)) | Out-Null
$script:CapturedRepositoryIdentity = Get-DirectoryIdentity -Path $RepositoryRoot
Assert-ExistingOrdinaryPathChain -Path $TempParent -Boundary ([IO.Path]::GetPathRoot($TempParent)) | Out-Null
Assert-TempParentOutsideRepositoryIdentity -TempParent $TempParent -RepositoryIdentity $script:CapturedRepositoryIdentity
$script:CapturedTempParentIdentity = Get-DirectoryIdentity -Path $TempParent

# Validate Godot version
if (-not (Test-Path -LiteralPath $GodotExecutable -PathType Leaf)) { throw 'Godot executable missing' }
$versionResult = Invoke-NativeText -Executable $GodotExecutable -Arguments @('--version') -WorkingDirectory $RepositoryRoot
if ($versionResult.ExitCode -ne 0) {
    throw "Godot version check failed: $($versionResult.Stderr)"
}
$versionLines = @($versionResult.Stdout -split "`r?`n" | Where-Object { $_ -ne '' })
if ($versionLines.Count -eq 0) { throw 'Godot version output is empty' }
$firstLine = ([string]$versionLines[0]).Trim()
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

# 6. Capture the pre-root directory set after all ordinary-chain and identity gates
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
$script:CapturedRootIdentity = Get-DirectoryIdentity -Path $Root
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
    $archiveResult = Invoke-NativeText -Executable $GitExecutable -Arguments @('-c', 'core.autocrlf=false', 'archive', '--format=tar', "--output=$archivePath", "${SourceHead}:godot-project-moe-rail-way") -WorkingDirectory $RepositoryRoot
    if ($archiveResult.ExitCode -ne 0) { throw "git archive failed: $($archiveResult.Stderr)" }
    Assert-ExistingOrdinaryPathChain -Path $archivePath -Boundary $Root | Out-Null

    # Extract with .NET TarFile because Windows tar.exe cannot extract every valid UTF-8/emoji Git path.
    [System.Formats.Tar.TarFile]::ExtractToDirectory($archivePath,$projectMirror,$false)

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
    Wait-TestCleanupBarrier
    Remove-OwnedRoot -Root $Root -ResolvedTempParent $TempParent
    if (Test-Path -LiteralPath $Root) { throw "Root still exists after cleanup: $Root" }

    Write-Host "PASS: editor playtest mirror verified"
    exit 0
}
catch {
    $failureException = $_.Exception
    $rootIdentityStillMatches = Test-CapturedRootReachable -Root $Root -ResolvedTempParent $TempParent
    if ($rootIdentityStillMatches) {
        Write-Host "PRESERVED_MIRROR: $Root"
    } elseif ($null -ne $script:CapturedRootIdentity) {
        Write-Host "MIRROR_IDENTITY_LOST: last-known-path=$Root captured-identity=$($script:CapturedRootIdentity)"
    } else {
        Write-Host "MIRROR_CREATION_FAILED: $Root"
    }
    [Console]::Error.WriteLine($failureException.Message)
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
- [ ] Review findings require this exact focused follow-up cycle:
  1. Amend and independently review the English design and plan before implementation changes.
  2. Require full porcelain to contain exactly `docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md` and `docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md`; stage only those two files, commit `docs: harden editor mirror review contract`, and require clean full porcelain.
  3. Modify the Task 1 tooling test only with the ambient Git routing, repository-temp/junction, granular dirty-state, ambient fake-version sanitization, Unicode/NUL, synthetic mode `120000`, deterministic early-exit diagnostic, and directory-identity cases above; run it against the prior reviewed implementation plus the reviewed documentation commits and require nonzero RED at the first new unmet contract.
  4. Apply the matching minimal launcher changes; require tooling GREEN and all five exact Godot regressions.
  5. Require the full porcelain allowlist to contain only the two Task 1 implementation paths; stage only those paths and commit `fix: harden editor mirror safety gates`.
  6. Require clean full porcelain, then repeat separate Sol specification and Sol quality/code reviews. Any new finding repeats this focused cycle.
  7. The live Unicode GREEN attempt proved that Windows `tar.exe` lists but cannot extract `assets/선로-🚆.bin`, while `.NET System.Formats.Tar.TarFile` extracts the same archive correctly; it also proved that the identity fixture masked a launcher exit before the ready event. Restore only the two uncommitted Task 1 files to `HEAD` through exact patch content, amend and independently review the two English canonical documents, commit only those documents as `docs: use Unicode-safe managed tar extraction`, and then repeat steps 3–6 with the managed extraction and early-exit diagnostic contract.
  8. The post-`4584404e8bdca5ac495918065615770b6e3e9b64` Sol quality review found ambient Git routing/config injection, repository junction aliases, and ambient fake-version inheritance. Amend/review only the two English canonical documents and commit them as `docs: reject ambient Git routing and repository aliases`; then change the test only and require RED against `4584404e8bdca5ac495918065615770b6e3e9b64`, apply the minimal launcher fix, rerun tooling GREEN plus all five regressions, commit only the two Task 1 implementation files as `fix: reject ambient Git routing and repository aliases`, require clean porcelain, and repeat separate Sol specification and quality/code reviews.

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
  - Task 1 commits `test: add safe editor mirror verification`, reviewed follow-up `fix: harden editor mirror safety gates`, and reviewed follow-up `fix: reject ambient Git routing and repository aliases`
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
- [ ] `MOERAIL_TEST_DIAGNOSTIC`, `MOERAIL_TEST_DIAGNOSTIC_LINE`, capture, and fake-child ready/release environment variables are fake-executable test seams only; inherited variables affect only the separately compiled fake child. Task 1's explicit hidden named-event cleanup barrier parameters are a separate launcher test seam and remain default-null in Task 2.

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
- [ ] **Nonzero child exit**, **drain failure**, **scan failure/match**, or **any source branch/upstream/HEAD/status/actual-hash drift** (from pinned expected path set) → **exit 1**. If the complete ordinary temp-parent/root path and both captured identities still match, preserve and print `PRESERVED_MIRROR: <absolute path>`; if either identity is lost, refuse deletion and print `MIRROR_IDENTITY_LOST: last-known-path=<path> captured-identity=<identity>` without claiming the current lexical path is the mirror.
- [ ] **Never copy back** any files from mirror to source.
- [ ] On success: revalidate exact owned root and all descendants, cleanup, confirm absence (`Test-Path $Root` → `False`), then print:
  ```
  PASS: editor playtest completed
  DIAGNOSTICS_SCANNED: <count>
  ```
  and **exit 0**.

### Task 2 Production Functions (Actual PowerShell Code)

Replace Task 1's `Mode` parameter with `[ValidateSet('Launch','VerifyMirror')] [string]$Mode = 'Launch'`. Preserve `Wait-TestCleanupBarrier` and the hidden named-event parameters. Add these functions, then replace Task 1's terminal snapshot/cleanup block with the mode branch and launch flow below, all inside the existing guarded `try`/`catch`:

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
    Wait-TestCleanupBarrier
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

Wait-TestCleanupBarrier
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
        [string]$GitExecutable, [string]$TempParent,
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
        '-GitExecutable',$GitExecutable,
        '-TempParent',$TempParent,'-Mode','Launch'
    )) { $psi.ArgumentList.Add($argument) }
    $null = $psi.Environment.Remove('MOERAIL_FAKE_VERSION')
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

# This is the Task 2 RED against the committed Task 1 launcher. After Launch
# exists, the same probe is a clean success and its mirror must be removed.
$availabilityCapture = Join-Path $testTempParent 'launch-availability-capture.txt'
$controllerEnvironmentBefore = [ordered]@{
    APPDATA=$env:APPDATA; LOCALAPPDATA=$env:LOCALAPPDATA; TEMP=$env:TEMP; TMP=$env:TMP
}
$availabilityRootsBefore = @(Get-MoerailDirs -TempParent $testTempParent)
$availabilitySourceBefore = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
$availability = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot `
    -GodotExecutable $fakeGodotExe -GitExecutable $gitExe `
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
        -GodotExecutable $fakeGodotExe -GitExecutable $gitExe `
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
        -GodotExecutable $fakeGodotExe -GitExecutable $gitExe `
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
    -GodotExecutable $fakeGodotExe -GitExecutable $gitExe `
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
    -GodotExecutable $fakeGodotExe -GitExecutable $gitExe `
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
  - On failure with the captured temp-parent/root identities still reachable at the original ordinary path: launcher exits 1, prints `PRESERVED_MIRROR: <path>`, and leaves the mirror intact for inspection. If either identity is lost, it refuses deletion and instead prints `MIRROR_IDENTITY_LOST: last-known-path=<path> captured-identity=<identity>`.
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

### Task 2 Default-Argument Manual Finding Amendment

The first committed Task 2 manual attempt exited 2 before any Godot window opened with `Preflight failed: Exception calling "GetFullPath" with "1" argument(s): "The path is empty."` The manual fixture, feature worktree, and protected primary worktree remained byte-identical and clean, and both validated manual roots were removed. The cause is binding behavior for omitted typed PowerShell strings: null-only guards do not recognize the empty `GitExecutable` and `TempParent` values used by the documented no-override command.

Before retrying manual verification:

1. Require independent Sol specification and quality review of this amendment. Then compare the full porcelain output with this exact two-document allowlist, stage only these paths, verify the staged set order-independently, commit, and require clean porcelain:

   ```powershell
   $expectedDocsPorcelain = @(
       ' M docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md',
       ' M docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md'
   ) | Sort-Object
   $actualDocsPorcelain = @(git status --porcelain=v1 -u | Sort-Object)
   if ($LASTEXITCODE -ne 0 -or ($actualDocsPorcelain -join "`n") -ne ($expectedDocsPorcelain -join "`n")) { exit 1 }
   git add -- `
       docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md `
       docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md
   if ($LASTEXITCODE -ne 0) { exit 1 }
   $expectedDocsStaged = @(
       'docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md',
       'docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md'
   ) | Sort-Object
   $actualDocsStaged = @(git diff --cached --name-only | Sort-Object)
   if ($LASTEXITCODE -ne 0 -or ($actualDocsStaged -join "`n") -ne ($expectedDocsStaged -join "`n")) { exit 1 }
   git commit -m "docs: cover default launcher arguments"
   if ($LASTEXITCODE -ne 0) { exit 1 }
   $porcelain = @(git status --porcelain=v1 -u)
   if ($LASTEXITCODE -ne 0 -or $porcelain.Count -ne 0) { exit 1 }
   ```

2. Add this focused test helper beside `Invoke-Launcher`. Its `Omitted` case intentionally adds neither optional argument; its `Whitespace` case explicitly adds both whitespace-only values:

   ```powershell
   function Invoke-LauncherWithDefaultGitAndTemp {
       param(
           [string]$LauncherPath,
           [string]$RepositoryRoot,
           [string]$GodotExecutable,
           [ValidateSet('Omitted','Whitespace')]
           [string]$Case
       )
       $psi = [Diagnostics.ProcessStartInfo]::new()
       $psi.FileName = (Get-Command pwsh.exe -ErrorAction Stop).Source
       $psi.UseShellExecute = $false
       $psi.RedirectStandardOutput = $true
       $psi.RedirectStandardError = $true
       foreach ($argument in @(
           '-NoProfile','-File',$LauncherPath,
           '-RepositoryRoot',$RepositoryRoot,
           '-GodotExecutable',$GodotExecutable,
           '-Mode','VerifyMirror'
       )) { $psi.ArgumentList.Add($argument) }
       if ($Case -eq 'Whitespace') {
           foreach ($argument in @('-GitExecutable',' ','-TempParent',' ')) {
               $psi.ArgumentList.Add($argument)
           }
       }
       $null = $psi.Environment.Remove('MOERAIL_FAKE_VERSION')
       $process = [Diagnostics.Process]::Start($psi)
       try {
           $stdoutTask = $process.StandardOutput.ReadToEndAsync()
           $stderrTask = $process.StandardError.ReadToEndAsync()
           $process.WaitForExit()
           if (-not [Threading.Tasks.Task]::WaitAll(
               [Threading.Tasks.Task[]]@($stdoutTask,$stderrTask),
               [TimeSpan]::FromSeconds(5)
           )) { throw 'Default Git/Temp capture drain timed out' }
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
   ```

3. Add these parameterized assertions after the clean fixture is created. They cover omitted and whitespace-only values, source preservation, and the complete top-level system-temp mirror-root set:

   ```powershell
   foreach ($defaultCase in @('Omitted','Whitespace')) {
       $defaultFixtureBefore = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
       $defaultRootsBefore = @(Get-MoerailDirs -TempParent $systemTempParent)
       $defaultResult = Invoke-LauncherWithDefaultGitAndTemp `
           -LauncherPath $launcherPath `
           -RepositoryRoot $cloneRoot `
           -GodotExecutable $fakeGodotExe `
           -Case $defaultCase
       Assert-ExitCode -Expected 0 -Actual $defaultResult.ExitCode `
           -Message " (default Git/Temp $defaultCase; stderr=$($defaultResult.Stderr.Trim()))"
       Assert-OutputContains -Needle 'PASS: editor playtest mirror verified' `
           -Haystack $defaultResult.Stdout -Message " (default Git/Temp $defaultCase marker)"
       $defaultRootsAfter = @(Get-MoerailDirs -TempParent $systemTempParent)
       Assert-DirectorySetUnchanged -TempParent $systemTempParent `
           -Before $defaultRootsBefore -After $defaultRootsAfter `
           -Message " (default Git/Temp $defaultCase)"
       $defaultFixtureAfter = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
       Assert-FixtureSnapshotUnchanged -Before $defaultFixtureBefore -After $defaultFixtureAfter
   }
   ```

4. With only the test file modified, require the exact porcelain line ` M godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1`, run `pwsh -NoProfile -File godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1`, and require nonzero RED against `6030a003d4d895e1dd4c0643db9a16eb742b76a5`. The failure must report exit 2 and the empty-path preflight diagnostic for the `Omitted` case.
5. Replace only the two null-only default guards with `[string]::IsNullOrWhiteSpace`, then require tooling GREEN and the exact five Godot regressions.
6. Compare the full porcelain output with this exact implementation allowlist, stage only these paths, verify the staged set order-independently, commit, and require clean porcelain:

   ```powershell
   $expectedFixPorcelain = @(
       ' M godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1',
       ' M godot-project-moe-rail-way/tools/playtest/launch_editor_playtest.ps1'
   ) | Sort-Object
   $actualFixPorcelain = @(git status --porcelain=v1 -u | Sort-Object)
   if ($LASTEXITCODE -ne 0 -or ($actualFixPorcelain -join "`n") -ne ($expectedFixPorcelain -join "`n")) { exit 1 }
   git add -- `
       godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1 `
       godot-project-moe-rail-way/tools/playtest/launch_editor_playtest.ps1
   if ($LASTEXITCODE -ne 0) { exit 1 }
   $expectedFixStaged = @(
       'godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1',
       'godot-project-moe-rail-way/tools/playtest/launch_editor_playtest.ps1'
   ) | Sort-Object
   $actualFixStaged = @(git diff --cached --name-only | Sort-Object)
   if ($LASTEXITCODE -ne 0 -or ($actualFixStaged -join "`n") -ne ($expectedFixStaged -join "`n")) { exit 1 }
   git commit -m "fix: resolve launcher default arguments"
   if ($LASTEXITCODE -ne 0) { exit 1 }
   $porcelain = @(git status --porcelain=v1 -u)
   if ($LASTEXITCODE -ne 0 -or $porcelain.Count -ne 0) { exit 1 }
   ```

7. Restart the complete manual verification from its first step. Record both the failed attempt and the successful retry in the ignored English Task 2 report before separate Sol specification and quality/code reviews.

---

### Task 2 Windows CRLF Manual Marker Amendment

The successful retry naturally exited 0 and emitted both required marker lines, but the original multiline regexes falsely rejected redirected Windows CRLF because `\r` remained before each `$` anchor. Keep the marker text and line anchoring strict while permitting only the optional carriage return that precedes `\n`: use `(?m)^PASS: editor playtest completed\r?$` and `(?m)^DIAGNOSTICS_SCANNED: \d+\r?$`. Reapply these corrected checks to the already captured stdout before accepting the manual evidence.

---

### Task 2 Cleanup-State and Child-Exit Quality Amendment

Independent Sol quality review of `a00b2c038db614358bd6331d86103fa63c74dbc5..dea9892eff27066f14f062c1b42556748c00d918` identified three binding gaps. A recursive removal can partially succeed before throwing, so its remaining path is not necessarily an intact preserved mirror. The cleanup-junction test must prove the external target and source fixture are unchanged. The fake child must also exercise a nonzero natural exit after producing otherwise valid logs. This amendment supersedes the earlier Task 2 wording wherever the two conflict.

#### Exact output-state contract

The launcher has three mutually exclusive post-creation failure states:

1. `PRESERVED_MIRROR: <path>` — recursive removal has not started, the captured root identity is still reachable at the original ordinary path, and the mirror remains intact for inspection.
2. `CLEANUP_REMNANTS: <path>` — recursive removal started and then failed, the captured root identity is still reachable, and remaining contents may be partial.
3. `MIRROR_IDENTITY_LOST: last-known-path=<path> captured-identity=<identity>` — the captured root identity is no longer reachable at the original path; do not claim that the lexical path is preserved or delete through it.

`MIRROR_CREATION_FAILED` remains the pre-identity state when no captured root identity exists.

Add one script-scoped flag beside the captured identities and set it only after final cleanup revalidation, immediately before `Remove-Item`:

```powershell
$CapturedRepositoryIdentity = $null
$CapturedTempParentIdentity = $null
$CapturedRootIdentity = $null
$CleanupRemovalStarted = $false
```

```powershell
function Remove-OwnedRoot {
    param(
        [string]$Root,
        [string]$ResolvedTempParent
    )

    $canonicalRoot = Assert-OwnedRoot -Root $Root -ResolvedTempParent $ResolvedTempParent -RequireExists $true
    $script:CleanupRemovalStarted = $true
    Remove-Item -LiteralPath $canonicalRoot -Recurse -Force -ErrorAction Stop
    if (Test-Path -LiteralPath $canonicalRoot) {
        throw "Root still exists after removal: $canonicalRoot"
    }
}
```

In the outer catch, retain the existing identity-lost and creation-failed branches, but replace the reachable-root branch with:

```powershell
if ($rootIdentityStillMatches) {
    if ($script:CleanupRemovalStarted) {
        Write-Host "CLEANUP_REMNANTS: $Root"
    } else {
        Write-Host "PRESERVED_MIRROR: $Root"
    }
}
```

The test-owned fake child gains a deterministic, child-only nonzero-exit seam after writing valid capture/log files and completing any ready/release handshake:

```csharp
string requestedExitCode = Environment.GetEnvironmentVariable("MOERAIL_TEST_EXIT_CODE");
if (!String.IsNullOrEmpty(requestedExitCode)) {
    int exitCode;
    if (!Int32.TryParse(requestedExitCode, out exitCode)) {
        return 7;
    }
    return exitCode;
}
return 0;
```

Every behavior-test `ProcessStartInfo` that starts the launcher must scrub this seam before intentional overrides, exactly as it already scrubs `MOERAIL_FAKE_VERSION`. Add the following line in `Invoke-Launcher`, `Invoke-LauncherWithDefaultGitAndTemp`, `Start-LauncherAsync`, the early-exit launcher block, and the identity-replacement launcher block. In `Invoke-Launcher`, it must appear after `InheritedEnvSeed` is applied and immediately before `EnvOverrides`; in each other location, it must appear after process setup and before any intentional environment override is applied:

```powershell
$null = $psi.Environment.Remove('MOERAIL_TEST_EXIT_CODE')
```

Use the corresponding local variable (`$earlyPsi` or `$identityPsi`) in the two custom blocks.

#### Required RED and GREEN sequence

1. Begin at a clean, independently reviewed documentation commit whose parent is exactly `dea9892eff27066f14f062c1b42556748c00d918`.
2. **Cleanup-marker RED:** edit only `godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1`. Change the locked cleanup-removal case to expect `CLEANUP_REMNANTS`, capture the source fixture before launch, and prove it is unchanged after the held file is released. Strengthen the cleanup-junction case at the same time: create an ordinary external target, write a fixed-byte sentinel into it, snapshot the source fixture, and after launcher failure prove the mirror-side path remains a junction, the external target remains an ordinary directory, the sentinel bytes are exact, and the source fixture snapshot is unchanged. Remove the junction before removing the external target. Run the tooling test and record its nonzero exit plus the old `PRESERVED_MIRROR`/missing `CLEANUP_REMNANTS` assertion as the first independent RED.
3. **Cleanup-marker minimal GREEN:** edit only the launcher in addition to the already changed test. Add the cleanup-started flag, set it at the exact point shown above, and split the reachable-root output marker. Run the complete tooling test and require GREEN before continuing.
4. **Child-exit RED:** edit only the tooling test in addition to the two already changed files. Add the ambient `MOERAIL_TEST_EXIT_CODE` removals to all five launcher-starting `ProcessStartInfo` paths. First add a normal Launch case with a unique capture file, using `InheritedEnvSeed = @{ MOERAIL_TEST_EXIT_CODE = '23' }` and `EnvOverrides = @{ MOERAIL_TEST_CAPTURE_PATH = $ambientExitCapture }`; this has no intentional exit-code override and must require launcher exit 0, the normal PASS marker, no leaked mirror root, a created capture file, and an unchanged source fixture snapshot. Then add a separate launch case with another unique capture file and `EnvOverrides = @{ MOERAIL_TEST_CAPTURE_PATH = $intentionalExitCapture; MOERAIL_TEST_EXIT_CODE = '23' }`; it expects launcher exit 1, `Godot editor exited 23`, `PRESERVED_MIRROR`, one validated new mirror root, a created capture file, and an unchanged source fixture snapshot. Do not add the fake-child exit seam yet. Run the tooling test again; the existing fake child returns 0, so the ambient regression passes but the intentional case records the second independent RED as expected-1/actual-0. Remove each capture file only after its assertions and any validated mirror cleanup complete.
5. **Child-exit minimal GREEN:** add only the fake-child seam shown above, then update README with the three-state wording. Run the complete tooling test and require GREEN. Validate and remove only test-owned RED roots after file handles release naturally; never terminate a process to unlock them.
6. README must say that `PRESERVED_MIRROR` is intact because removal has not started, `CLEANUP_REMNANTS` may be partial because removal started, and `MIRROR_IDENTITY_LOST` is only a last-known path/identity report.
7. Run the five exact Godot regression scripts separately, then execute the exact implementation commit gate below.
8. Rerun the tooling test and all five regressions against the commit. Restart the complete manual verification from its first step because launcher behavior changed. Update the ignored English Task 2 report, then obtain independent Sol specification and quality/code reviews over the full Task 2 range and current evidence.

#### Documentation review and commit gate

Require separate independent Sol specification and quality reviews of this amendment before staging it. Both must return `APPROVED`. Then run exactly:

```powershell
$documentationBase = (git rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $documentationBase -cne 'dea9892eff27066f14f062c1b42556748c00d918') { exit 1 }

$expectedDocumentationPorcelain = @(
    ' M docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md',
    ' M docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md'
) | Sort-Object
$actualDocumentationPorcelain = @(git status --porcelain=v1 -u) | Sort-Object
if ($LASTEXITCODE -ne 0 -or ($actualDocumentationPorcelain -join "`n") -ne ($expectedDocumentationPorcelain -join "`n")) { exit 1 }

$documentationPaths = @(
    'docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md',
    'docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md'
) | Sort-Object
git add -- docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md
if ($LASTEXITCODE -ne 0) { exit 1 }
$stagedDocumentationPaths = @(git diff --cached --name-only | ForEach-Object { $_.Replace('\','/') } | Sort-Object)
if ($LASTEXITCODE -ne 0 -or ($stagedDocumentationPaths -join "`n") -ne ($documentationPaths -join "`n")) { exit 1 }
git diff --cached --check
if ($LASTEXITCODE -ne 0) { exit 1 }
git commit -m "docs: distinguish cleanup remnants"
if ($LASTEXITCODE -ne 0) { exit 1 }
$documentationParent = (git rev-parse 'HEAD^').Trim()
if ($LASTEXITCODE -ne 0 -or $documentationParent -cne 'dea9892eff27066f14f062c1b42556748c00d918') { exit 1 }
$documentationSubject = (git log -1 --format=%s).Trim()
if ($LASTEXITCODE -ne 0 -or $documentationSubject -cne 'docs: distinguish cleanup remnants') { exit 1 }
$porcelain = @(git status --porcelain=v1 -u)
if ($LASTEXITCODE -ne 0 -or $porcelain.Count -ne 0) { exit 1 }
```

#### Implementation commit gate

After both RED/GREEN cycles, tooling GREEN, and the five exact regressions, run exactly:

```powershell
$implementationBaseParent = (git rev-parse 'HEAD^').Trim()
$implementationBaseSubject = (git log -1 --format=%s).Trim()
$implementationBasePaths = @(git diff-tree --no-commit-id --name-only -r HEAD | ForEach-Object { $_.Replace('\','/') } | Sort-Object)
$expectedDocumentationPaths = @(
    'docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md',
    'docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md'
) | Sort-Object
if ($LASTEXITCODE -ne 0 `
    -or $implementationBaseParent -cne 'dea9892eff27066f14f062c1b42556748c00d918' `
    -or $implementationBaseSubject -cne 'docs: distinguish cleanup remnants' `
    -or ($implementationBasePaths -join "`n") -ne ($expectedDocumentationPaths -join "`n")) { exit 1 }

$expectedImplementationPorcelain = @(
    ' M README.md',
    ' M godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1',
    ' M godot-project-moe-rail-way/tools/playtest/launch_editor_playtest.ps1'
) | Sort-Object
$actualImplementationPorcelain = @(git status --porcelain=v1 -u) | Sort-Object
if ($LASTEXITCODE -ne 0 -or ($actualImplementationPorcelain -join "`n") -ne ($expectedImplementationPorcelain -join "`n")) { exit 1 }

$implementationPaths = @(
    'README.md',
    'godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1',
    'godot-project-moe-rail-way/tools/playtest/launch_editor_playtest.ps1'
) | Sort-Object
git add -- README.md godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1 godot-project-moe-rail-way/tools/playtest/launch_editor_playtest.ps1
if ($LASTEXITCODE -ne 0) { exit 1 }
$stagedImplementationPaths = @(git diff --cached --name-only | ForEach-Object { $_.Replace('\','/') } | Sort-Object)
if ($LASTEXITCODE -ne 0 -or ($stagedImplementationPaths -join "`n") -ne ($implementationPaths -join "`n")) { exit 1 }
git diff --cached --check
if ($LASTEXITCODE -ne 0) { exit 1 }
git commit -m "fix: distinguish cleanup remnants"
if ($LASTEXITCODE -ne 0) { exit 1 }
$porcelain = @(git status --porcelain=v1 -u)
if ($LASTEXITCODE -ne 0 -or $porcelain.Count -ne 0) { exit 1 }
```

---

### Task 2 Fake-Compiler Build-Server Isolation Amendment

At clean `040c6bc0da38fc5078f77d7032a7757bdb82f2a8`, the final fresh tooling run reached its final test-root cleanup and exited 1. `Remove-Item` was denied at `temp\VBCSCompiler\AnalyzerAssemblyLoader\...\Microsoft.Interop.JavaScript.JSImportGenerator.dll`. No process was enumerated or terminated. This observed exit-1 cleanup failure is the RED evidence for this focused follow-up.

The Microsoft [`dotnet publish` contract](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-publish) defines `--disable-build-servers` as ignoring persistent build servers. Roslyn's [`ManagedCompiler` source](https://github.com/dotnet/roslyn/blob/main/src/Compilers/Core/MSBuildTask/ManagedCompiler.cs) routes compilation through the compiler server only when shared compilation is enabled. Therefore the exact minimal implementation change is limited to `godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1`: add both `'--disable-build-servers'` and `'-p:UseSharedCompilation=false'` to the existing `dotnet publish` argument array. Retain the unique child-only `DOTNET_CLI_HOME`, `TEMP`, `TMP`, and NuGet roots. Do not call `dotnet build-server shutdown`, enumerate build-server processes, or terminate any process.

#### Required sequence

1. Obtain separate independent Sol specification and quality reviews of this amendment. Both must return `APPROVED` before staging the documents.
2. Execute the documentation gate below and record its clean commit SHA.
3. Retain the observed fresh-tooling exit 1 above as RED. Make only the exact two-argument addition to the tooling test.
4. Run the complete tooling test and require `PASS: editor playtest tooling tests` plus exit 0 and no leaked root from that run. Run the five exact Godot regressions separately and require exit 0 plus zero line-anchored prohibited diagnostics for each.
5. Execute the implementation gate below. Rerun tooling and all five regressions against the commit.
6. Restart the complete manual verification from its first step, update the ignored English Task 2 report, and obtain final independent Sol specification and quality/code reviews over the complete Task 2 range and evidence.
7. Rerun the fresh feature completion gate. Any test-root cleanup failure remains a gate failure; wait for natural handle release, revalidate the exact test-owned root, and remove it without process interference.

#### Documentation review and commit gate

```powershell
$documentationBase = (git rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $documentationBase -cne '040c6bc0da38fc5078f77d7032a7757bdb82f2a8') { exit 1 }
$expectedDocumentationPorcelain = @(
    ' M docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md',
    ' M docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md'
) | Sort-Object
$actualDocumentationPorcelain = @(git status --porcelain=v1 -u) | Sort-Object
if ($LASTEXITCODE -ne 0 -or ($actualDocumentationPorcelain -join "`n") -ne ($expectedDocumentationPorcelain -join "`n")) { exit 1 }
$documentationPaths = @(
    'docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md',
    'docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md'
) | Sort-Object
git add -- docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md
if ($LASTEXITCODE -ne 0) { exit 1 }
$stagedDocumentationPaths = @(git diff --cached --name-only | ForEach-Object { $_.Replace('\','/') } | Sort-Object)
if ($LASTEXITCODE -ne 0 -or ($stagedDocumentationPaths -join "`n") -ne ($documentationPaths -join "`n")) { exit 1 }
git diff --cached --check
if ($LASTEXITCODE -ne 0) { exit 1 }
git commit -m "docs: isolate fake compiler build"
if ($LASTEXITCODE -ne 0) { exit 1 }
$documentationParent = (git rev-parse 'HEAD^').Trim()
$documentationSubject = (git log -1 --format=%s).Trim()
if ($LASTEXITCODE -ne 0 -or $documentationParent -cne '040c6bc0da38fc5078f77d7032a7757bdb82f2a8' -or $documentationSubject -cne 'docs: isolate fake compiler build') { exit 1 }
$porcelain = @(git status --porcelain=v1 -u)
if ($LASTEXITCODE -ne 0 -or $porcelain.Count -ne 0) { exit 1 }
```

#### Tooling-test commit gate

```powershell
$implementationBaseParent = (git rev-parse 'HEAD^').Trim()
$implementationBaseSubject = (git log -1 --format=%s).Trim()
$implementationBasePaths = @(git diff-tree --no-commit-id --name-only -r HEAD | ForEach-Object { $_.Replace('\','/') } | Sort-Object)
$expectedDocumentationPaths = @(
    'docs/superpowers/plans/2026-08-25-godot-editor-playtest-safety.md',
    'docs/superpowers/specs/2026-08-25-godot-editor-playtest-safety-design.md'
) | Sort-Object
if ($LASTEXITCODE -ne 0 `
    -or $implementationBaseParent -cne '040c6bc0da38fc5078f77d7032a7757bdb82f2a8' `
    -or $implementationBaseSubject -cne 'docs: isolate fake compiler build' `
    -or ($implementationBasePaths -join "`n") -ne ($expectedDocumentationPaths -join "`n")) { exit 1 }
$expectedImplementationPorcelain = @(' M godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1')
$actualImplementationPorcelain = @(git status --porcelain=v1 -u)
if ($LASTEXITCODE -ne 0 -or ($actualImplementationPorcelain -join "`n") -ne ($expectedImplementationPorcelain -join "`n")) { exit 1 }
$implementationPath = 'godot-project-moe-rail-way/tests/tooling/test_launch_editor_playtest.ps1'
git add -- $implementationPath
if ($LASTEXITCODE -ne 0) { exit 1 }
$stagedImplementationPaths = @(git diff --cached --name-only | ForEach-Object { $_.Replace('\','/') } | Sort-Object)
if ($LASTEXITCODE -ne 0 -or ($stagedImplementationPaths -join "`n") -ne $implementationPath) { exit 1 }
git diff --cached --check
if ($LASTEXITCODE -ne 0) { exit 1 }
git commit -m "test: isolate fake compiler build"
if ($LASTEXITCODE -ne 0) { exit 1 }
$porcelain = @(git status --porcelain=v1 -u)
if ($LASTEXITCODE -ne 0 -or $porcelain.Count -ne 0) { exit 1 }
```

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
  if ($manualStdout -notmatch '(?m)^PASS: editor playtest completed\r?$') { exit 1 }
  if ($manualStdout -notmatch '(?m)^DIAGNOSTICS_SCANNED: \d+\r?$') { exit 1 }
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
