<p align="center">
  <img src="https://em-content.zobj.net/source/apple/391/rock_1faa8.png" width="100" />
</p>

<h1 align="center">caveman-plan</h1>

<p align="center"><strong>why write many word when plan, build, fix need few</strong></p>

<p align="center">
  Claude Code skill — a caveman-compressed <strong>plan → confirm → execute → revise</strong> workflow.
  Cuts ~70% of plan/status/chat tokens. Code stays normal.
</p>

---

## What it does

`caveman-plan` runs a full build loop in caveman terseness — but never silently. Four phases:

1. **PLAN** — caveman plan: numbered steps, risks, files touched.
2. **CONFIRM** — stops and waits. Nothing runs until you reply `go`.
3. **EXECUTE** — does the work after approval. Status updates stay terse; actual code is written normal.
4. **REVISE** — loop for changes on a fresh build *or* an existing finished project: add feature, fix, refactor → mini re-plan → confirm → execute.

Caveman style persists across every phase. Code, commits, and security warnings always stay normal prose.

**Before (normal, ~70 tokens):**
> "Sure! To add JWT authentication, I would recommend first installing the jsonwebtoken and bcrypt packages, then creating an authentication middleware that verifies the bearer token..."

**After (caveman-plan, ~22 tokens):**
> ```
> PLAN: JWT auth
> 1. Add `jsonwebtoken` + `bcrypt`.
> 2. `middleware/auth.js` — verify Bearer, attach `req.user`.
> 3. `POST /login` — sign token, 15min expiry.
> Risk: secret leak → use env.
> ```

Same plan. Less word. Brain still big.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (or any agent that loads `~/.claude/skills/`)
- Node.js ≥ 18 (only if you use the install script)

## Recommended companion — caveman

`caveman-plan` is **self-contained** and works on its own. But it pairs best with the [**caveman**](https://github.com/JuliusBrussee/caveman) plugin, which adds:

- `[CAVEMAN] ⛏` statusline badge — lifetime tokens saved
- `/caveman-stats` — real session token usage from the Claude Code log
- Full caveman mode for *all* replies (not just planning)

The install script checks for caveman and offers to install it. Skip it if you only want planning compression.

## Install

**macOS / Linux / WSL / Git Bash:**

```bash
curl -fsSL https://raw.githubusercontent.com/Ahmadnidzam/caveman-plan/main/install.sh | bash
```

**Windows (PowerShell 5.1+):**

```powershell
irm https://raw.githubusercontent.com/Ahmadnidzam/caveman-plan/main/install.ps1 -OutFile "$env:TEMP\cp.ps1"; & powershell -ExecutionPolicy Bypass -File "$env:TEMP\cp.ps1"
```

**Manual:**

```bash
mkdir -p ~/.claude/skills/caveman-plan
cp SKILL.md ~/.claude/skills/caveman-plan/SKILL.md
```

Restart Claude Code (or start a new session) so the skill registers.

## Usage

| Action | How |
|---|---|
| Start a build | say "buatkan rencana X" / "plan and build X" → get plan, reply `go` to execute |
| Approve plan | `go` / "lanjut" / "kerjakan" / "ok" |
| Change plan | say the change → agent re-plans, asks again |
| Revise existing project | "tambah fitur X" / "revisi" / "fix Y" → mini re-plan → `go` |
| Force on | `/caveman-plan` |
| Intensity | `/caveman-plan lite` · `full` (default) · `ultra` |
| Off | "stop caveman" / "normal mode" |

## How it works

1. Skill file drops into `~/.claude/skills/caveman-plan/`.
2. Description triggers the skill on planning intent.
3. Skill tells the agent: while planning, drop articles/filler, use numbered fragment steps, keep all technical terms + code + paths exact.
4. Auto-clarity: security warnings, irreversible-action confirmations, and ambiguous multi-step order stay in normal prose.

## License

MIT — see [LICENSE](./LICENSE).

---

<p align="center"><em>caveman-plan shrink what agent <strong>plan</strong>. <a href="https://github.com/JuliusBrussee/caveman">caveman</a> shrink what agent <strong>say</strong>.</em></p>
