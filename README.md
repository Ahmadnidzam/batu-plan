<p align="center">
  <img src="assets/headline.png" alt="batu-plan — plan → confirm → execute → revise" width="100%" />
</p>

<p align="center"><strong>why write many word when plan, build, fix need few</strong></p>

<p align="center">
  AI coding-agent skill — a terse "batu" (rock / caveman-style)
  <strong>plan → confirm → execute → revise</strong> workflow.
</p>

---

## What it does

`batu-plan` runs a full build loop in terse "batu" prose — but never silently. Four phases:

1. **PLAN** — terse plan: numbered steps, risks, files touched.
2. **CONFIRM** — stops and waits. Nothing runs until you reply `go`.
3. **EXECUTE** — does the work after approval. Status updates stay terse; actual code is written normal.
4. **REVISE** — loop for changes on a fresh build *or* an existing finished project: add feature, fix, refactor → mini re-plan → confirm → execute.

Terse style persists across every phase. Code, commits, and security warnings always stay normal prose.

**Before (normal, ~70 tokens):**
> "Sure! To add JWT authentication, I would recommend first installing the jsonwebtoken and bcrypt packages, then creating an authentication middleware that verifies the bearer token..."

**After (batu-plan, ~22 tokens):**
> ```
> PLAN: JWT auth
> 1. Add `jsonwebtoken` + `bcrypt`.
> 2. `middleware/auth.js` — verify Bearer, attach `req.user`.
> 3. `POST /login` — sign token, 15min expiry.
> Risk: secret leak → use env.
> Approve? `go` or change.
> ```

> **Scope of the saving.** batu-plan compresses **planning/status prose only** — a *minority* of a real build session's tokens. File reads, diffs, and tool I/O usually dominate, and the skill text itself adds a little input cost each session. Expect ~70% off the plan-prose slice, not off your whole bill. The win is mostly **readability + speed**; cost is a bonus.

## Activation

batu-plan turns on for **any build / change / extend request** so its terse style and the plan-gate apply by default:

- ordinary dev verbs — "revisi", "tambah fitur", "ubah", "fix", "add feature", "ganti", "implement", "refactor"
- explicit — `/batu-plan`, plan mode, "plan and build", "buatkan rencana dan kerjakan X"

Read-only questions ("what does X do", "explain Y") do **not** activate — answered normally. Turn off with "stop batu" / "normal mode".

On activation it runs a **CLARIFY** step first: 1-3 targeted questions about the project (which file/module, expected behavior, constraints, scope) before producing a plan — skipped when the answer is already clear from context. Then PLAN → CONFIRM (`go`) → EXECUTE → REVISE loop. Nothing runs until you approve.

> **Trade-off (be aware).** Activating on common dev verbs is broad by design — it makes the skill apply almost every coding turn, which is the point (consistent terseness + a gate). The cost is an upfront CLARIFY question on most requests. Say "normal mode" any time to opt out.

## Requirements

- One of the [supported agents](#supported-agents) below
- `curl`/`wget` (bash) or PowerShell 5.1+ (Windows) for the install script

## Supported agents

The installer auto-detects which agents you have and drops the skill in each one's native format — Agent-Skills file, rule file, or a marker-fenced block in a shared instructions file. Absent agents are skipped.

| Agent | Format | Scope |
|---|---|---|
| Claude Code · Gemini CLI · OpenCode · Goose · Crush · Kiro · Junie · Qwen · Forge · OpenClaw · Droid | `SKILL.md` | global |
| Windsurf · Cursor | rule file | global |
| Codex | `AGENTS.md` block | global |
| Cursor · Cline · Roo Code · Kilo Code · Windsurf · Copilot · Codex | rule / instructions | project (`--project`) |

Adding a new agent to the installer is one line.

## Install

**macOS / Linux / WSL / Git Bash:**

```bash
curl -fsSL https://raw.githubusercontent.com/Ahmadnidzam/batu-plan/main/install.sh | bash
```

**Windows (PowerShell 5.1+):**

```powershell
irm https://raw.githubusercontent.com/Ahmadnidzam/batu-plan/main/install.ps1 -OutFile "$env:TEMP\bp.ps1"; & powershell -ExecutionPolicy Bypass -File "$env:TEMP\bp.ps1"
```

**Manual:**

```bash
mkdir -p ~/.claude/skills/batu-plan
cp SKILL.md ~/.claude/skills/batu-plan/SKILL.md
```

Restart the agent (or start a new session) so the skill registers.

### Flags

| Flag (bash / PowerShell) | Effect |
|---|---|
| `--project` / `-Project` | Also write into the **current directory's** project agent files (Cursor/Cline/Roo/Kilo/Windsurf/Copilot/Codex). Off by default — global agents only. A bare `.github`/`.cursor`/etc. dir counts as opt-in, so pass this deliberately and review what gets written before committing. |
| `--local` / `-Local` | Use `./SKILL.md` + `./rules.md` from CWD instead of downloading (skips the integrity check). Because the content is unverified, `--local` **requires `--project`** and never writes global config. |

```bash
# global agents only (default)
curl -fsSL .../install.sh | bash
# project files in this repo too
curl -fsSL .../install.sh | bash -s -- --project
```

### Integrity — what the check does and does not cover

The installer embeds the SHA-256 of `SKILL.md` + `rules.md` and verifies each download before writing. **This defends against a CDN/network tamper of those two files while `install.sh` itself is intact.** It does **not** defend against a full repository compromise — an attacker who can edit the payload can edit the embedded hashes in the same commit. The `curl | bash` entrypoint also fetches `install.sh` from `main` unpinned.

For a trustworthy install: **read the script first**, then pin to a reviewed commit:

```bash
BATU_PLAN_REF=<commit-sha> \
  curl -fsSL https://raw.githubusercontent.com/Ahmadnidzam/batu-plan/<commit-sha>/install.sh | bash
```

(Use the *same* `<commit-sha>` in both the URL and `BATU_PLAN_REF` so the embedded hashes and the payload match.)

## Usage

| Action | How |
|---|---|
| Start a build | "buatkan rencana dan kerjakan X" / "plan and build X" → get plan, reply `go` |
| Approve plan | `go` / "lanjut" / "kerjakan" / "ok" |
| Change plan | say the change → agent re-plans, asks again |
| Revise (after active) | "tambah fitur X" / "revisi" / "fix Y" → mini re-plan → `go` |
| Force on | `/batu-plan` |
| Intensity | `/batu-plan lite` · `full` (default) · `ultra` |
| Off | "stop batu" / "normal mode" |

## Recommended companion — caveman

batu-plan is **self-contained**. It pairs well with the [**caveman**](https://github.com/JuliusBrussee/caveman) plugin, which adds a `[CAVEMAN] ⛏` statusline badge and `/caveman-stats` (real session token usage). Optional — skip it if you only want the planning workflow.

## License

MIT — see [LICENSE](./LICENSE).

---

<p align="center"><em>batu-plan shrink what agent <strong>plan</strong>. <a href="https://github.com/JuliusBrussee/caveman">caveman</a> shrink what agent <strong>say</strong>.</em></p>
