# sprc-plugins

A [Claude Code](https://claude.com/claude-code) plugin marketplace for working on the **sprc** HPC
cluster — a 4-node, 8× H100-NVL Slurm cluster (controller/login node `sprlab005`).

Currently one plugin:

- **`sprc-slurm`** — teaches a Claude Code agent how to *actually run work* on the cluster:
  stage and submit `sbatch` jobs, open interactive `salloc` GPU sessions, pick the right
  GPUs/walltime/QoS tier, monitor and debug jobs, and follow through on long runs — execute-first,
  not a wall of explanation. It encodes the cluster's real defaults and policies (per-GPU CPU/RAM
  defaults, the `normal`/`undergrad`/`expedite`/`scavenger` QoS tiers and per-user caps, the
  `main`/`debug` partitions, SSH-adoption rules) so Claude gives *this cluster's* answer instead of
  generic Slurm boilerplate.

> **Note:** the facts baked in are specific to the sprc cluster. If you're a member of that cluster,
> install and go. If you run a *different* Slurm cluster, this is still a useful starting point —
> see [Adapting it for your own cluster](#adapting-it-for-your-own-cluster).

---

## Install

You need [Claude Code](https://claude.com/claude-code) installed. Then, in a Claude Code session:

```
/plugin marketplace add max-bromberg/sprc-plugins
/plugin install sprc-slurm@sprc-plugins
```

Verify it's active:

```
/plugin            # sprc-slurm should show as installed/enabled
```

(Already cloned the repo, or on a shared filesystem with the cluster? You can also add it by path:
`/plugin marketplace add /path/to/sprc-plugins`.)

## Use it

Just ask Claude to do cluster work in plain language — the skill triggers on its own. For example:

- "get `~/proj/train.py` running on the cluster, it needs 2 GPUs for about 10 hours"
- "grab me a GPU node to poke at my code in a Python REPL"
- "submit these 200 checkpointing eval jobs overnight without hogging the cluster"
- "my job's stuck PENDING with `QOSMaxGRESPerUser` — what's wrong?"

Claude will write and submit the job (or give you the exact command), pick sane resources, surface
anything you need to know, and — for long jobs — set up a background watch and report back when it
finishes.

## Updating

When a new version is published:

```
/plugin marketplace update sprc-plugins
/plugin update sprc-slurm@sprc-plugins
```

---

## What's in the box

```
sprc-plugins/
├── .claude-plugin/marketplace.json       # marketplace manifest
├── LICENSE                               # MIT
└── plugins/
    └── sprc-slurm/
        ├── .claude-plugin/plugin.json    # plugin manifest (name / version / author)
        └── skills/slurm/
            ├── SKILL.md                  # the workflow + operating posture
            ├── references/
            │   ├── cluster-facts.md      # hardware, defaults, QoS/partition tables
            │   ├── troubleshooting.md    # error → cause → fix
            │   └── admin-ops.md          # things that need a sysadmin (onboarding, expedite)
            └── assets/job-template.sbatch
```

## Adapting it for your own cluster

The skill is structured so the cluster-specific facts live in a few obvious places. To retarget it:

1. **Fork this repo.**
2. Edit `plugins/sprc-slurm/skills/slurm/references/cluster-facts.md` — node count/GPUs, CPU/RAM
   defaults, your QoS tiers and per-user caps, your partitions.
3. Update the cluster-specific lines in `SKILL.md` (login-node name, partition names, the
   "get these right" list) and `references/troubleshooting.md`.
4. Bump `version` in `plugins/sprc-slurm/.claude-plugin/plugin.json`, and point the install commands
   in this README at your fork.

The *design stance* (execute-first, terse-but-don't-withhold, facts in references, follow through on
long jobs) is cluster-agnostic and worth keeping.

## Publishing updates (maintainer)

1. Edit the skill under `plugins/sprc-slurm/skills/slurm/` and bump `version` in the plugin manifest.
2. `git commit -am "..." && git push`.
3. Users pick it up with the [Updating](#updating) commands above.

## License

[MIT](LICENSE) © 2026 Max Bromberg.
