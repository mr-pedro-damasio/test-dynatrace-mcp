# PLAN — Evolve this scaffold into a Dynatrace MCP exploration project

## 0. Goal

Turn this zero-config devcontainer template into a **purpose-built sandbox for exploring the
Dynatrace MCP server through the Claude Code CLI**.

No application code is required. The deliverables are configuration and documentation:

1. Wire the **Dynatrace MCP server** into the project so `claude` picks it up automatically.
2. Tune **`AGENTS.md`** so the agent knows what Dynatrace is, how to query it, and how to behave.
3. Update project **documentation** (`README.md`, `.env.example`) for this new purpose.
4. Adjust the **devcontainer** so the MCP server has what it needs at runtime.
5. Make **improvement / feature suggestions** (optional, opt-in).

> ⚠️ **Verify-before-trust markers.** Anything tagged **`[VERIFY]`** is drawn from general
> knowledge of the `dynatrace-oss/dynatrace-mcp` project and MUST be confirmed against the
> official source before relying on it. The `context7` plugin was just installed for this —
> run `/reload-plugins`, then ask Claude to look up the Dynatrace MCP docs. Primary sources:
> - Repo: `github.com/dynatrace-oss/dynatrace-mcp`
> - npm package + Dynatrace Developer docs for platform tokens & scopes.

---

## 1. Current state (assessment)

| Area | State | Notes |
|------|-------|-------|
| `CLAUDE.md` | `@AGENTS.md` only | Delegates all guidance to `AGENTS.md`. Good pattern — keep it. |
| `AGENTS.md` | **Empty (0 bytes)** | The single biggest gap. All agent guidance lives here. |
| `.github/copilot-instructions.md` | Points to `AGENTS.md` | Consistent single-source-of-truth. Keep. |
| `.env.example` | Placeholder vars only | Needs Dynatrace variables. |
| `.gitignore` | Ignores `.env*` | Good — secrets won't be committed. |
| `.claude/settings.json` | OpenRouter/DeepSeek env, all keys disabled (`_`-prefixed) | Not Dynatrace-related; see §7 note. No MCP or permission config yet. |
| `.devcontainer/devcontainer.json` | Ubuntu base + Node LTS + Claude Code + Copilot + GitHub CLI | Node/npx present → MCP server can run via `npx`. ✅ |
| `.devcontainer/post-create.sh` | Installs antigravity, codex, opencode | Not needed for the Claude-Code-only goal (see §6). |
| MCP config | **None** | No `.mcp.json` exists. This is the core work. |

**Bottom line:** the container can already run an `npx`-based MCP server. The work is almost
entirely configuration + docs, exactly as scoped.

---

## 2. Target state

```
test-dynatrace-mcp/
├── .mcp.json                 # NEW — project-scoped Dynatrace MCP server definition
├── .env.example              # UPDATED — Dynatrace connection vars, documented
├── AGENTS.md                 # UPDATED — Dynatrace context, DQL tips, safety rules
├── README.md                 # UPDATED — how to connect & explore via Claude Code
├── CLAUDE.md                 # unchanged (@AGENTS.md)
├── docs/
│   └── EXPLORING.md          # NEW (optional) — example prompts & a guided tour
├── .claude/
│   └── settings.json         # UPDATED — MCP tool permission allowlist (optional)
└── .devcontainer/            # minor cleanup (see §6)
```

---

## 3. Prerequisites (you provide these)

Before Claude can talk to Dynatrace you need, from a Dynatrace tenant:

1. **Environment URL** — the Platform (Grail) URL, e.g. `https://<envid>.apps.dynatrace.com`. **`[VERIFY]`** exact variable name (commonly `DT_ENVIRONMENT`).
2. **Authentication** — the MCP server supports either: **`[VERIFY]`**
   - a **Platform token** (simplest; single `DT_PLATFORM_TOKEN`-style var), or
   - an **OAuth client** (client id + secret) for the platform.
3. **Scopes/permissions** on that token — grant only what you intend to explore. Likely-relevant read scopes **`[VERIFY]`**:
   - Grail/DQL query, logs read, metrics read, entities read, events read,
   - problems (Davis) read, security problems / vulnerabilities read,
   - (optional, write) event ingest / notifications — **skip for a read-only exploration**.

> Start **read-only**. Add write scopes deliberately, later, if you want to try them.

---

## 4. Work items

### Phase 1 — Add the Dynatrace MCP server  *(core)*

1. Create **`.mcp.json`** at the project root (Claude Code auto-loads project-scoped MCP servers
   from here). Use **env-var expansion** so no secret is ever committed:

   ```jsonc
   {
     "mcpServers": {
       "dynatrace": {
         "command": "npx",
         "args": ["-y", "@dynatrace-oss/dynatrace-mcp-server"],   // [VERIFY] package name
         "env": {
           "DT_ENVIRONMENT": "${DT_ENVIRONMENT}",                 // [VERIFY] var names
           "DT_PLATFORM_TOKEN": "${DT_PLATFORM_TOKEN}"
         }
       }
     }
   }
   ```
   - `${VAR}` values are resolved by Claude Code from the environment — keep the real values in
     `.env` (git-ignored) or the shell, never in `.mcp.json`.
   - **`[VERIFY]`** exact package name, binary, and required env vars via context7 / the repo.

2. Confirm registration and health:
   ```bash
   claude mcp list          # dynatrace should appear
   /mcp                     # inside a claude session: check "connected" + list tools
   ```

### Phase 2 — Environment & secrets

1. Rewrite **`.env.example`** with documented Dynatrace vars (no real values):
   ```dotenv
   # Dynatrace platform (Grail) environment URL
   DT_ENVIRONMENT=https://<envid>.apps.dynatrace.com
   # Platform token (read-only scopes recommended to start)  [VERIFY name]
   DT_PLATFORM_TOKEN=
   # --- OR OAuth instead of a platform token ---  [VERIFY names]
   # OAUTH_CLIENT_ID=
   # OAUTH_CLIENT_SECRET=
   ```
2. Document `cp .env.example .env` and how `.env` is loaded before launching `claude`
   (e.g. `set -a; source .env; set +a; claude`). **`[VERIFY]`** whether the MCP server auto-reads
   `.env` from the project dir — if it does, this step simplifies.
3. `.gitignore` already covers `.env*`. ✅ No change needed.

### Phase 3 — Tune `AGENTS.md`  *(core; currently empty)*

Populate `AGENTS.md` so the agent is effective and safe with Dynatrace. Sections to include:

- **Project purpose** — this repo exists to explore the Dynatrace MCP server via Claude Code.
- **What the agent can do here** — query observability data (problems, logs, metrics, entities,
  traces, security findings) through the `dynatrace` MCP tools; no app code to build.
- **How to query** — prefer the Dynatrace MCP tools over shell; when writing **DQL** (Dynatrace
  Query Language) keep queries scoped and time-bounded; explain the query before running it.
- **Safety rails** — read-only by default; **never** ingest events, change config, or run write
  operations unless the user explicitly asks; always show the query/tool call and expected impact
  first; treat tenant data as sensitive (don't paste secrets or full PII into files).
- **Cost/scope awareness** — bound time ranges, limit result sizes, avoid unbounded scans on Grail.
- **Conventions** — Markdown rules, where to put notes (`docs/`), and to keep secrets out of git.

### Phase 4 — Documentation

1. **`README.md`** — repurpose from "generic template" to "Dynatrace MCP exploration":
   - What the project is, prerequisites (§3), setup (§Phase 1–2), how to start exploring.
   - A short "first session" walkthrough (open `claude`, run `/mcp`, ask a question).
2. **`docs/EXPLORING.md`** *(optional but recommended)* — a menu of starter prompts, e.g.:
   - "List the open problems in the last 24h and summarize root causes."
   - "Show error logs for service X in the last hour."
   - "What entities depend on <host>?"
   - "Summarize open security vulnerabilities by severity."
   - A short DQL cheat-sheet section.

### Phase 5 — Claude Code ergonomics *(optional, quality-of-life)*

1. **Permission allowlist** in `.claude/settings.json` so common Dynatrace tool calls don't prompt
   every time. MCP tool permission ids look like `mcp__dynatrace__<tool>`. **`[VERIFY]`** exact tool
   names from `/mcp`, then allow the read-only ones, e.g.:
   ```jsonc
   { "permissions": { "allow": ["mcp__dynatrace__*"] } }   // or enumerate read-only tools
   ```
   (The `/fewer-permission-prompts` skill can generate this from real usage after a session.)
2. Leave the OpenRouter/DeepSeek block in `.claude/settings.json` alone unless you actually intend
   to route through a non-Anthropic model — see §7.

---

## 5. Verification / acceptance checklist

- [ ] `claude mcp list` shows `dynatrace`.
- [ ] `/mcp` in a session reports **connected** and lists tools.
- [ ] A simple read query (e.g. "list open problems") returns real tenant data.
- [ ] No secrets are committed (`git status` clean of `.env`; `.mcp.json` uses `${VAR}` only).
- [ ] `AGENTS.md` is non-empty and reflects the Dynatrace purpose.
- [ ] `README.md` describes setup accurately; a fresh clone can be brought up from it alone.
- [ ] Rebuilding the devcontainer still yields a working `claude` + `npx`.

---

## 6. Suggested improvements (optional)

- **Trim `post-create.sh`.** The Claude-Code-only goal doesn't need antigravity, codex, or
  opencode. Removing them speeds up container builds. Keep them only if you want to compare MCP
  behavior across CLIs.
- **Pre-warm the MCP package** in `post-create.sh` (`npx -y <pkg> --version || true`) so the first
  `claude` session doesn't pay the download cost. **`[VERIFY]`** package name first.
- **Pin the MCP server version** in `.mcp.json` args (`<pkg>@x.y.z`) for reproducibility, matching
  the `devcontainer-lock.json` philosophy already in the repo.
- **`containerEnv` passthrough** in `devcontainer.json` for `DT_ENVIRONMENT` etc., or use
  Codespaces **secrets**, so the container has credentials without a manual `source .env`.
- **Prune VS Code extensions** to the ones you'll use (Claude Code + GitHub); drop Copilot/Gemini/
  ChatGPT if unused.
- **Add a `.claude/` slash command** (e.g. `/dt-triage`) capturing a favorite investigation flow,
  once you know which prompts you reuse.
- **`docs/EXPLORING.md`** as the living notebook of prompts + DQL that worked.

## 7. Notes & open questions

- **`.claude/settings.json` model routing.** The current file points Claude Code at OpenRouter with
  `deepseek/deepseek-v4-pro` (all keys currently disabled via the `_` prefix). The stated goal is
  "explore via Claude Code CLI" — decide whether you want stock Anthropic Claude (leave disabled /
  remove) or the OpenRouter route (enable + fill keys). This is independent of the Dynatrace work.
- **Auth method choice.** Platform token vs OAuth — pick one for the first pass (token is simpler).
- **All `[VERIFY]` items** above should be confirmed via context7 / the official repo before wiring,
  since exact package name, env var names, and scope names drive whether the connection works.

---

## 8. Suggested execution order

1. `/reload-plugins`, then verify all `[VERIFY]` items via context7 (package, env vars, scopes).
2. Phase 1 (`.mcp.json`) → Phase 2 (`.env.example`) → connect & smoke-test (`/mcp`).
3. Phase 3 (`AGENTS.md`) → Phase 4 (docs).
4. Phase 5 (permissions) + §6 improvements as desired.
5. Run the §5 checklist.
