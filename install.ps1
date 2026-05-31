# caveman-plan multi-agent installer (soft caveman prerequisite) — Windows PowerShell 5.1+
#
# Flags:
#   -Project   also write into the CURRENT directory's project agent files. Off by default.
#   -Local     use .\SKILL.md and .\rules.md from CWD instead of downloading.
param(
  [switch]$Project,
  [switch]$Local
)
$ErrorActionPreference = "Stop"

$Ref     = if ($env:CAVEMAN_PLAN_REF) { $env:CAVEMAN_PLAN_REF } else { "main" }
$RepoRaw = "https://raw.githubusercontent.com/Ahmadnidzam/caveman-plan/$Ref"
$Home_   = $env:USERPROFILE

# Expected SHA-256 of fetched files. Installer aborts on mismatch.
$ShaSkill = "0bb7881985093b6fb3696132b49f13c0ff40144207dd062382070a1024f77fb9"
$ShaRules = "bddbc444e9bee00234d78632671b07d338198148504b9205030722ccc2b2b6e2"

$Tmp = Join-Path $env:TEMP ("caveman-plan-" + [guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Force -Path $Tmp | Out-Null

Write-Host "caveman-plan installer (multi-agent)" -ForegroundColor Yellow
Write-Host ""

$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
function Write-Text($path, $text) { [IO.File]::WriteAllText($path, $text, $Utf8NoBom) }

function Fetch($name, $expectedSha) {
  $dest = Join-Path $Tmp $name
  if ($Local -and (Test-Path ".\$name")) {
    Copy-Item ".\$name" $dest -Force
    Write-Host "  i using local .\$name (-Local; integrity check skipped)"
    return $dest
  }
  Invoke-RestMethod "$RepoRaw/$name" -OutFile $dest
  $got = (Get-FileHash $dest -Algorithm SHA256).Hash.ToLower()
  if ($got -ne $expectedSha) {
    Write-Host "x integrity check FAILED for $name" -ForegroundColor Red
    Write-Host "  expected $expectedSha"
    Write-Host "  got      $got"
    Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
  }
  return $dest
}
$SkillSrc = Fetch "SKILL.md" $ShaSkill
$RuleSrc  = Fetch "rules.md" $ShaRules

$script:Installed = 0
$MarkStart = "<!-- caveman-plan:start -->"
$MarkEnd   = "<!-- caveman-plan:end -->"

function Install-Skill($label, $detect, $skillsDir) {
  if (Test-Path $detect) {
    $d = Join-Path $skillsDir "caveman-plan"
    New-Item -ItemType Directory -Force -Path $d | Out-Null
    Copy-Item $SkillSrc (Join-Path $d "SKILL.md") -Force
    Write-Host "  OK  $label  -> $d\SKILL.md" -ForegroundColor Green
    $script:Installed++
  }
}

function Install-Rule($label, $detect, $destFile) {
  if (Test-Path $detect) {
    New-Item -ItemType Directory -Force -Path (Split-Path $destFile) | Out-Null
    Copy-Item $RuleSrc $destFile -Force
    Write-Host "  OK  $label  -> $destFile" -ForegroundColor Green
    $script:Installed++
  }
}

function Install-Append($label, $detect, $destFile) {
  if (Test-Path $detect) {
    New-Item -ItemType Directory -Force -Path (Split-Path $destFile) | Out-Null
    $body = ""
    if (Test-Path $destFile) { $body = [IO.File]::ReadAllText($destFile) }
    if ($body -and $body.Contains($MarkStart)) {
      $pattern = [regex]::Escape($MarkStart) + "[\s\S]*?" + [regex]::Escape($MarkEnd)
      $body = [regex]::Replace($body, $pattern, "").TrimEnd()
    }
    $rule = [IO.File]::ReadAllText($RuleSrc)
    $out  = ($body.TrimEnd() + "`n`n" + $MarkStart + "`n" + $rule + "`n" + $MarkEnd + "`n")
    Write-Text $destFile $out
    Write-Host "  OK  $label  -> $destFile" -ForegroundColor Green
    $script:Installed++
  }
}

# --- 0. caveman soft check ---
$cavemanFound = (Test-Path (Join-Path $Home_ ".claude\skills\caveman")) -or `
  ((Test-Path (Join-Path $Home_ ".claude\plugins\cache")) -and `
   (Get-ChildItem (Join-Path $Home_ ".claude\plugins\cache") -Filter "caveman*" -ErrorAction SilentlyContinue))
if ($cavemanFound) {
  Write-Host "  i  caveman detected - statusline + /caveman-stats available"
} else {
  Write-Host "  i  caveman not found (optional). For statusline + stats:"
  Write-Host "     irm https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.ps1 | iex"
}
Write-Host ""
Write-Host "Scanning agents..."

# --- Agent-Skills format (global) ---
Install-Skill "Claude Code" (Join-Path $Home_ ".claude")          (Join-Path $Home_ ".claude\skills")
Install-Skill "Gemini CLI"  (Join-Path $Home_ ".gemini")          (Join-Path $Home_ ".gemini\skills")
Install-Skill "OpenCode"    (Join-Path $Home_ ".config\opencode") (Join-Path $Home_ ".config\opencode\skills")
Install-Skill "Goose"       (Join-Path $Home_ ".config\goose")    (Join-Path $Home_ ".config\goose\skills")
Install-Skill "Crush"       (Join-Path $Home_ ".config\crush")    (Join-Path $Home_ ".config\crush\skills")
Install-Skill "Kiro"        (Join-Path $Home_ ".kiro")            (Join-Path $Home_ ".kiro\skills")
Install-Skill "Junie"       (Join-Path $Home_ ".junie")           (Join-Path $Home_ ".junie\skills")
Install-Skill "Qwen"        (Join-Path $Home_ ".qwen")            (Join-Path $Home_ ".qwen\skills")
Install-Skill "Forge"       (Join-Path $Home_ ".forge")           (Join-Path $Home_ ".forge\skills")
Install-Skill "OpenClaw"    (Join-Path $Home_ ".openclaw")        (Join-Path $Home_ ".openclaw\workspace\skills")
Install-Skill "Droid"       (Join-Path $Home_ ".droid")           (Join-Path $Home_ ".droid\skills")

# --- Dedicated rule file (global) ---
Install-Rule "Windsurf"        (Join-Path $Home_ ".codeium\windsurf") (Join-Path $Home_ ".codeium\windsurf\memories\caveman-plan.md")
Install-Rule "Cursor (global)" (Join-Path $Home_ ".cursor")           (Join-Path $Home_ ".cursor\rules\caveman-plan.mdc")

# --- Shared instructions file (global, append) ---
Install-Append "Codex (global)" (Join-Path $Home_ ".codex") (Join-Path $Home_ ".codex\AGENTS.md")

# --- Project-scoped (opt-in via -Project) ---
if ($Project) {
  Write-Host "Scanning current project ($PWD)... (-Project)"
  Install-Rule   "Cursor (project)"   ".\.cursor"    ".\.cursor\rules\caveman-plan.mdc"
  Install-Rule   "Cline"              ".\.clinerules" ".\.clinerules\caveman-plan.md"
  Install-Rule   "Roo Code"           ".\.roo"       ".\.roo\rules\caveman-plan.md"
  Install-Rule   "Kilo Code"          ".\.kilocode"  ".\.kilocode\rules\caveman-plan.md"
  Install-Rule   "Windsurf (project)" ".\.windsurf"  ".\.windsurf\rules\caveman-plan.md"
  Install-Append "Copilot (project)"  ".\.github"    ".\.github\copilot-instructions.md"
  Install-Append "Codex (project)"    ".\AGENTS.md"  ".\AGENTS.md"
} else {
  Write-Host "  i  project files skipped (pass -Project to write into the current repo)"
}

Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue
Write-Host ""
if ($script:Installed -eq 0) {
  Write-Host "!  No agents detected. Manual: copy SKILL.md -> <agent>\skills\caveman-plan\SKILL.md" -ForegroundColor Yellow
} else {
  Write-Host "OK  caveman-plan installed for $($script:Installed) target(s). Restart the agent to pick it up." -ForegroundColor Green
}
