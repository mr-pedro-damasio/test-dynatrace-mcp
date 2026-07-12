# Dynatrace MCP Exploration Sandbox

> A devcontainer wired to query a **Dynatrace Platform (Grail)** tenant through the
> **Dynatrace MCP server** in the **Claude Code CLI**. There is no application code to
> build — the deliverables are configuration and documentation for safe, read-only
> observability exploration.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/mr-pedro-damasio/test-dynatrace-mcp)

---

## Overview

This repository lets you point Claude Code at your Dynatrace tenant and ask questions
about problems, logs, metrics, entities, traces, and security findings — in natural
language or DQL. The [`dynatrace`](https://github.com/dynatrace-oss/dynatrace-mcp) MCP
server is declared in `.mcp.json` and launched automatically by Claude Code via
`npx @dynatrace-oss/dynatrace-mcp-server@latest`.

Exploration is **read-only by default**. Write/side-effecting tools (sending email or
Slack, ingesting events, creating notebooks) are never invoked unless you explicitly ask.
See [`AGENTS.md`](AGENTS.md) for the full agent behavior contract.

---

## What's Included

- **Dynatrace MCP server** — declared in `.mcp.json`, connects to your tenant using
  `${VAR}` expansion so no secret is ever committed.
- **Dev Container** — Ubuntu base with Node.js LTS (so `npx` can run the MCP server) and
  the Claude Code CLI pre-installed.
- **Agent instructions** — `CLAUDE.md` → `AGENTS.md` describe the Dynatrace context, how
  to write scoped DQL, and the read-only safety rails.
- **Docs** — [`docs/EXPLORING.md`](docs/EXPLORING.md): a menu of starter prompts and a
  short DQL cheat-sheet.

---

## Prerequisites

From your Dynatrace tenant you need:

1. **Environment URL** — the Platform (Grail) URL, e.g. `https://<envid>.apps.dynatrace.com`
   (the `apps.dynatrace.com` host, **not** the classic `live.dynatrace.com`).
2. **Authentication** — either a **Platform token** (simplest; single `DT_PLATFORM_TOKEN`)
   or an **OAuth client** (`OAUTH_CLIENT_ID` + `OAUTH_CLIENT_SECRET`).
3. **Read scopes** on that token — grant only what you intend to explore (Grail/DQL query,
   logs/metrics/entities/events read, problems and security read). Start read-only; add
   write scopes deliberately, later, only if you want to try them.

> Create a Platform token under **Settings → Platform tokens** in your tenant.

---

## Setup

### Option 1 — GitHub Codespaces (recommended)

1. Click **Open in GitHub Codespaces** above, or **Code → Codespaces → New codespace**.
2. Wait for the environment to build (first run takes a few minutes).
3. Configure credentials:
   ```bash
   cp .env.example .env
   # Edit .env: set DT_ENVIRONMENT and DT_PLATFORM_TOKEN
   ```
4. Open a **new** terminal. `post-create.sh` adds a snippet to `~/.bashrc` that
   auto-loads `.env` into every new shell, so the vars are ready for `claude`.

### Option 2 — Dev Container (local)

**Prerequisites:** [Docker Desktop](https://www.docker.com/products/docker-desktop) and the
[Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

1. Clone the repository and open it in VS Code.
2. When prompted, click **Reopen in Container**.
3. `cp .env.example .env` and fill in `DT_ENVIRONMENT` + `DT_PLATFORM_TOKEN`.
4. Open a **new** terminal so the `.env` auto-load applies.

> **Never commit `.env`.** `.gitignore` already excludes `.env*`, and `.mcp.json` uses
> `${VAR}` expansion only — real values live in `.env` (git-ignored) or your shell.

See [`.env.example`](.env.example) for every variable, both auth options, token storage,
and the optional Grail cost guardrail.

---

## Your First Session

1. **Launch Claude Code** from a terminal that has the `.env` vars loaded:
   ```bash
   claude
   ```
   (Outside the devcontainer, or in a shell opened before setup, load them first:
   `set -a; source .env; set +a; claude`.)

2. **Confirm the server is connected** — inside the session run:
   ```
   /mcp
   ```
   `dynatrace` should report **connected** and list its tools. From a shell you can also
   run `claude mcp list`.

3. **Ask a question.** For example:
   > List the open problems in the last 24h and summarize the likely root causes.

   Claude will explain the query, run the read-only `dynatrace` tool, and summarize the
   result. Browse [`docs/EXPLORING.md`](docs/EXPLORING.md) for more starter prompts.

> If `claude mcp list` prints a *"Missing environment variables: OAUTH_CLIENT_ID,
> OAUTH_CLIENT_SECRET"* warning while using a platform token, it is harmless — those
> OAuth vars are simply unset. Remove the two lines from `.mcp.json` to silence it.

---

## Available Tools

The `dynatrace` MCP server exposes read tools for:

| Area | Tools |
|------|-------|
| Problems & incidents | `list_problems`, `list_davis_analyzers`, `execute_davis_analyzer` |
| Security | `list_vulnerabilities` |
| Errors & exceptions | `list_exceptions` |
| Ad-hoc queries (DQL) | `execute_dql`, `verify_dql`, `generate_dql_from_natural_language`, `explain_dql_in_natural_language` |
| Entities & topology | `find_entity_by_name` |
| Kubernetes | `get_kubernetes_events` |
| Environment | `get_environment_info` |
| Davis CoPilot | `chat_with_davis_copilot` |

**Write / side-effecting tools** — `send_email`, `send_slack_message`, `send_event`,
`create_dynatrace_notebook`, `reset_grail_budget` — are **never called unless you
explicitly ask**, and Claude confirms the payload and recipients first.

---

## Cost & Safety

- **Grail bills by bytes scanned.** Every query is time-bounded, filtered early, and
  `limit`-ed. Set `DT_GRAIL_QUERY_BUDGET_GB` in `.env` to fail fast on runaway scans.
- **Read-only by default.** See [`AGENTS.md`](AGENTS.md) for the complete safety contract.
- **Tenant data is sensitive.** Don't paste secrets or full PII into tracked files; put
  reusable notes in `docs/`.

---

## License

[MIT](LICENSE) © 2026 mr-pedro-damasio
