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
        string requestedExitCode = Environment.GetEnvironmentVariable("MOERAIL_TEST_EXIT_CODE");
        if (!String.IsNullOrEmpty(requestedExitCode)) {
            int exitCode;
            if (!Int32.TryParse(requestedExitCode, out exitCode)) return 7;
            return exitCode;
        }
        return 0;
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
        '--disable-build-servers','-p:UseSharedCompilation=false',
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
    $null = $psi.Environment.Remove('MOERAIL_TEST_EXIT_CODE')
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
    $null = $psi.Environment.Remove('MOERAIL_TEST_EXIT_CODE')
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
    $null = $psi.Environment.Remove('MOERAIL_TEST_EXIT_CODE')
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
    $null = $earlyPsi.Environment.Remove('MOERAIL_TEST_EXIT_CODE')
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
    $null = $identityPsi.Environment.Remove('MOERAIL_TEST_EXIT_CODE')
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

# Ambient test-only exit code is scrubbed before intentional overrides.
$ambientExitRootsBefore = @(Get-MoerailDirs -TempParent $testTempParent)
$ambientExitSourceBefore = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
$ambientExitCapture = Join-Path $testTempParent 'ambient-exit-capture.txt'
$ambientExitResult = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot `
    -GodotExecutable $fakeGodotExe -GitExecutable $gitExe `
    -Mode Launch -TempParent $testTempParent `
    -InheritedEnvSeed @{ MOERAIL_TEST_EXIT_CODE='23' } `
    -EnvOverrides @{ MOERAIL_TEST_CAPTURE_PATH=$ambientExitCapture }
Assert-ExitCode -Expected 0 -Actual $ambientExitResult.ExitCode -Message ' (ambient exit-code sanitization)'
Assert-OutputContains -Needle 'PASS: editor playtest completed' -Haystack $ambientExitResult.Stdout -Message ' (ambient exit-code sanitization marker)'
if (-not (Test-Path -LiteralPath $ambientExitCapture -PathType Leaf)) { throw 'Ambient exit-code capture missing' }
$ambientExitRootsAfter = @(Get-MoerailDirs -TempParent $testTempParent)
Assert-DirectorySetUnchanged -TempParent $testTempParent -Before $ambientExitRootsBefore -After $ambientExitRootsAfter -Message ' (ambient exit-code sanitization)'
$ambientExitSourceAfter = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
Assert-FixtureSnapshotUnchanged -Before $ambientExitSourceBefore -After $ambientExitSourceAfter
Remove-Item -LiteralPath $ambientExitCapture -Force -ErrorAction Stop

# An intentional child exit after valid logs is a launcher failure.
$intentionalExitRootsBefore = @(Get-MoerailDirs -TempParent $testTempParent)
$intentionalExitSourceBefore = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
$intentionalExitCapture = Join-Path $testTempParent 'intentional-exit-capture.txt'
$intentionalExitResult = Invoke-Launcher -LauncherPath $launcherPath -RepositoryRoot $cloneRoot `
    -GodotExecutable $fakeGodotExe -GitExecutable $gitExe `
    -Mode Launch -TempParent $testTempParent -EnvOverrides @{
        MOERAIL_TEST_CAPTURE_PATH=$intentionalExitCapture
        MOERAIL_TEST_EXIT_CODE='23'
    }
Assert-ExitCode -Expected 1 -Actual $intentionalExitResult.ExitCode -Message ' (intentional child exit)'
$intentionalExitCombined = $intentionalExitResult.Stdout + $intentionalExitResult.Stderr
Assert-OutputContains -Needle 'Godot editor exited 23' -Haystack $intentionalExitCombined -Message ' (intentional child exit diagnostic)'
Assert-OutputContains -Needle 'PRESERVED_MIRROR:' -Haystack $intentionalExitCombined -Message ' (intentional child exit preservation)'
if (-not (Test-Path -LiteralPath $intentionalExitCapture -PathType Leaf)) { throw 'Intentional child-exit capture missing' }
$intentionalExitPreserved = Get-OnlyNewMirrorRoot -Before $intentionalExitRootsBefore -TempParent $testTempParent
Assert-TestMirrorRoot -Root $intentionalExitPreserved -ResolvedTempParent $testTempParent | Out-Null
$intentionalExitSourceAfter = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
Assert-FixtureSnapshotUnchanged -Before $intentionalExitSourceBefore -After $intentionalExitSourceAfter
Remove-TestMirrorRoot -Root $intentionalExitPreserved -ResolvedTempParent $testTempParent
Remove-Item -LiteralPath $intentionalExitCapture -Force -ErrorAction Stop

# Cleanup pre-removal revalidation: a junction descendant must preserve the mirror.
$beforeRoots = @(Get-MoerailDirs -TempParent $testTempParent)
$junctionSourceBefore = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
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
$junctionTargetItem = Get-Item -LiteralPath $junctionTarget -Force -ErrorAction Stop
if (-not $junctionTargetItem.PSIsContainer -or ($junctionTargetItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw 'Cleanup junction target is not an ordinary directory'
}
$sentinel = Join-Path $junctionTarget 'sentinel.bin'
$expectedSentinelBytes = [byte[]](0x4d,0x52,0x57,0x01)
[IO.File]::WriteAllBytes($sentinel,$expectedSentinelBytes)
$junction = Join-Path $preserved 'cleanup-junction'
New-Item -ItemType Junction -Path $junction -Target $junctionTarget -ErrorAction Stop | Out-Null
[IO.File]::WriteAllText($release,'release',[Text.Encoding]::UTF8)
$result = Complete-LauncherAsync -Running $running
Assert-ExitCode -Expected 1 -Actual $result.ExitCode -Message ' (cleanup revalidation)'
Assert-OutputContains -Needle 'PRESERVED_MIRROR:' -Haystack ($result.Stdout+$result.Stderr)
$junctionItem = Get-Item -LiteralPath $junction -Force -ErrorAction Stop
if (($junctionItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) {
    throw 'Cleanup junction no longer has ReparsePoint'
}
$junctionTargetItem = Get-Item -LiteralPath $junctionTarget -Force -ErrorAction Stop
if (-not $junctionTargetItem.PSIsContainer -or ($junctionTargetItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw 'Cleanup junction target changed from an ordinary directory'
}
$actualSentinelBytes = [IO.File]::ReadAllBytes($sentinel)
if ($actualSentinelBytes.Length -ne $expectedSentinelBytes.Length) {
    throw 'Cleanup junction sentinel length changed'
}
for ($index = 0; $index -lt $expectedSentinelBytes.Length; $index++) {
    if ($actualSentinelBytes[$index] -ne $expectedSentinelBytes[$index]) {
        throw "Cleanup junction sentinel byte changed at index $index"
    }
}
$junctionSourceAfter = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
Assert-FixtureSnapshotUnchanged -Before $junctionSourceBefore -After $junctionSourceAfter
Remove-Item -LiteralPath $junction -Force -ErrorAction Stop
Remove-Item -LiteralPath $junctionTarget -Recurse -Force -ErrorAction Stop
Remove-TestMirrorRoot -Root $preserved -ResolvedTempParent $testTempParent
foreach ($path in @($ready,$release,$capture)) { Remove-Item -LiteralPath $path -Force -ErrorAction Stop }

# Cleanup removal failure: an ordinary non-log file denies delete sharing.
$beforeRoots = @(Get-MoerailDirs -TempParent $testTempParent)
$heldSourceBefore = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
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
    Assert-OutputContains -Needle 'CLEANUP_REMNANTS:' -Haystack ($result.Stdout+$result.Stderr)
} finally {
    $held.Dispose()
}
$heldSourceAfter = Get-FixtureSnapshot -RepositoryRoot $cloneRoot
Assert-FixtureSnapshotUnchanged -Before $heldSourceBefore -After $heldSourceAfter
Remove-TestMirrorRoot -Root $preserved -ResolvedTempParent $testTempParent
foreach ($path in @($ready,$release,$capture)) { Remove-Item -LiteralPath $path -Force -ErrorAction Stop }

Assert-TestOwnedRoot -Root $testTempParent -ResolvedTempParent $systemTempParent -RequireExists $true | Out-Null
Remove-Item -LiteralPath $testTempParent -Recurse -Force -ErrorAction Stop
if (Test-Path -LiteralPath $testTempParent) { throw "Test temp parent still exists after cleanup: $testTempParent" }
Write-Host 'PASS: editor playtest tooling tests'
