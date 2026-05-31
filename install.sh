#!/usr/bin/env bash
# caveman-plan installer (soft caveman prerequisite)
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/Ahmadnidzam/caveman-plan/main"
SKILL_DIR="$HOME/.claude/skills/caveman-plan"

echo "🪨 caveman-plan installer"
echo "  planning compression skill for Claude Code"
echo

# 1. Check caveman (soft — warn only, do not block)
CAVEMAN_FOUND=0
if [ -d "$HOME/.claude/skills/caveman" ] || ls -d "$HOME"/.claude/plugins/cache/caveman* >/dev/null 2>&1; then
  CAVEMAN_FOUND=1
fi

if [ "$CAVEMAN_FOUND" -eq 1 ]; then
  echo "✓ caveman detected — statusline + /caveman-stats available"
else
  echo "ℹ caveman not found (optional companion)."
  echo "  caveman-plan works without it. For statusline + stats, install caveman:"
  echo "    curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash"
  echo
fi

# 2. Install skill
mkdir -p "$SKILL_DIR"

if [ -f "./SKILL.md" ]; then
  cp ./SKILL.md "$SKILL_DIR/SKILL.md"
  echo "✓ installed from local SKILL.md"
else
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REPO_RAW/SKILL.md" -o "$SKILL_DIR/SKILL.md"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$SKILL_DIR/SKILL.md" "$REPO_RAW/SKILL.md"
  else
    echo "✗ need curl or wget" >&2
    exit 1
  fi
  echo "✓ installed from $REPO_RAW/SKILL.md"
fi

echo
echo "✓ caveman-plan installed → $SKILL_DIR/SKILL.md"
echo "  Restart Claude Code, then: /caveman-plan  (or say 'buatkan rencana ...')"
