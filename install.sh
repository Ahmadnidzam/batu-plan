#!/usr/bin/env bash
# caveman-plan multi-agent installer (soft caveman prerequisite)
# Detects installed AI coding agents and drops the skill/rule in each one's format.
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/Ahmadnidzam/caveman-plan/main"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "🪨 caveman-plan installer (multi-agent)"
echo

# --- fetch content (prefer local files, else download) ---
get() { # $1=filename -> path in $TMP
  if [ -f "./$1" ]; then cp "./$1" "$TMP/$1";
  elif command -v curl >/dev/null 2>&1; then curl -fsSL "$REPO_RAW/$1" -o "$TMP/$1";
  elif command -v wget >/dev/null 2>&1; then wget -qO "$TMP/$1" "$REPO_RAW/$1";
  else echo "✗ need curl or wget" >&2; exit 1; fi
}
get SKILL.md
get rules.md

INSTALLED=0; SKIPPED=0
MARK_START="<!-- caveman-plan:start -->"
MARK_END="<!-- caveman-plan:end -->"

# Copy SKILL.md into an Agent-Skills directory (idempotent overwrite)
skill() { # $1=label $2=detect-path $3=skills-dir
  if [ -e "$2" ]; then
    mkdir -p "$3/caveman-plan"
    cp "$TMP/SKILL.md" "$3/caveman-plan/SKILL.md"
    echo "  ✓ $1  → $3/caveman-plan/SKILL.md"; INSTALLED=$((INSTALLED+1))
  fi
}

# Write a standalone rule file (idempotent overwrite)
rule() { # $1=label $2=detect-path $3=dest-file
  if [ -e "$2" ]; then
    mkdir -p "$(dirname "$3")"
    cp "$TMP/rules.md" "$3"
    echo "  ✓ $1  → $3"; INSTALLED=$((INSTALLED+1))
  fi
}

# Append a marker-fenced block to a shared instructions file (idempotent)
append() { # $1=label $2=detect-path $3=dest-file
  if [ -e "$2" ]; then
    mkdir -p "$(dirname "$3")"; touch "$3"
    if grep -qF "$MARK_START" "$3" 2>/dev/null; then
      # replace existing block
      awk -v s="$MARK_START" -v e="$MARK_END" '
        $0==s{skip=1} !skip{print} $0==e{skip=0}' "$3" > "$3.tmp" && mv "$3.tmp" "$3"
    fi
    { echo ""; echo "$MARK_START"; cat "$TMP/rules.md"; echo "$MARK_END"; } >> "$3"
    echo "  ✓ $1  → $3"; INSTALLED=$((INSTALLED+1))
  fi
}

# --- 0. caveman soft check ---
if [ -d "$HOME/.claude/skills/caveman" ] || ls -d "$HOME"/.claude/plugins/cache/caveman* >/dev/null 2>&1; then
  echo "  ℹ caveman detected — statusline + /caveman-stats available"
else
  echo "  ℹ caveman not found (optional). Install for statusline + stats:"
  echo "    curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash"
fi
echo
echo "Scanning agents…"

# --- Agent-Skills format (global) ---
skill  "Claude Code"   "$HOME/.claude"               "$HOME/.claude/skills"
skill  "Gemini CLI"    "$HOME/.gemini"               "$HOME/.gemini/skills"
skill  "OpenCode"      "$HOME/.config/opencode"      "$HOME/.config/opencode/skills"
skill  "Goose"         "$HOME/.config/goose"         "$HOME/.config/goose/skills"
skill  "Crush"         "$HOME/.config/crush"         "$HOME/.config/crush/skills"
skill  "Kiro"          "$HOME/.kiro"                 "$HOME/.kiro/skills"
skill  "Junie"         "$HOME/.junie"                "$HOME/.junie/skills"
skill  "Qwen"          "$HOME/.qwen"                 "$HOME/.qwen/skills"
skill  "Forge"         "$HOME/.forge"                "$HOME/.forge/skills"
skill  "OpenClaw"      "$HOME/.openclaw"             "$HOME/.openclaw/workspace/skills"
skill  "Droid"         "$HOME/.droid"                "$HOME/.droid/skills"

# --- Dedicated rule file (global) ---
rule   "Windsurf"      "$HOME/.codeium/windsurf"     "$HOME/.codeium/windsurf/memories/caveman-plan.md"
rule   "Cursor (global)" "$HOME/.cursor"             "$HOME/.cursor/rules/caveman-plan.mdc"

# --- Shared instructions file (global, append) ---
append "Codex (global)" "$HOME/.codex"               "$HOME/.codex/AGENTS.md"

# --- Project-scoped agents (only if marker present in CWD) ---
echo "Scanning current project ($(pwd))…"
rule   "Cursor (project)"  "./.cursor"               "./.cursor/rules/caveman-plan.mdc"
rule   "Cline"             "./.clinerules"           "./.clinerules/caveman-plan.md"
rule   "Roo Code"          "./.roo"                  "./.roo/rules/caveman-plan.md"
rule   "Kilo Code"         "./.kilocode"             "./.kilocode/rules/caveman-plan.md"
rule   "Windsurf (project)" "./.windsurf"            "./.windsurf/rules/caveman-plan.md"
append "Copilot (project)" "./.github"               "./.github/copilot-instructions.md"
append "Codex (project)"   "./AGENTS.md"             "./AGENTS.md"

echo
if [ "$INSTALLED" -eq 0 ]; then
  echo "⚠ No agents detected. Manual: copy SKILL.md → <agent>/skills/caveman-plan/SKILL.md"
else
  echo "✓ caveman-plan installed for $INSTALLED target(s). Restart the agent to pick it up."
fi
