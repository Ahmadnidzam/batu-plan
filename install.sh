#!/usr/bin/env bash
# batu-plan multi-agent installer (soft caveman prerequisite)
# Detects installed AI coding agents and drops the skill/rule in each one's format.
#
# Flags:
#   --project   also write into the CURRENT directory's project agent files
#               (Cursor/Cline/Roo/Kilo/Windsurf/Copilot/Codex). Off by default.
#   --local     use ./SKILL.md and ./rules.md from CWD instead of downloading
#               (skips integrity check). SECURITY: --local installs UNVERIFIED
#               content, so it is restricted to project scope and REQUIRES
#               --project. It never writes global agent config.
set -euo pipefail

REF="${BATU_PLAN_REF:-main}"   # pin to a commit SHA for reproducible installs
REPO_RAW="https://raw.githubusercontent.com/Ahmadnidzam/batu-plan/$REF"

# Expected SHA-256 of the fetched files. Installer aborts on mismatch. This
# defends a CDN/network tamper of these two files while install.sh itself is
# intact. It does NOT defend against full repo compromise (an attacker who can
# edit the payload can edit these constants too). For that, pin BATU_PLAN_REF to
# a reviewed commit and read this script first. Bump when content changes.
SHA_SKILL="696045facad3460093f8d6b7610beef8eb0350459e1c679240bc0d987c85f5f8"
SHA_RULES="5d1bd4d182e4d54c4950f003de7634e3037e14dd35795fc1f7625115d9f0d203"

USE_LOCAL=0; DO_PROJECT=0
for arg in "$@"; do
  case "$arg" in
    --local)   USE_LOCAL=1 ;;
    --project) DO_PROJECT=1 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

# --local installs unverified content → never let it touch global config.
if [ "$USE_LOCAL" -eq 1 ] && [ "$DO_PROJECT" -eq 0 ]; then
  echo "✗ --local requires --project. Refusing to install unverified content globally." >&2
  echo "  Run inside the target repo with: install.sh --local --project" >&2
  exit 2
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "🪨 batu-plan installer (multi-agent)"
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
    echo "  ℹ using local ./$1 (--local; integrity check skipped, project scope only)"
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
MARK_START="<!-- batu-plan:start -->"
MARK_END="<!-- batu-plan:end -->"

skill() { # $1=label $2=detect-path $3=skills-dir
  if [ -e "$2" ]; then
    mkdir -p "$3/batu-plan"
    cp "$TMP/SKILL.md" "$3/batu-plan/SKILL.md"
    echo "  ✓ $1  → $3/batu-plan/SKILL.md"; INSTALLED=$((INSTALLED+1))
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
    local existing
    if grep -qF "$MARK_START" "$3" 2>/dev/null; then
      existing="$(awk -v s="$MARK_START" -v e="$MARK_END" '
        $0==s{skip=1} !skip{print} $0==e{skip=0}' "$3")"
    else
      existing="$(cat "$3")"
    fi
    # command substitution strips trailing newlines → no blank-line drift on re-run
    {
      if [ -n "$existing" ]; then printf '%s\n\n' "$existing"; fi
      printf '%s\n' "$MARK_START"; cat "$TMP/rules.md"; printf '%s\n' "$MARK_END"
    } > "$3"
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

# --- Global agents (skipped entirely under --local) ---
if [ "$USE_LOCAL" -eq 0 ]; then
  echo "Scanning agents…"
  # Agent-Skills format
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
  # Dedicated rule file
  rule   "Windsurf"      "$HOME/.codeium/windsurf"     "$HOME/.codeium/windsurf/memories/batu-plan.md"
  rule   "Cursor (global)" "$HOME/.cursor"             "$HOME/.cursor/rules/batu-plan.mdc"
  # Shared instructions file (append)
  append "Codex (global)" "$HOME/.codex"               "$HOME/.codex/AGENTS.md"
fi

# --- Project-scoped agents (opt-in via --project) ---
# Note: a bare .github/.cursor/.codex dir is treated as opt-in here. Pass
# --project deliberately, and review what gets written before committing.
if [ "$DO_PROJECT" -eq 1 ]; then
  echo "Scanning current project ($(pwd))… (--project)"
  rule   "Cursor (project)"  "./.cursor"               "./.cursor/rules/batu-plan.mdc"
  rule   "Cline"             "./.clinerules"           "./.clinerules/batu-plan.md"
  rule   "Roo Code"          "./.roo"                  "./.roo/rules/batu-plan.md"
  rule   "Kilo Code"         "./.kilocode"             "./.kilocode/rules/batu-plan.md"
  rule   "Windsurf (project)" "./.windsurf"            "./.windsurf/rules/batu-plan.md"
  append "Copilot (project)" "./.github"               "./.github/copilot-instructions.md"
  append "Codex (project)"   "./AGENTS.md"             "./AGENTS.md"
elif [ "$USE_LOCAL" -eq 0 ]; then
  echo "  ℹ project files skipped (pass --project to write into the current repo)"
fi

echo
if [ "$INSTALLED" -eq 0 ]; then
  echo "⚠ No agents detected. Manual: copy SKILL.md → <agent>/skills/batu-plan/SKILL.md"
else
  echo "✓ batu-plan installed for $INSTALLED target(s). Restart the agent to pick it up."
fi
