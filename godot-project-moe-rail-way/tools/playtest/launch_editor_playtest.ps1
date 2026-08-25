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
    if ($null -eq $GitExecutable) { $GitExecutable = (Get-Command git.exe -ErrorAction Stop).Source }
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
if ($null -eq $TempParent) { $TempParent = [IO.Path]::GetTempPath() }
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
