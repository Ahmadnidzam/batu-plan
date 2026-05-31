#!/usr/bin/env bash
# caveman-plan multi-agent installer (soft caveman prerequisite)
# Detects installed AI coding agents and drops the skill/rule in each one's format.
#
# Flags:
#   --project   also write into the CURRENT directory's project agent files
#               (Cursor/Cline/Roo/Kilo/Windsurf/Copilot/Codex). Off by default.
#   --local     use ./SKILL.md and ./rules.md from CWD instead of downloading.
#               Only honor this when you trust the current directory.
set -euo pipefail

REF="${CAVEMAN_PLAN_REF:-main}"   # pin to a commit SHA for reproducible installs
REPO_RAW="https://raw.githubusercontent.com/Ahmadnidzam/caveman-plan/$REF"

# Expected SHA-256 of the fetched files. Installer aborts on mismatch, so a
# tampered CDN/repo cannot inject agent instructions. Bump when content changes.
SHA_SKILL="0bb7881985093b6fb3696132b49f13c0ff40144207dd062382070a1024f77fb9"
SHA_RULES="bddbc444e9bee00234d78632671b07d338198148504b9205030722ccc2b2b6e2"

USE_LOCAL=0; DO_PROJECT=0
for arg in "$@"; do
  case "$arg" in
    --local)   USE_LOCAL=1 ;;
    --project) DO_PROJECT=1 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "🪨 caveman-plan installer (multi-agent)"
echo

sha256_of() { # $1=file -> hash on stdout
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1;
  elif command -v shasum   >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1;
  else echo "✗ need sha256sum or shasum to verify integrity" >&2; exit 1; fi
}

get() { # $1=filename $2=expected-sha
  local f="$TMP/$1"
  if [ "$USE_LOCAL" -eq 1 ] && [ -f "./$1" ]; then
    cp "./$1" "$f"
    echo "  ℹ using local ./$1 (--local; integrity check skipped)"
    return
  fi
  if command -v curl >/dev/null 2>&1; then curl -fsSL "$REPO_RAW/$1" -o "$f";
  elif command -v wget >/dev/null 2>&1; then wget -qO "$f" "$REPO_RAW/$1";
  else echo "✗ need curl or wget" >&2; exit 1; fi
  local got; got="$(sha256_of "$f")"
  if [ "$got" != "$2" ]; then
    echo "✗ integrity check FAILED for $1" >&2
    echo "  expected $2" >&2
    echo "  got      $got" >&2
    exit 1
  fi
}
get SKILL.md "$SHA_SKILL"
get rules.md "$SHA_RULES"

INSTALLED=0
MARK_START="<!-- caveman-plan:start -->"
MARK_END="<!-- caveman-plan:end -->"

skill() { # $1=label $2=detect-path $3=skills-dir
  if [ -e "$2" ]; then
    mkdir -p "$3/caveman-plan"
    cp "$TMP/SKILL.md" "$3/caveman-plan/SKILL.md"
    echo "  ✓ $1  → $3/caveman-plan/SKILL.md"; INSTALLED=$((INSTALLED+1))
  fi
}

rule() { # $1=label $2=detect-path $3=dest-file
  if [ -e "$2" ]; then
    mkdir -p "$(dirname "$3")"
    cp "$TMP/rules.md" "$3"
    echo "  ✓ $1  → $3"; INSTALLED=$((INSTALLED+1))
  fi
}

append() { # $1=label $2=detect-path $3=dest-file
  if [ -e "$2" ]; then
    mkdir -p "$(dirname "$3")"; touch "$3"
    if grep -qF "$MARK_START" "$3" 2>/dev/null; then
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

# --- Project-scoped agents (opt-in via --project) ---
if [ "$DO_PROJECT" -eq 1 ]; then
  echo "Scanning current project ($(pwd))… (--project)"
  rule   "Cursor (project)"  "./.cursor"               "./.cursor/rules/caveman-plan.mdc"
  rule   "Cline"             "./.clinerules"           "./.clinerules/caveman-plan.md"
  rule   "Roo Code"          "./.roo"                  "./.roo/rules/caveman-plan.md"
  rule   "Kilo Code"         "./.kilocode"             "./.kilocode/rules/caveman-plan.md"
  rule   "Windsurf (project)" "./.windsurf"            "./.windsurf/rules/caveman-plan.md"
  append "Copilot (project)" "./.github"               "./.github/copilot-instructions.md"
  append "Codex (project)"   "./AGENTS.md"             "./AGENTS.md"
else
  echo "  ℹ project files skipped (pass --project to write into the current repo)"
fi

echo
if [ "$INSTALLED" -eq 0 ]; then
  echo "⚠ No agents detected. Manual: copy SKILL.md → <agent>/skills/caveman-plan/SKILL.md"
else
  echo "✓ caveman-plan installed for $INSTALLED target(s). Restart the agent to pick it up."
fi
