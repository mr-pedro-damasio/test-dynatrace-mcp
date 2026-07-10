set -euo pipefail

curl -fsSL https://antigravity.google/cli/install.sh | bash
curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh
npm install -g  opencode-ai
