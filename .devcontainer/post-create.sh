set -euo pipefail

curl -fsSL https://antigravity.google/cli/install.sh | bash
curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh
npm install -g  opencode-ai

# Auto-load the project's .env into every shell so MCP servers (e.g. Dynatrace)
# receive DT_ENVIRONMENT / DT_PLATFORM_TOKEN without a manual `source` step.
MARKER="# auto-load project .env for MCP servers"
if ! grep -qF "$MARKER" ~/.bashrc 2>/dev/null; then
  cat >> ~/.bashrc <<'BASHRC'

# auto-load project .env for MCP servers
if [ -f /workspaces/test-dynatrace-mcp/.env ]; then
  set -a; . /workspaces/test-dynatrace-mcp/.env; set +a
fi
BASHRC
fi
