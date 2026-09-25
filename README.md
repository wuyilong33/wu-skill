# wuai — a multi-agent delivery workflow for DeepSeek Harness

A single slash-command skill that runs the heavy pipeline: reconnaissance →
consumer analysis → architect → parallel execution → convergence check →
independent audit.

Type `/wuai <what you want built or analyzed>` and the agent runs the whole
thing instead of improvising.

> **Status: early.** The workflow is written and installs cleanly, but it has
> been exercised only lightly on real tasks. Treat it as a strong skeleton,
> not a proven process — and read [Honest limitations](#honest-limitations)
> before relying on it.

## What it is

Most agent work fails in one of three places: it builds the wrong thing, it
breaks a caller nobody checked, or it declares success without evidence.
`wuai` is a written procedure aimed at those three failures specifically.

| Phase | What happens | Which failure it targets |
| --- | --- | --- |
| **0** Reconnaissance | Resolve the project root, build/refresh the knowledge graph, read the project's own rules, write an explicit boundary statement | Building something out of scope |
| **0.5** Consumer analysis | Name what is consumed, who reads it (`path:line`), what they assume, and which reader is actually broken | Fixing the wrong consumer |
| **1** Architect | Spec first, then ordered tasks with concrete `path:line` anchors. Mandatory when the change touches a contract | Building the wrong thing well |
| **2** Execute | Parallel writers, one per file, in a controlled environment | Conflicting concurrent edits |
| **2.5** Convergence check | Is the same bug recurring? Did the file grow? What ends this work? | Patches accumulating instead of integrating |
| **3** Audit | Independent read-only investigators, synthesised into ranked hypotheses | Blind spots shared with the author |
| **Report** | Boundary → built → verified → findings → unproven | Claims without evidence |

## Install

The skill lives in the global DSH skills directory:

```
~/.dsh/skills/wuai/SKILL.md
```

Copy the `wuai/` directory there:

```bash
mkdir -p ~/.dsh/skills
cp -r wuai ~/.dsh/skills/
```

Then add the trigger rule to `~/.dsh/AGENTS.md` so the command is recognised:

```markdown
## `/wuai` — the full delivery workflow

When the user's message begins with `/wuai`, load the `wuai` skill immediately
and follow it end to end. Everything after the command is the task.
```

Restart DeepSeek Harness so the skill is discovered.

## Usage

```
/wuai analyze the tunnel reconnect logic in this repo
/wuai add rate limiting to the upload endpoint
/wuai find why the nightly job silently skips records
```

Everything after `/wuai` is the task description.

## Requirements

- **DeepSeek Harness** with skills enabled.
- Optional but recommended: a **knowledge graph** for cheaper code reads. The
  workflow checks for one in Phase 0 and works without it, just slower.

The skill references these companion skills when installed. Missing ones are
skipped rather than fatal:

`spec-driven-development`, `planning-and-task-breakdown`,
`bug-hunt-swarm`, `code-review-and-quality`, `diagnose`, `tdd`,
`grill-me`, `incremental-implementation`

## Honest limitations

These are known and not yet fixed. They are listed here rather than buried.

**It has not been battle-tested.** The structure is sound and the constraints
are fact-checked, but the pipeline has run on very few real tasks. Phase 1
subagents may return vague plans instead of the anchor analysis they were
asked for; the parallel phases may hit the concurrency cap faster than the
batching handles.

**"No bugs" is not promised.** No process can guarantee that. What this
workflow commits to is narrower and honest: every claim carries pasted
evidence, and unverified things are reported as unverified.

**Cost is real.** A single `/wuai` run can use an order of magnitude more
tokens than ordinary conversation — an architect, parallel implementation
agents, and an independent audit. The workflow treats this as intended, but it
is your budget.

**Concurrency is capped by the host.** DeepSeek Harness allows at most **8**
live continuable subagents and a delegation depth of **1** — a subagent cannot
spawn its own subagents. Every delegated agent is therefore briefed completely
up front; there is no recursive decomposition.

**No failure-return path yet.** If the audit finds a serious defect, the
workflow as written does not loop back to re-implement and re-audit. That is a
known gap.

## Design notes

The phases exist because they fail differently:

- **Architect first** — the most expensive bug in software is building the
  wrong thing well. A spec and anchor analysis catch it before code exists.
- **Verify each unit** — a bug caught one step after it is introduced costs
  minutes; the same bug caught at the end costs the whole task.
- **Independent audit** — an agent reviewing its own work shares its own blind
  spots, so the audit is only worth running if it is genuinely independent and
  genuinely read-only.

## License

MIT
