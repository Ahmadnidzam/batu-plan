# caveman-plan installer (soft caveman prerequisite) — Windows PowerShell 5.1+
$ErrorActionPreference = "Stop"

$RepoRaw  = "https://raw.githubusercontent.com/Ahmadnidzam/caveman-plan/main"
$SkillDir = Join-Path $env:USERPROFILE ".claude\skills\caveman-plan"

Write-Host "caveman-plan installer" -ForegroundColor Yellow
Write-Host "  planning compression skill for Claude Code"
Write-Host ""

# 1. Check caveman (soft — warn only)
$cavemanSkill  = Join-Path $env:USERPROFILE ".claude\skills\caveman"
$cavemanCache  = Join-Path $env:USERPROFILE ".claude\plugins\cache"
$cavemanFound  = (Test-Path $cavemanSkill) -or `
                 ((Test-Path $cavemanCache) -and (Get-ChildItem $cavemanCache -Filter "caveman*" -ErrorAction SilentlyContinue))

if ($cavemanFound) {
  Write-Host "OK  caveman detected - statusline + /caveman-stats available" -ForegroundColor Green
} else {
  Write-Host "i   caveman not found (optional companion)."
  Write-Host "    caveman-plan works without it. For statusline + stats, install caveman:"
  Write-Host "      irm https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.ps1 | iex"
  Write-Host ""
}

# 2. Install skill
New-Item -ItemType Directory -Force -Path $SkillDir | Out-Null
$dest = Join-Path $SkillDir "SKILL.md"

if (Test-Path ".\SKILL.md") {
  Copy-Item ".\SKILL.md" $dest -Force
  Write-Host "OK  installed from local SKILL.md" -ForegroundColor Green
} else {
  Invoke-RestMethod "$RepoRaw/SKILL.md" -OutFile $dest
  Write-Host "OK  installed from $RepoRaw/SKILL.md" -ForegroundColor Green
}

Write-Host ""
Write-Host "OK  caveman-plan installed -> $dest" -ForegroundColor Green
Write-Host "    Restart Claude Code, then: /caveman-plan  (or say 'buatkan rencana ...')"
