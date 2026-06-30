<div align="center">

# ⚡ sprc-plugins

### Claude Code superpowers for the **sprc** H100 cluster

<sub>4 nodes · 8× H100-NVL · Slurm · controller <code>sprlab005</code></sub>

</div>

---

A [Claude Code](https://claude.com/claude-code) plugin marketplace for the **sprc** HPC cluster. It
ships one plugin, **`sprc-slurm`**, that lets Claude *actually run your work* on the cluster instead
of just explaining how: it stages and submits `sbatch` jobs, opens interactive `salloc` GPU
sessions, picks sane GPUs/walltime/QoS, monitors and debugs jobs, and follows through on long
runs — execute-first, terse, and tuned to this cluster's real defaults and policies.

## Add it

In a Claude Code session:

```
/plugin marketplace add max-bromberg/sprc-plugins
/plugin install sprc-slurm@sprc-plugins
/reload-plugins
```

…and you're set. Just ask Claude to run cluster work in plain language — *"get train.py running on
the cluster for ~6h"*, *"grab me a GPU node to debug in"*, *"submit these as an overnight
scavenger sweep"* — and the skill takes it from there.

## License

[MIT](LICENSE) © 2026 Max Bromberg.
