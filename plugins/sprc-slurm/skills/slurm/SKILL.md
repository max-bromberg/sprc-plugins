---
name: slurm
description: >-
  Run work on the lab's `sprc` H100 GPU cluster (login/controller `sprlab005`) via Slurm: stage and
  submit `sbatch` jobs, open interactive `salloc` GPU sessions and SSH onto compute nodes, pick
  GPUs/CPUs/memory, walltime, and QoS tier (`normal`/`undergrad`/`expedite`/`scavenger`), and
  monitor/debug jobs. Use it to actually GET WORK RUNNING, not just explain it. Reach for it
  whenever the user wants to run, submit, schedule, queue, launch, or kick off a job; train, test,
  benchmark, profile, fine-tune, or sweep on a GPU/node; grab or allocate a node or "a GPU"; check
  on a long run; or troubleshoot a pending/stuck/failed job — especially anything mentioning
  `sprc`, `sprlab005`, `sbatch`/`salloc`/`srun`/`squeue`/`sacct`/`scancel`/`sinfo`/`scavenger`/`expedite`,
  even if they never say "Slurm." Do NOT use it for administering Slurm itself
  (`slurmctld`/`slurmd`), conceptual "how does X work" questions with no job to run, fixing
  SSH/login/networking, or work on a local laptop (local GPUs, GNU `parallel`, `cron`).
---

# Running work on the `sprc` cluster (Slurm)

## Operating posture: do the work, don't narrate it

The people on this cluster are experienced — they already know what Slurm is and how the workflow
goes. They invoke you to **get their work running**, not to be taught the steps. So **default to
executing**: figure out the resources, write the job script, submit it, and report back tersely
(job id + the one command they'd use to watch it). Don't preface a run with a tutorial on QoS tiers,
fair-share, or "here's how Slurm works" — that's noise they have to scroll past.

- **Act first.** When the user describes work to run, *stage and submit it.* The deliverable is a
  running (or ready-to-submit) job, not an explanation of how you'd submit it.
- **Be terse.** A good response is the script you wrote + "Submitted job 12345; watch with
  `tail -f myrun-12345.out`." A paragraph per flag is too much.
- **Explain only on demand.** If the user asks "why", "how does X work", or "what are my options",
  *then* explain — and pull in the references below for the specifics.
- **Terse ≠ withholding.** Brevity is about cutting what they already know, not what they need to
  know. Always surface — in a line — the caveat that would otherwise burn them: their job needs
  checkpointing because it'll be requeued, they're not onboarded so nothing will submit, their
  `--time` is too short for the run, their files aren't on the shared FS the nodes can see. Flag it,
  don't lecture it.
- **One judgment call to flag, not lecture:** when a choice genuinely affects them (e.g. `normal`
  vs. `scavenger` for a big sweep), state the pick and a half-line why, then proceed.

This posture is the point of the skill. Everything below is what you need to act *correctly* for
*this* cluster — keep it in your head, but keep it out of your reply unless asked.

## Act correctly: the cluster facts that change what you do

These are the things a generic Slurm answer gets wrong here. Get them right silently.

- **Never run real work on the login node `sprlab005`.** Anything using a GPU or sustained CPU/RAM
  goes through `sbatch`/`salloc`. The login node is for editing, submitting, monitoring — and each
  user is now **hard-capped at 8 vCPUs there** (systemd cgroup), so heavy local work is throttled,
  not just frowned upon. Real compute belongs on a node.
- **No GPU unless you ask.** Add `--gres=gpu:N` (or `--gpus=N`). CPUs and RAM then auto-derive — you
  rarely set them. Per GPU you get **32 CPUs (16 cores) + ~384 GB**; a CPU-only job floors at 4 CPUs
  (~48 GB). So usually: **request GPUs + `--time`, nothing else.**
- **Interactive vs. batch decides the partition and the walltime cap — automatically.** `sbatch`
  runs on `main` (3-day cap). `salloc`/`srun` (interactive) are **auto-routed to `debug` and capped
  at 1 hour** by `job_submit.lua` — you do **not** pass `-p`. Two consequences to internalize: an
  interactive job that names a non-`debug` partition (e.g. `-p main`) is **rejected**, and an
  interactive `--time` over 1 h is **silently clamped to 1 h**. So **anything longer than an hour
  must be `sbatch`** — never try to hold a long `salloc`. Set an honest `--time` regardless (batch
  backfills sooner with an accurate short walltime; jobs are killed at the limit).
- **GPUs come from the QoS, not a partition.** Default QoS is right for almost everything; only pass
  `--qos` for the two special cases below.
- **Allocate before you SSH to a node.** `ssh sprcNN` is *denied* without an allocation there; with
  one, you land on the node scoped to your job's GPUs/cores/RAM. So always `salloc` first.
- **Onboarding gate.** If `sacctmgr show assoc where user=$USER` is empty, every submit is rejected
  (`Invalid account...`). You can't fix this — tell the user to ask a sysadmin to add them. Don't retry.

Exact numbers, caps, and the rationale live in `references/cluster-facts.md` — read it before quoting
a specific limit; don't recite from memory.

## The default path: stage and submit a batch job

This is what to do for "run / submit / kick off X". Steps, not prose:

1. **Decide** GPUs (from what the work needs) and an honest `--time` (estimate + ~25–50% margin,
   under the 3-day cap). Leave CPU/RAM as defaults unless the work is lopsided.
2. **Write the script.** Start from `assets/job-template.sbatch`, fill in the `#SBATCH` lines and the
   work command. Launch the actual work with `srun` inside the script. For long runs, wire up
   checkpoint/resume and add `--requeue` — jobs can hit walltime or be requeued.
3. **Submit** (`sbatch job.sbatch`), then **report** the job id + how it'll be watched. Don't run the
   work yourself on the login node.
4. **Own the follow-through — don't just hand over check commands and leave.** A long job isn't
   handled when you submit it; it's handled when you've reported how it *ended*. So your default is to
   **set up a background monitor yourself and tell the user you'll report back** — e.g. close with
   "Submitted job 12345 — I'll watch it and report when it finishes." (You can still give them a
   `squeue --me` / `tail -f` to peek if they want; that's in addition, not instead.) Don't make the
   user poll and come back to ask.

   In Claude Code, launch the watch as a **background** command — it returns when the job leaves the
   queue and the harness re-invokes you, so you report completion (and surface a failure promptly)
   without blocking the user:

   ```bash
   until ! squeue -j <id> -h -t PENDING,RUNNING,COMPLETING -o %T | grep -q .; do sleep 60; done
   sacct -j <id> --format=JobID,State,Elapsed,MaxRSS,ExitCode    # then report the outcome
   ```

   On other harnesses, use whatever background/notify mechanism exists. The principle is the same:
   *submit, then arrange to follow up and report* — never poll inline in a way that blocks the user.
   (If you're only staging a job for the user to submit themselves, still say you'll set up the watch
   once it's submitted, so the follow-through is the plan, not an afterthought.)

Minimal correct script (the template asset is the annotated version):

```bash
#!/bin/bash
#SBATCH --job-name=myrun
#SBATCH --gres=gpu:1
#SBATCH --time=8:00:00
#SBATCH --output=%x-%j.out
set -euo pipefail
srun ./run_my_thing.sh
```

Then: `sbatch job.sbatch` → `squeue --me` (PD pending / R running / CG completing) →
`tail -f myrun-<id>.out`. `scontrol show job <id>` shows the `Reason=` if it's stuck.

## Interactive when they want to poke at a node

For "give me a shell on a GPU / debug live / open a REPL": get them into an allocation, don't lecture.
Interactive sessions are **auto-routed to `debug` and capped at 1 hour** — this is for hands-on work,
not long runs.

```bash
salloc --gres=gpu:1 --time=1:00:00     # interactive allocation on debug (≤1h); work here via srun, or:
squeue --me                            # see the node (e.g. sprc02)
ssh sprc02                             # only works because you hold an allocation there
```

Don't pass `-p main` (or any non-`debug` partition) to an interactive job — it's rejected. Don't
request more than `--time=1:00:00` — it's clamped to the hour. **If the work needs longer than an
hour, it isn't an interactive job — write an `sbatch` script instead** (the default path above).
Remind them to `exit`/`scancel` when done (an idle `salloc` holds GPUs and costs fair-share).

## QoS: default is fine; deviate in two cases

Pass `--qos` only when one of these applies — otherwise say nothing about QoS:

- **`--qos=scavenger`** for big *restartable* batches (sweeps, anything that checkpoints): soaks idle
  GPUs (up to all 8), lowest priority, **requeued the instant a real job needs the GPU**. The
  good-neighbor choice for bulk work — but only if it actually checkpoints. Pair with a job array.
  **Batch only** — an interactive `salloc --qos=scavenger` is rejected; use `sbatch`.
- **`--qos=expedite`** for a genuine deadline — but it's **sysadmin-granted per user** and not
  self-serve. If the user needs it, tell them to ask; until granted, `--qos=expedite` is rejected.
  (It's also the one QoS exempt from the interactive 1 h cap, so a granted user's `salloc` runs its
  full 24 h — but for long *unattended* work, `sbatch` is still the right tool; don't reach for
  expedite just to stretch an interactive session.)

## Monitor / debug

```bash
squeue --me                 # my jobs + state
scontrol show job <id>      # full detail + Reason= for pending
squeue --start              # ETA for pending jobs
sacct -j <id> --format=JobID,State,Elapsed,MaxRSS,ExitCode    # post-mortem
```

When a job won't start or fails, **read the `Reason=` before changing flags** — don't shotgun. Most
common: `Priority`/`Resources` = just waiting; `QOSMaxGRESPerUser` = at your per-user GPU cap (4 on
`normal`), running jobs must free one — not routable around; killed at walltime = raise `--time` +
checkpoint; OOM = raise `--mem`. The full error→cause→fix table is `references/troubleshooting.md` —
consult it for anything non-obvious, and explain to the user only what they need.

## Email notifications (opt-in)

Slurm emails **nothing by default** — it's per-job opt-in. To notify the user about a job, add:

```bash
#SBATCH --mail-type=END,FAIL        # events: BEGIN, END, FAIL, ALL, TIME_LIMIT_90 …
#SBATCH --mail-user=<netid>         # bare netid is enough → <netid>@illinois.edu
```

- **Bare netid works** — the cluster qualifies it to `<netid>@illinois.edu` (their campus inbox); a
  full address (internal or external) is fine too.
- **If their login name isn't their netid, set `--mail-user` explicitly.** Omitting it defaults the
  recipient to `<login>@illinois.edu`, which for those users isn't a real mailbox — the mail is then
  silently dropped (no error, job runs normally). Flag this rather than let it bite them.
- **Off** = omit `--mail-type` (already the default), or `--mail-type=NONE` to override one baked into
  a script.
- For a sweep/array, `--mail-type=ALL` floods the inbox (one mail per state change per task) — prefer
  `FAIL` only, or skip mail and rely on the background watch above.
- Mail comes from `no-reply@illinois.edu` ("SPRC Cluster") — send-only, replies go nowhere.

## Where you're running, and the references

- **On `sprlab005`**: commands run directly; files live on the shared FS the compute nodes also see.
- **From a laptop**: `ssh sprlab005` and run there — and make sure the user's **code/data are on the
  cluster's shared filesystem**, not just the laptop (a compute node can't see local disk). Stage the
  project over first if needed.

Pull these in only when relevant — they're for getting the details right or answering a "why":
- `references/cluster-facts.md` — hardware, exact defaults/caps, QoS table, scheduling knobs.
- `references/troubleshooting.md` — error → cause → fix.
- `references/admin-ops.md` — things that need a sysadmin (onboarding, `expedite`, reservations);
  recognize these and tell the user to ask, don't try to work around them.
