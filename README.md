# sprc-lab — Claude Code plugin marketplace

Internal Claude Code plugins for the lab's **sprc** HPC cluster.

Currently hosts one plugin:

- **`sprc-slurm`** — teaches any Claude Code agent how to actually run work on the sprc H100 Slurm
  cluster (controller `sprlab005`): stage and submit `sbatch` jobs, interactive `salloc` GPU
  sessions, pick the right QoS/walltime, and monitor/debug — execute-first, not a tutorial.

---

## For colleagues: how to install

You need Claude Code (`claude`) installed. Then pick whichever source is easiest:

### Option A — from the shared filesystem (easiest on the cluster)

Because we all share the cluster filesystem, you can add the marketplace straight from its path — no
GitHub needed. In a Claude Code session:

```
/plugin marketplace add /shared/path/to/sprc-cluster-marketplace
/plugin install sprc-slurm@sprc-lab
```

(Replace `/shared/path/...` with wherever this repo lives on the shared FS — ask Max for the exact
path, e.g. `~maxbromberg/sprc-cluster-marketplace` if it's readable, or a `/projects/...` location.)

### Option B — from GitHub (works anywhere)

```
/plugin marketplace add <github-owner>/sprc-cluster-marketplace
/plugin install sprc-slurm@sprc-lab
```

For a **private** repo, make sure your `gh` CLI is authenticated (`gh auth login`) first.

### Verify it's active

```
/plugin            # should list sprc-slurm as installed/enabled
```

Then just ask Claude to do cluster work normally — "get train.py running on the cluster for ~6h",
"grab me a GPU node to debug in", "submit this as a scavenger sweep". The skill triggers on its own.

---

## Updating

When Max pushes a new version:

```
/plugin marketplace update sprc-lab
/plugin update sprc-slurm@sprc-lab
```

---

## For Max: how to publish / maintain

This directory is **both** a marketplace and the plugin host. Layout:

```
sprc-cluster-marketplace/
├── .claude-plugin/marketplace.json     # marketplace manifest (lists plugins)
└── plugins/
    └── sprc-slurm/
        ├── .claude-plugin/plugin.json  # plugin manifest (name/version/author)
        └── skills/slurm/               # the skill itself (SKILL.md + references + assets)
```

**Publish once (shared FS):** just make sure this folder sits somewhere lab members can read on the
shared filesystem and tell them the path. That's it — Option A works immediately.

**Publish to GitHub (portable):**

```bash
cd ~/sprc-cluster-marketplace
git init && git add -A && git commit -m "sprc-slurm v0.1.0"
gh repo create sprc-cluster-marketplace --private --source=. --push   # or --public
```

**Ship an update:**

1. Edit the skill under `plugins/sprc-slurm/skills/slurm/` (and bump `version` in
   `plugins/sprc-slurm/.claude-plugin/plugin.json`).
2. `git commit -am "..." && git push` (GitHub) — or nothing extra for the shared-FS path.
3. Tell colleagues to run the **Updating** commands above.

> The canonical/develop copy of the skill lives at `~/.claude-personal/skills/slurm/`. When you
> change it there, copy it back into `plugins/sprc-slurm/skills/slurm/` (excluding `evals/`) before
> committing, so the published plugin matches.
