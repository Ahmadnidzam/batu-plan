# caveman-plan multi-agent installer (soft caveman prerequisite) — Windows PowerShell 5.1+
$ErrorActionPreference = "Stop"

$RepoRaw = "https://raw.githubusercontent.com/Ahmadnidzam/caveman-plan/main"
$Home_   = $env:USERPROFILE
$Tmp     = Join-Path $env:TEMP ("caveman-plan-" + [guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Force -Path $Tmp | Out-Null

Write-Host "caveman-plan installer (multi-agent)" -ForegroundColor Yellow
Write-Host ""

# --- fetch content (prefer local, else download) ---
function Get-Content-File($name) {
  $dest = Join-Path $Tmp $name
  if (Test-Path ".\$name") { Copy-Item ".\$name" $dest -Force }
  else { Invoke-RestMethod "$RepoRaw/$name" -OutFile $dest }
  return $dest
}
$SkillSrc = Get-Content-File "SKILL.md"
$RuleSrc  = Get-Content-File "rules.md"

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
    if (-not (Test-Path $destFile)) { New-Item -ItemType File -Path $destFile | Out-Null }
    $body = Get-Content $destFile -Raw -ErrorAction SilentlyContinue
    if ($body -and $body.Contains($MarkStart)) {
      $pattern = [regex]::Escape($MarkStart) + "[\s\S]*?" + [regex]::Escape($MarkEnd)
      $body = [regex]::Replace($body, $pattern, "").TrimEnd()
      Set-Content $destFile $body -Encoding utf8
    }
    $rule = Get-Content $RuleSrc -Raw
    Add-Content $destFile "`n$MarkStart`n$rule`n$MarkEnd" -Encoding utf8
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

# --- Project-scoped (only if marker present in CWD) ---
Write-Host "Scanning current project ($PWD)..."
Install-Rule   "Cursor (project)"   ".\.cursor"    ".\.cursor\rules\caveman-plan.mdc"
Install-Rule   "Cline"              ".\.clinerules" ".\.clinerules\caveman-plan.md"
Install-Rule   "Roo Code"           ".\.roo"       ".\.roo\rules\caveman-plan.md"
Install-Rule   "Kilo Code"          ".\.kilocode"  ".\.kilocode\rules\caveman-plan.md"
Install-Rule   "Windsurf (project)" ".\.windsurf"  ".\.windsurf\rules\caveman-plan.md"
Install-Append "Copilot (project)"  ".\.github"    ".\.github\copilot-instructions.md"
Install-Append "Codex (project)"    ".\AGENTS.md"  ".\AGENTS.md"

Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue
Write-Host ""
if ($script:Installed -eq 0) {
  Write-Host "!  No agents detected. Manual: copy SKILL.md -> <agent>\skills\caveman-plan\SKILL.md" -ForegroundColor Yellow
} else {
  Write-Host "OK  caveman-plan installed for $($script:Installed) target(s). Restart the agent to pick it up." -ForegroundColor Green
}
