#!/usr/bin/env bash
# Install the sprc `slurm` skill for opencode and/or codex by symlinking it into
# the skills directory each tool scans. Skills use the same SKILL.md format in
# both tools, so one source serves both.
#
#   ./install.sh                 # global: codex (~/.codex/skills) + opencode (~/.config/opencode/skills)
#   ./install.sh .agents/skills  # a specific dir instead (e.g. project scope: BOTH tools read <repo>/.agents/skills)
#
# ponytail: symlink, not copy — one source of truth, edits propagate; both tools
# follow symlinked skill folders. Re-run to repoint after moving the repo.
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")/plugins/sprc-slurm/skills/slurm" && pwd)"

link() {  # link <skills-dir>
  mkdir -p "$1"
  ln -sfn "$src" "$1/slurm"
  echo "Linked $1/slurm -> $src"
}

if [ $# -gt 0 ]; then
  link "$1"
else
  link "${CODEX_HOME:-$HOME/.codex}/skills"              # codex (global)
  link "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills"  # opencode (global)
fi
echo "Restart opencode/codex to pick it up."
