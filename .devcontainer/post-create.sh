set -euo pipefail

curl -fsSL https://chatgpt.com/codex/install.sh | sh
curl -fsSL https://antigravity.google/cli/install.sh | bash
npm install -g \
  opencode-ai
