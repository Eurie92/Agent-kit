<#
.SYNOPSIS
  Wire Agent-kit rules and skills into Claude Code, Antigravity (Gemini) and Codex.

.DESCRIPTION
  Idempotent: running it twice gives the same result.
  Rule sources: rules/GLOBAL.md (shared) plus local/MODELS.md and local/PREFS.md (personal, git-ignored,
  written by the setup skill). If a local file is missing, it stops before changing anything.
  - Claude:      adds @imports of the three rule files to ~/.claude/CLAUDE.md
                 (a copy of the rules instead, if the kit path has a space)
  - Antigravity: copies the rules into ~/.gemini/GEMINI.md (T3 Code's Antigravity does not load
                 rule files; the handoff boot step and project AGENTS.md point to the kit rules)
  - Codex:      copies the rules into ~/.codex/AGENTS.md
  Each harness gets a marked block (agent-kit:start / agent-kit:end) that is updated in place;
  text outside it is never touched.
  Claude and Codex skills are linked with directory junctions (no admin or Developer Mode needed), so
  kit edits are live. Antigravity does not follow junctions in its skills folder, so it gets copies
  (each with a .agent-kit-copy marker file). Links or copies of skills removed from the kit are pruned.
  Copied rules and Antigravity skills need a re-run after you edit the kit.
  If T3 Code home ($env:T3CODE_HOME, or ~/.t3) exists, starter bot template.json files are copied to
  <T3 home>/bots/templates/kit-<name>/template.json regardless of -Harness; otherwise skipped.
  Any file or copied skill it changes or removes is backed up first to ~/.agent-kit-backups/<timestamp>/.

.PARAMETER DryRun
  Show what would change. Change nothing.

.PARAMETER Harness
  Limit to some harnesses: claude, gemini, codex, comma-separated (for example -Harness claude,gemini). Default: all three.
  Starter bot templates for T3 Code still run when T3 home exists.

.PARAMETER Uninstall
  Remove the marked blocks, skill links/copies and kit-* bot template folders this script created.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File install\install.ps1 -DryRun
#>
[CmdletBinding()]
param(
  [switch]$DryRun,
  [string[]]$Harness = @('claude', 'gemini', 'codex'),
  [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

# "powershell -File" passes "-Harness claude,gemini" as one string, so split on commas here.
$Harness = @($Harness | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ } | Select-Object -Unique)
$badHarness = @($Harness | Where-Object { $_ -notin @('claude', 'gemini', 'codex') })
if ($Harness.Count -eq 0 -or $badHarness.Count -gt 0) {
  Write-Host "Unknown -Harness value: $($badHarness -join ', '). Use claude, gemini or codex, comma-separated."
  exit 1
}
$Kit = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path.TrimEnd('\')
$KitSkillsDir = Join-Path $Kit 'skills'
$KitBotTemplatesDir = Join-Path $Kit 'templates\bots\starters'
$HomeDir = $env:USERPROFILE.TrimEnd('\')
$T3Home = if (-not [string]::IsNullOrWhiteSpace($env:T3CODE_HOME)) { $env:T3CODE_HOME.Trim().TrimEnd('\', '/') } else { Join-Path $HomeDir '.t3' }
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupDir = Join-Path $HomeDir ".agent-kit-backups\$Stamp"
$Start = '<!-- agent-kit:start (managed by Agent-kit install.ps1; edits inside are overwritten) -->'
$End = '<!-- agent-kit:end -->'
$StartLine = '(?m)^<!-- agent-kit:start\b[^\n]*-->[ \t]*$'
$EndLine = '(?m)^<!-- agent-kit:end -->[ \t]*$'
$BlockRegex = '(?ms)^<!-- agent-kit:start\b[^\n]*-->[ \t]*\n.*?^<!-- agent-kit:end -->[ \t]*$'
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$CopyMarker = '.agent-kit-copy'
$RuleFiles = @('rules\GLOBAL.md', 'local\MODELS.md', 'local\PREFS.md')
$script:Changes = 0

if (-not $Uninstall) {
  $missing = @($RuleFiles | Where-Object { -not (Test-Path -LiteralPath (Join-Path $Kit $_)) })
  if ($missing.Count -gt 0) {
    Write-Host "Agent-kit: $Kit"
    Write-Host "Missing: $($missing -join ', '). Nothing was changed."
    Write-Host 'Run setup first: tell your agent "set up Agent-kit" (it follows INSTALL.md),'
    Write-Host 'or copy rules/MODELS.example.md to local/MODELS.md and write local/PREFS.md by hand.'
    exit 1
  }
}

function Write-Step([string]$Msg) {
  $prefix = if ($DryRun) { '[dry-run] ' } else { '' }
  Write-Host "$prefix$Msg"
}

function Backup-Item([string]$Path) {
  # Copies a file or folder to the backup dir, keeping its path relative to the home folder.
  if (-not (Test-Path -LiteralPath $Path)) { return }
  $rel = if ($Path.StartsWith("$HomeDir\", [StringComparison]::OrdinalIgnoreCase)) { $Path.Substring($HomeDir.Length + 1) } else { $Path.Replace(':', '') }
  $dest = Join-Path $BackupDir $rel
  if ($DryRun) { Write-Step "backup  $Path"; return }
  New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
  Copy-Item -LiteralPath $Path -Destination $dest -Recurse -Force
}

function Set-ManagedBlock([string]$Path, [string]$Body) {
  $old = ''
  if (Test-Path -LiteralPath $Path) { $old = [IO.File]::ReadAllText($Path) }
  $crlf = $old.Contains("`r`n")
  $text = $old.Replace("`r`n", "`n")
  $starts = [regex]::Matches($text, $StartLine).Count
  $ends = [regex]::Matches($text, $EndLine).Count
  $match = [regex]::Match($text, $BlockRegex)
  if ($starts -gt 1 -or $starts -ne $ends -or ($starts -eq 1 -and -not $match.Success)) {
    Write-Warning "skip    $Path has broken or duplicate agent-kit markers. Fix them by hand, then re-run."
    return
  }
  if ($Body) {
    $block = "$Start`n$($Body.Replace("`r`n", "`n").Trim())`n$End"
    if ($match.Success) {
      $new = $text.Substring(0, $match.Index) + $block + $text.Substring($match.Index + $match.Length)
    } else {
      $outside = $text.TrimEnd()
      $new = if ($outside) { "$outside`n`n$block`n" } else { "$block`n" }
    }
  } elseif ($match.Success) {
    $before = $text.Substring(0, $match.Index).TrimEnd()
    $after = $text.Substring($match.Index + $match.Length).TrimStart("`n")
    $new = if ($before -and $after) { "$before`n`n$after" } elseif ($before) { "$before`n" } else { $after }
  } else {
    $new = $text
  }
  if ($crlf) { $new = $new.Replace("`n", "`r`n") }
  if ($new -eq $old) { Write-Host "ok      $Path (no change)"; return }
  Backup-Item $Path
  $script:Changes++
  if (-not $new.Trim()) {
    Write-Step "delete  $Path (nothing left in it)"
    if (-not $DryRun) { Remove-Item -LiteralPath $Path -Force }
    return
  }
  Write-Step "write   $Path"
  if ($DryRun) { return }
  New-Item -ItemType Directory -Force -Path (Split-Path $Path) | Out-Null
  [IO.File]::WriteAllText($Path, $new, $Utf8)
}

function Get-KitSkills {
  Get-ChildItem -LiteralPath $KitSkillsDir -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') }
}

function Get-JunctionTarget([string]$Path) {
  $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
  if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    return [string]($item.Target | Select-Object -First 1)
  }
  return $null
}

function Test-KitPath([string]$Target, [string]$Name) {
  # True if $Target is <kit>\skills\<Name> (the folder may no longer exist).
  return $Target -and ($Target.TrimEnd('\') -ieq (Join-Path $KitSkillsDir $Name))
}

function Remove-Junction([string]$Path) {
  [IO.Directory]::Delete($Path)  # removes the junction only, never the folder it points to
}

function Remove-StaleSkills([string]$SkillsDir, [string[]]$Keep) {
  # Links or copies made by this script for skills that are no longer in the kit.
  if (-not (Test-Path -LiteralPath $SkillsDir)) { return }
  foreach ($item in Get-ChildItem -LiteralPath $SkillsDir -Force -Directory -ErrorAction SilentlyContinue) {
    if ($Keep -contains $item.Name) { continue }
    $target = Get-JunctionTarget $item.FullName
    if (Test-KitPath $target $item.Name) {
      $script:Changes++
      Write-Step "unlink  $($item.FullName) (skill no longer in the kit)"
      if (-not $DryRun) { Remove-Junction $item.FullName }
    } elseif (-not $target -and (Test-Path -LiteralPath (Join-Path $item.FullName $CopyMarker))) {
      Backup-Item $item.FullName
      $script:Changes++
      Write-Step "remove  $($item.FullName) (skill no longer in the kit)"
      if (-not $DryRun) { Remove-Item -LiteralPath $item.FullName -Recurse -Force }
    }
  }
}

function Set-SkillLinks([string]$SkillsDir) {
  $skills = @(Get-KitSkills)
  foreach ($skill in $skills) {
    $link = Join-Path $SkillsDir $skill.Name
    $target = Get-JunctionTarget $link
    $ours = Test-KitPath $target $skill.Name
    $dangling = $target -and -not (Test-Path -LiteralPath $target)
    if ($Uninstall) {
      if ($ours) {
        $script:Changes++
        Write-Step "unlink  $link"
        if (-not $DryRun) { Remove-Junction $link }
      }
      continue
    }
    if ($ours -and -not $dangling) { Write-Host "ok      $link (linked)"; continue }
    if ($target -and -not $ours -and -not $dangling) {
      Write-Warning "skip    $link is a link to $target, not to this kit. Move it, then re-run."
      continue
    }
    if (-not $target -and (Test-Path -LiteralPath $link)) {
      Write-Warning "skip    $link exists and is not an Agent-kit link. Move it, then re-run."
      continue
    }
    $script:Changes++
    $verb = if ($target) { 'relink' } else { 'link  ' }
    Write-Step "$verb  $link -> $($skill.FullName)"
    if ($DryRun) { continue }
    if ($target) { Remove-Junction $link }  # broken link, e.g. the kit was moved
    New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
    New-Item -ItemType Junction -Path $link -Target $skill.FullName | Out-Null
  }
  Remove-StaleSkills $SkillsDir ($skills | ForEach-Object { $_.Name })
}

function Get-DirSignature([string]$Dir) {
  # Relative path + SHA256 of every file, skipping our marker. Same signature = same content.
  $root = (Resolve-Path -LiteralPath $Dir).Path.TrimEnd('\')
  $lines = Get-ChildItem -LiteralPath $root -Recurse -File -Force |
    Where-Object { $_.Name -ne $CopyMarker } |
    ForEach-Object { $_.FullName.Substring($root.Length) + ':' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash } |
    Sort-Object
  return ($lines -join "`n")
}

function Set-SkillCopies([string]$SkillsDir) {
  # Antigravity does not follow junctions inside its skills folder, so Gemini gets real copies.
  # Each copy holds a marker file so the script knows it owns the folder.
  $skills = @(Get-KitSkills)
  foreach ($skill in $skills) {
    $dest = Join-Path $SkillsDir $skill.Name
    $target = Get-JunctionTarget $dest
    $oldLink = [bool]$target -and ((Test-KitPath $target $skill.Name) -or -not (Test-Path -LiteralPath $target))
    $isCopy = -not $target -and (Test-Path -LiteralPath (Join-Path $dest $CopyMarker))
    if ($Uninstall) {
      if ($oldLink -or $isCopy) {
        if ($isCopy) { Backup-Item $dest }
        $script:Changes++
        Write-Step "remove  $dest"
        if (-not $DryRun) {
          if ($oldLink) { Remove-Junction $dest } else { Remove-Item -LiteralPath $dest -Recurse -Force }
        }
      }
      continue
    }
    if ($target -and -not $oldLink) {
      Write-Warning "skip    $dest is a link to $target, not to this kit. Move it, then re-run."
      continue
    }
    if (-not $target -and -not $isCopy -and (Test-Path -LiteralPath $dest)) {
      Write-Warning "skip    $dest exists and is not an Agent-kit copy. Move it, then re-run."
      continue
    }
    if ($isCopy -and ((Get-DirSignature $dest) -eq (Get-DirSignature $skill.FullName))) {
      Write-Host "ok      $dest (copy up to date)"
      continue
    }
    $script:Changes++
    $verb = if ($oldLink) { 'relink' } elseif ($isCopy) { 'update' } else { 'copy  ' }
    Write-Step "$verb  $dest <- $($skill.FullName)"
    if ($isCopy) { Backup-Item $dest }
    if ($DryRun) { continue }
    if ($oldLink) { Remove-Junction $dest }
    elseif ($isCopy) { Remove-Item -LiteralPath $dest -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
    Copy-Item -LiteralPath $skill.FullName -Destination $dest -Recurse -Force
    [IO.File]::WriteAllText((Join-Path $dest $CopyMarker), "Copied by Agent-kit install.ps1 from $($skill.FullName). Edit the kit, then re-run install.ps1. Files added here are lost on the next run.`n", $Utf8)
  }
  Remove-StaleSkills $SkillsDir ($skills | ForEach-Object { $_.Name })
}

function Get-RulesText {
  $parts = $RuleFiles | ForEach-Object { [IO.File]::ReadAllText((Join-Path $Kit $_)).Trim() }
  return "<!-- Copied from $Kit (rules\GLOBAL.md, local\MODELS.md, local\PREFS.md). Edit there, then re-run install.ps1. -->`n`n" + ($parts -join "`n`n")
}

$targets = @{
  claude = @{
    Rules  = Join-Path $HomeDir '.claude\CLAUDE.md'
    Skills = Join-Path $HomeDir '.claude\skills'
    Body   = {
      $k = if ($Kit.StartsWith("$HomeDir\", [StringComparison]::OrdinalIgnoreCase)) { '~' + $Kit.Substring($HomeDir.Length) } else { $Kit }
      if ($k.Contains(' ')) {
        # @imports stop at a space, so copy the rules instead.
        Write-Warning "The kit path has a space, so Claude gets a copy of the rules. Re-run install.ps1 after editing them."
        Get-RulesText
      } else {
        (($RuleFiles | ForEach-Object { "@$k\$_" }) -join "`n").Replace('\', '/')
      }
    }
  }
  gemini = @{
    Rules  = Join-Path $HomeDir '.gemini\GEMINI.md'
    Skills = Join-Path $HomeDir '.gemini\config\skills'
    Copy   = $true
    Body   = { Get-RulesText }
  }
  codex  = @{
    Rules  = Join-Path $HomeDir '.codex\AGENTS.md'
    Skills = Join-Path $HomeDir '.agents\skills'
    Body   = { Get-RulesText }
  }
}

function Set-BotTemplates {
  $destRoot = Join-Path $T3Home 'bots\templates'
  Write-Host "`n== bot templates =="
  if (-not (Test-Path -LiteralPath $T3Home -PathType Container)) {
    Write-Host "skip    T3 Code not found at $T3Home; bot templates skipped"
    return
  }
  if (-not (Test-Path -LiteralPath $KitBotTemplatesDir -PathType Container)) { return }
  foreach ($dir in Get-ChildItem -LiteralPath $KitBotTemplatesDir -Directory | Sort-Object Name) {
    $src = Join-Path $dir.FullName 'template.json'
    if (-not (Test-Path -LiteralPath $src -PathType Leaf)) { continue }
    $destDir = Join-Path $destRoot ("kit-" + $dir.Name)
    $dest = Join-Path $destDir 'template.json'
    if ($Uninstall) {
      if (Test-Path -LiteralPath $destDir -PathType Container) {
        Backup-Item $destDir
        $script:Changes++
        Write-Step "remove  $destDir"
        if (-not $DryRun) { Remove-Item -LiteralPath $destDir -Recurse -Force }
      }
      continue
    }
    if ((Test-Path -LiteralPath $dest -PathType Leaf) -and ((Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash)) {
      Write-Host "ok      $dest (up to date)"
      continue
    }
    $exists = Test-Path -LiteralPath $dest
    $verb = if ($exists) { 'update' } else { 'copy  ' }
    if ($exists) { Backup-Item $dest }
    $script:Changes++
    Write-Step "$verb  $dest <- $src"
    if ($DryRun) { continue }
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    Copy-Item -LiteralPath $src -Destination $dest -Force
  }
  if ($Uninstall -and -not $DryRun -and (Test-Path -LiteralPath $destRoot -PathType Container)) {
    if (@(Get-ChildItem -LiteralPath $destRoot -Force).Count -eq 0) {
      Remove-Item -LiteralPath $destRoot -Force
    }
  }
}

Write-Host "Agent-kit: $Kit"
foreach ($h in $Harness) {
  $t = $targets[$h]
  Write-Host "`n== $h =="
  $body = if ($Uninstall) { '' } else { & $t.Body }
  Set-ManagedBlock $t.Rules $body
  if ($t.Copy) { Set-SkillCopies $t.Skills } else { Set-SkillLinks $t.Skills }
  if ($h -eq 'codex' -and -not $Uninstall -and -not $DryRun -and (Test-Path -LiteralPath $t.Rules)) {
    $size = (Get-Item -LiteralPath $t.Rules).Length
    if ($size -gt 24KB) {
      Write-Warning "$($t.Rules) is $([math]::Round($size / 1KB, 1)) KiB. Codex reads 32 KiB in total, project AGENTS.md included. Trim it."
    }
  }
}
Set-BotTemplates

Write-Host ''
if ($script:Changes -eq 0) { Write-Host 'Done. Nothing to change.' }
elseif ($DryRun) { Write-Host "Dry run: $($script:Changes) change(s) would be made." }
else {
  Write-Host "Done: $($script:Changes) change(s)."
  if (Test-Path $BackupDir) { Write-Host "Backups: $BackupDir" }
}
