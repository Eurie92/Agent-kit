# Tests for install.ps1. Each case runs the installer against a fake home (USERPROFILE) in a temp folder,
# using a copy of the kit with test local/ files, so your real home and local/ are never touched.
# Usage (from the kit folder):
#   powershell -ExecutionPolicy Bypass -File install\test-install.ps1
# Exit code: 0 when every check passes, 1 otherwise.
$ErrorActionPreference = 'Stop'
$Repo = Split-Path $PSScriptRoot -Parent
$Root = Join-Path ([IO.Path]::GetTempPath()) ("agent-kit-test-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force $Root | Out-Null
$realHome = $env:USERPROFILE
$script:pass = 0
$script:fail = 0

function Check([string]$Name, [bool]$Ok, $Out = $null) {
  if ($Ok) { $script:pass++; Write-Host "PASS $Name" }
  else {
    $script:fail++; Write-Host "FAIL $Name"
    if ($Out) { $Out | ForEach-Object { Write-Host "       $_" } }
  }
}
function Run-Installer([string]$KitDir, [string]$HomeDir, [string[]]$More = @()) {
  $env:USERPROFILE = $HomeDir
  try {
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $KitDir 'install\install.ps1') @More 2>&1 | ForEach-Object { "$_" }
    return @{ Out = @($out); Code = $LASTEXITCODE; Text = ($out -join "`n") }
  } finally { $env:USERPROFILE = $realHome }
}
function New-Kit([string]$Dir, [switch]$NoLocal) {
  foreach ($d in 'install', 'rules', 'skills') { Copy-Item (Join-Path $Repo $d) (Join-Path $Dir $d) -Recurse }
  if (-not $NoLocal) {
    New-Item -ItemType Directory (Join-Path $Dir 'local') | Out-Null
    [IO.File]::WriteAllText((Join-Path $Dir 'local\MODELS.md'), "# Model routing (test)`n")
    [IO.File]::WriteAllText((Join-Path $Dir 'local\PREFS.md'), "# Personal preferences (test)`n")
  }
  return $Dir
}
function New-Home([string]$Name) {
  $h = Join-Path $Root $Name; New-Item -ItemType Directory $h | Out-Null; return $h
}
# powershell.exe creates AppData under USERPROFILE at start-up; ignore it when checking that a home is untouched.
function Get-HomeItems([string]$HomeDir) {
  return @(Get-ChildItem $HomeDir -Recurse -Force | Where-Object { $_.FullName -notlike "$HomeDir\AppData*" })
}
function Test-Junction([string]$Path) {
  $i = Get-Item $Path -Force -ErrorAction SilentlyContinue
  return ($i -and ($i.Attributes -band [IO.FileAttributes]::ReparsePoint))
}

try {
  Write-Host "PowerShell $($PSVersionTable.PSVersion) on $([Environment]::OSVersion.VersionString)"
  $kit = New-Kit (Join-Path $Root 'kit')
  $skills = @(Get-ChildItem (Join-Path $kit 'skills') -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') } | ForEach-Object { $_.Name })

  # Missing local/ files
  $bare = New-Kit (Join-Path $Root 'kit-bare') -NoLocal
  $h = New-Home 'h-nolocal'
  $r = Run-Installer $bare $h
  Check 'no local/: exit 1' ($r.Code -eq 1) $r.Out
  Check 'no local/: names both files' ($r.Text -match 'Missing: local\\MODELS\.md, local\\PREFS\.md') $r.Out
  Check 'no local/: home untouched' ((Get-HomeItems $h).Count -eq 0)
  $r = Run-Installer $bare $h @('-Uninstall')
  Check 'no local/: uninstall still runs' ($r.Code -eq 0) $r.Out

  # Dry run
  $h = New-Home 'h-dry'
  $r = Run-Installer $kit $h @('-DryRun')
  Check 'dry run: exit 0' ($r.Code -eq 0) $r.Out
  Check 'dry run: home untouched' ((Get-HomeItems $h).Count -eq 0)
  Check 'dry run: says changes would be made' ($r.Text -match 'Dry run: \d+ change') $r.Out

  # Install twice
  $h = New-Home 'h-main'
  $r = Run-Installer $kit $h
  Check 'install: exit 0' ($r.Code -eq 0) $r.Out
  $r = Run-Installer $kit $h
  Check 'install again: Nothing to change' ($r.Text -match 'Nothing to change') $r.Out
  $cm = [IO.File]::ReadAllText((Join-Path $h '.claude\CLAUDE.md'))
  $imports = @([regex]::Matches($cm, '(?m)^@.+$') | ForEach-Object { $_.Value })
  Check 'claude: 3 imports in order' ($imports.Count -eq 3 -and (($imports -join ' ') -match 'rules/GLOBAL\.md.*local/MODELS\.md.*local/PREFS\.md')) $imports
  foreach ($f in '.gemini\GEMINI.md', '.codex\AGENTS.md') {
    $t = [IO.File]::ReadAllText((Join-Path $h $f))
    Check "$f holds all three rule files" ($t.Contains('# Global rules') -and $t.Contains('# Model routing (test)') -and $t.Contains('# Personal preferences (test)'))
  }
  $linked = @($skills | Where-Object { (Test-Junction (Join-Path $h ".claude\skills\$_")) -and (Test-Junction (Join-Path $h ".agents\skills\$_")) })
  Check 'claude + codex skills are junctions' ($linked.Count -eq $skills.Count) $linked
  $copied = @($skills | Where-Object { (Test-Path (Join-Path $h ".gemini\config\skills\$_\.agent-kit-copy")) -and -not (Test-Junction (Join-Path $h ".gemini\config\skills\$_")) })
  Check 'gemini skills are marked copies' ($copied.Count -eq $skills.Count) $copied

  # User text around the block and a CRLF file are kept
  $g = Join-Path $h '.gemini\GEMINI.md'
  [IO.File]::WriteAllText($g, "# My top rule`n`n" + [IO.File]::ReadAllText($g) + "`n# My bottom rule`n")
  $c = Join-Path $h '.codex\AGENTS.md'
  [IO.File]::WriteAllText($c, [IO.File]::ReadAllText($c).Replace("`n", "`r`n"))
  $gBefore = [IO.File]::ReadAllBytes($g); $cBefore = [IO.File]::ReadAllBytes($c)
  $r = Run-Installer $kit $h
  Check 'user text + CRLF: Nothing to change' ($r.Text -match 'Nothing to change') $r.Out
  Check 'user text + CRLF: files byte-identical' ((Compare-Object $gBefore ([IO.File]::ReadAllBytes($g))) -eq $null -and (Compare-Object $cBefore ([IO.File]::ReadAllBytes($c))) -eq $null)

  # New, then removed kit skill
  $tmp = Join-Path $kit 'skills\zz-temp'
  New-Item -ItemType Directory $tmp | Out-Null
  [IO.File]::WriteAllText((Join-Path $tmp 'SKILL.md'), "---`nname: zz-temp`ndescription: test`n---`n")
  $r = Run-Installer $kit $h
  Check 'new skill: 2 links + 1 copy' ((@($r.Out | Where-Object { $_ -match '^link .*zz-temp' }).Count -eq 2) -and (@($r.Out | Where-Object { $_ -match '^copy .*zz-temp' }).Count -eq 1)) $r.Out
  Remove-Item $tmp -Recurse -Force
  $r = Run-Installer $kit $h
  Check 'removed skill: pruned' (-not (Test-Path (Join-Path $h '.claude\skills\zz-temp')) -and -not (Test-Path (Join-Path $h '.gemini\config\skills\zz-temp')) -and -not (Test-Path (Join-Path $h '.agents\skills\zz-temp'))) $r.Out

  # Broken markers are skipped
  $cmPath = Join-Path $h '.claude\CLAUDE.md'
  $before = [IO.File]::ReadAllText($cmPath)
  [IO.File]::WriteAllText($cmPath, $before + "<!-- agent-kit:start stray -->`n")
  $r = Run-Installer $kit $h @('-Harness', 'claude')
  Check 'broken markers: skipped with a warning' ($r.Text -match 'broken or\s+duplicate') $r.Out
  [IO.File]::WriteAllText($cmPath, $before)

  # Old block in a CRLF file is replaced in place
  $h6 = New-Home 'h-old'
  New-Item -ItemType Directory (Join-Path $h6 '.claude') | Out-Null
  $old = "# My top rule`r`n`r`n<!-- agent-kit:start (managed by Agent-kit install.ps1; edits inside are overwritten) -->`r`n@~/Desktop/Agent-kit/rules/GLOBAL.md`r`n@~/Desktop/Agent-kit/rules/MODELS.md`r`n<!-- agent-kit:end -->`r`n`r`n# My bottom rule`r`n"
  [IO.File]::WriteAllText((Join-Path $h6 '.claude\CLAUDE.md'), $old)
  $r = Run-Installer $kit $h6 @('-Harness', 'claude')
  $new = [IO.File]::ReadAllText((Join-Path $h6 '.claude\CLAUDE.md'))
  Check 'old block: replaced in place, outside text kept' ($new.StartsWith("# My top rule`r`n") -and $new.TrimEnd().EndsWith('# My bottom rule') -and ([regex]::Matches($new, 'agent-kit:start')).Count -eq 1 -and $new.Contains('local/PREFS.md')) ($new -split "`r?`n")
  Check 'old block: CRLF kept' (-not ($new -match '[^\r]\n'))

  # Harness list
  $hh = New-Home 'h-harness'
  $r = Run-Installer $kit $hh @('-Harness', 'claude,gemini')
  Check 'harness list: only claude + gemini' ($r.Code -eq 0 -and (Test-Path (Join-Path $hh '.claude\CLAUDE.md')) -and (Test-Path (Join-Path $hh '.gemini\GEMINI.md')) -and -not (Test-Path (Join-Path $hh '.codex')) -and -not (Test-Path (Join-Path $hh '.agents'))) $r.Out
  $r = Run-Installer $kit $hh @('-Harness', 'claude, Gemini')
  Check 'harness list: spaces and case ignored' ($r.Code -eq 0 -and $r.Text -match 'Nothing to change') $r.Out
  $hb = New-Home 'h-bad'
  $r = Run-Installer $kit $hb @('-Harness', 'claude,cursor')
  Check 'harness list: bad value exits 1 and names it' ($r.Code -eq 1 -and $r.Text -match 'Unknown -Harness value: cursor') $r.Out
  Check 'harness list: bad value leaves home untouched' ((Get-HomeItems $hb).Count -eq 0)

  # Uninstall
  $kitFiles = @(Get-ChildItem $kit -Recurse -File).Count
  $r = Run-Installer $kit $h @('-Uninstall')
  Check 'uninstall: exit 0' ($r.Code -eq 0) $r.Out
  $left = @($skills | Where-Object { (Test-Path (Join-Path $h ".claude\skills\$_")) -or (Test-Path (Join-Path $h ".agents\skills\$_")) -or (Test-Path (Join-Path $h ".gemini\config\skills\$_")) })
  Check 'uninstall: no skill links or copies left' ($left.Count -eq 0) $left
  Check 'uninstall: block-only files deleted' (-not (Test-Path (Join-Path $h '.claude\CLAUDE.md')) -and -not (Test-Path (Join-Path $h '.codex\AGENTS.md')))
  $gAfter = [IO.File]::ReadAllText($g)
  Check 'uninstall: user text kept' ($gAfter.Contains('# My top rule') -and $gAfter.Contains('# My bottom rule') -and -not $gAfter.Contains('agent-kit:start'))
  Check 'uninstall: kit untouched' (@(Get-ChildItem $kit -Recurse -File).Count -eq $kitFiles)
  $r = Run-Installer $kit $h @('-Uninstall')
  Check 'uninstall again: Nothing to change' ($r.Text -match 'Nothing to change') $r.Out
} finally {
  $env:USERPROFILE = $realHome
  cmd /c rmdir /s /q "$Root" 2>$null
}
Write-Host ""
Write-Host "PASS: $($script:pass)  FAIL: $($script:fail)"
if ($script:fail -gt 0) { exit 1 } else { exit 0 }
