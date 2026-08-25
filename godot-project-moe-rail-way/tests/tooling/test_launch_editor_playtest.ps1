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
