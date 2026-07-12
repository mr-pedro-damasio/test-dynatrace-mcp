# Exploring Dynatrace with Claude Code

A living menu of starter prompts and a DQL cheat-sheet for querying your tenant through
the `dynatrace` MCP server. All prompts below are **read-only** — Claude explains each
query before running it, scopes it to a time window, and limits result size.

> New here? Read the [README](../README.md) for setup, then launch `claude` and run
> `/mcp` to confirm the `dynatrace` server is connected.

---

## Starter prompts

Paste any of these into a Claude Code session. Adjust service names, hosts, and time
windows to match your tenant.

### Problems & incidents

- *"List the open problems in the last 24h and summarize the likely root causes."*
- *"Which problems in the last 6h affected the most entities? Group by problem type."*
- *"Show the timeline of the highest-severity problem right now and what it impacts."*
- *"List the available Davis analyzers, then run the relevant one on service X."*

### Errors & exceptions

- *"Show the top exception types for service X in the last hour, with counts."*
- *"What new exceptions appeared in the last 3h that weren't seen in the prior 24h?"*

### Logs

- *"Show error-level logs for service X in the last hour, most recent first, limit 50."*
- *"Count log records by status for host Y over the last 2h."*

### Metrics & trends

- *"Chart the request rate and failure rate for service X over the last 3h."*
- *"What's the p95 response time trend for service X today vs. yesterday?"*

### Entities & topology

- *"Find the entity named `<host>` and show what depends on it."*
- *"What services run on host Y, and which are currently unhealthy?"*

### Security

- *"Summarize open security vulnerabilities by severity."*
- *"List the critical vulnerabilities affecting internet-facing services."*

### Kubernetes

- *"Show Kubernetes events in the last hour for namespace Z, warnings first."*

### Natural-language DQL help

- *"Draft a DQL query that counts failed requests per service in the last hour."*
  (Uses `generate_dql_from_natural_language`; Claude will `verify_dql` before running.)
- *"Explain what this DQL query does: `<paste query>`."*
  (Uses `explain_dql_in_natural_language`.)
- *"Ask Davis CoPilot how to correlate log spikes with a problem."*

---

## DQL cheat-sheet

DQL (Dynatrace Query Language) is pipeline-based: each `|` stage transforms the stream.
Keep queries **scoped, time-bounded, and limited** — Grail bills by bytes scanned.

### Anatomy

```dql
fetch logs, from: now() - 1h        // source + time window
| filter dt.entity.service == "SERVICE-1234"   // filter EARLY to cut bytes
| filter loglevel == "ERROR"
| sort timestamp desc               // order
| limit 50                          // cap result size
```

### Common building blocks

| Goal | Snippet |
|------|---------|
| Bound the time window | `fetch logs, from: now() - 24h, to: now()` |
| Filter early | `\| filter dt.entity.host == "HOST-ABC"` |
| Match text | `\| filter matchesPhrase(content, "timeout")` |
| Count by group | `\| summarize count(), by: {loglevel}` |
| Time series (trend) | `\| makeTimeseries count(), by: {dt.entity.service}` |
| Percentiles | `\| summarize p95 = percentile(duration, 95), by: {dt.entity.service}` |
| Top N | `\| sort count() desc \| limit 10` |
| Add a derived field | `\| fieldsAdd svc = dt.entity.service` |

### Cost-aware habits

- **Always** set an explicit `from:` (and `to:` when relevant) — never scan open-ended.
- `filter` **before** `summarize`/`sort` so fewer bytes flow downstream.
- Prefer `summarize` / `makeTimeseries` (counts, trends) over pulling raw records when
  you only need aggregates.
- Start narrow (one service, short window, small `limit`), confirm the data shape, then
  widen only if needed.
- Run `verify_dql` on anything non-trivial before `execute_dql` — it catches syntax and
  scope errors cheaply.
- Set `DT_GRAIL_QUERY_BUDGET_GB` in `.env` to fail fast on runaway scans.

### Common data sources

| Source | `fetch` target |
|--------|----------------|
| Logs | `fetch logs` |
| Spans / traces | `fetch spans` |
| Events | `fetch events` |
| Metrics | `timeseries` command (e.g. `timeseries avg(dt.host.cpu.usage)`) |
| Problems | `fetch dt.davis.problems` |
| Vulnerabilities | `fetch security.events` |

> Exact field and entity names depend on your tenant's data. When unsure, ask Claude to
> `generate_dql_from_natural_language` and it will draft + verify a query for you.

---

## Notes

Add prompts and DQL snippets that worked well for your tenant below, so this file grows
into a reusable investigation playbook.
