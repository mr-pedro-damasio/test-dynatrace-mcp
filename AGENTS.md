# AGENTS.md — Dynatrace MCP exploration sandbox

> This file is the single source of truth for agent behavior in this repo.
> `CLAUDE.md` and `.github/copilot-instructions.md` both delegate here.

## Project purpose

This repository is a **purpose-built sandbox for exploring the Dynatrace MCP server
through the Claude Code CLI**. There is **no application code to build or ship** — the
deliverables are configuration and documentation. Your job is to help the user query and
reason about their Dynatrace observability data safely and efficiently.

The Dynatrace MCP server is declared in `.mcp.json` and runs via
`npx @dynatrace-oss/dynatrace-mcp-server@latest`. It connects to the Dynatrace **Platform
(Grail)** tenant configured in `.env` (`DT_ENVIRONMENT`, `DT_PLATFORM_TOKEN`). See
`.env.example` and `README.md` for setup.

## What you can do here

You have a `dynatrace` MCP server with tools for reading observability data:

- **Problems & incidents** — `list_problems`, and Davis AI analysis via
  `list_davis_analyzers` / `execute_davis_analyzer`.
- **Security** — `list_vulnerabilities`.
- **Errors & exceptions** — `list_exceptions`.
- **Ad-hoc queries** — `execute_dql` (run DQL), `verify_dql` (validate before running),
  `generate_dql_from_natural_language`, `explain_dql_in_natural_language`.
- **Entities & topology** — `find_entity_by_name`.
- **Kubernetes** — `get_kubernetes_events`.
- **Environment** — `get_environment_info`.
- **Davis CoPilot** — `chat_with_davis_copilot` for natural-language help.

Prefer these MCP tools over shell commands (`curl`, etc.) for anything Dynatrace — they
handle auth, paging, and the Grail budget for you.

## Write / side-effecting tools — require explicit user request

These tools change state or notify people. **Do not call them unless the user explicitly
asks**, and confirm the exact payload and recipients first:

- `send_email`, `send_slack_message` — send notifications to real people.
- `send_event` — ingests an event into the tenant.
- `create_dynatrace_notebook` — creates a notebook in the tenant.
- `reset_grail_budget` — clears the local query-budget guardrail (see below).

## How to query

- **Explain before you run.** State in one line what a query/tool call will do and why,
  then run it. For DQL, show the query first.
- **Validate DQL** with `verify_dql` before `execute_dql` when a query is non-trivial —
  it catches syntax/scope errors cheaply.
- **Scope and time-bound every query.** Add explicit time ranges (e.g. last 1h/24h),
  `filter` early, and `limit` result size. Never run unbounded scans over Grail.
- **Iterate small.** Start narrow (one service, short window, small limit), confirm the
  shape of the data, then widen only if needed.
- If unsure how to express something, use `generate_dql_from_natural_language` to draft
  and `explain_dql_in_natural_language` to sanity-check an existing query.

## Safety rails

- **Read-only by default.** Querying is safe; writing is not. Never ingest events, send
  notifications, change config, or run any write operation unless the user explicitly
  asks for that specific action.
- **Always show the tool call and expected impact first** for anything that leaves a
  trace or notifies someone.
- **Treat tenant data as sensitive.** Don't paste secrets, tokens, or full PII into files
  committed to the repo. Keep credentials in `.env` (git-ignored) only. When saving
  findings to `docs/`, redact identifiers that aren't needed.

## Cost / scope awareness (Grail)

- Grail bills by **bytes scanned**, so bounded time ranges and early filters directly
  reduce cost. The optional `DT_GRAIL_QUERY_BUDGET_GB` guardrail in `.env` fails fast on
  runaway scans — respect it rather than resetting it.
- Avoid `fetch` over wide time windows without `filter`/`limit`. Prefer aggregations
  (`summarize`, `makeTimeseries`) over pulling raw records when you only need counts/trends.

## Conventions

- **Secrets stay out of git.** `.gitignore` already excludes `.env*`; `.mcp.json` uses
  `${VAR}` expansion only. Don't hardcode a tenant URL, token, or query result containing
  sensitive data into tracked files.
- **Notes and reusable prompts** go in `docs/` (e.g. `docs/EXPLORING.md`), not scattered
  in the repo root.
- **Markdown:** keep lines readable, use fenced code blocks with a language, and prefer
  tables for structured comparisons.
- Keep this file and `README.md` in sync when the setup or tool inventory changes.
