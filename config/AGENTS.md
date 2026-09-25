# Global agent instructions

This file applies to every session, in every workspace, on this machine.

## `/wuai` — the full delivery workflow

**When the user's message begins with `/wuai`, load the `wuai` skill
immediately and follow it end to end.** Everything after the command is the
task. Do not ask whether to run it, do not summarise it back, and do not
substitute a lighter process — the command *is* the instruction to run the
heavy pipeline.

`/wuai` means: recon → architect (spec + anchor analysis) → parallel
execution with per-unit verification → independent parallel audit → report.
The user has authorised spending agents and tokens freely; use them. The
non-negotiable part is that every claim carries pasted evidence, and that
failures are reported as failures.

The rest of this file applies in full during a `/wuai` run — especially the
"never claim a stage passed without evidence" rule and the delegation limits.

## Engineering skills — routing rules

A set of engineering skills is installed globally at `~/.dsh/skills/`. They are
**advisory** — not mandatory. Load one with the `skill` tool when the situation
below matches; if the user says to skip it, skip it and carry on normally.

The point of loading one is to switch on a *disciplined procedure* for a task
where improvising usually goes wrong.

| When the situation is… | Load this skill | What it buys |
| --- | --- | --- |
| A bug that resists a quick fix; a performance regression; something "broken" or "throwing" with no obvious cause | `diagnose` | Forced reproduce → minimise → hypothesise → instrument → fix → regression-test, instead of guessing at edits |
| Building a feature or fixing a bug where correctness matters and the change is not trivial | `tdd` | Red-green-refactor: a failing test first, then the code, then cleanup |
| A plan or design that is still fuzzy, or the user is about to commit to a direction | `grill-me` | Relentless interview that closes each branch of the decision tree before work starts |
| Requests for architecture improvement, refactoring, or untangling coupled modules | `improve-codebase-architecture` | Deepening opportunities informed by the project's own domain language and ADRs |
| Turning a discussion into written requirements or work items | `to-prd`, then `to-issues`, then `triage` | PRD → independently-grabbable issues → triage state machine |
| Reporting bugs conversationally and wanting them filed | `qa` | Background codebase exploration plus issue filing |
| Planning a refactor that must land in small safe steps | `request-refactor-plan` | Tiny-commit plan, filed as an issue |
| Mapping test files away from `as` assertions to shoehorn | `migrate-to-shoehorn` | Mechanical migration |
| Adding commit-time formatting, typechecking, and tests | `setup-pre-commit` | Husky + lint-staged wiring |
| Unfamiliar with a section of code and needing the bigger picture | `zoom-out` | Higher-level perspective on how a piece fits |
| Terminology drifting between people, code, and docs | `ubiquitous-language` | A canonical glossary written to `UBIQUITOUS_LANGUAGE.md` |
| Writing or extending a skill | `write-a-skill` | Correct structure and progressive disclosure |
| Wanting compressed output to save tokens | `caveman` | Drops filler while keeping technical accuracy |
| Editing prose — restructuring, clarity, tightening | `edit-article` | Editorial pass on a draft |
| Writing the interface for a new module, exploring API shapes | `design-an-interface` | Several radically different designs from parallel subagents, to compare |
| Noting something in an Obsidian vault | `obsidian-vault` | Vault search, creation, wikilinks |
| Breaking a spec into ordered, independently implementable tasks | `planning-and-task-breakdown` | Small verifiable units with explicit acceptance criteria |
| Starting a new project, feature, or significant change with no spec yet | `spec-driven-development` | A written spec as the shared source of truth before any code |
| Reviewing a change before it lands, on any axis | `code-review-and-quality` | Five-axis review: correctness, readability, architecture, security, performance |
| A bug whose cause is not obvious and parallel investigation would help | `bug-hunt-swarm` | Four read-only investigators in parallel, then ranked hypotheses |

## Multi-agent delivery pipeline

For a substantial piece of work — a new feature, a meaningful change to
existing code, or a bug whose cause is not yet known — prefer the following
three-layer shape over improvising. It is still advisory: skip it for small or
obvious work, and skip any stage the user says to skip.

### Layer 0 — Consumer analysis (before diagnosing anything)

**Every fix starts by answering one question: "what consumes this?"**

A bug is rarely where it appears. Before proposing any fix, name the consumer
chain explicitly:

1. **What is consumed** — the exact artefact: a file, a field, a parameter, a
   return value, a report key. Not "the config" — `spec.slots[].max_chars`.
2. **Who consumes it** — every reader, by `path:line`. Grep for the field name
   and for the function name; do not trust comments or docs (this repo has a
   documented history of line-number drift and comments contradicting code).
3. **What the consumer assumes** — the implicit contract. Is the value always
   present? Is it static or does it change upstream? Is `None` meaningful?
4. **Which consumer is actually broken** — usually only one, and often it is
   not the one that reported the symptom.

**Fix at the point of consumption, and prefer the authoritative source.**
If the data being validated literally exists on the object under test, read it
there — do not accept a copy passed in by the caller, because a hand-off
parameter can be omitted and the omission silently changes the result.

#### The failure modes this stage exists to catch

These are real, already-observed defects — not hypotheticals:

| Failure mode | Symptom | Root cause |
| --- | --- | --- |
| **Optional parameter decides correctness** | Works in production, fails in a standalone test (or vice versa) | A `param=None` whose omission flips behaviour; caller forgot to pass it |
| **Mixed baseline** | Same check passes for some items, fails for others, with no obvious pattern | Some items judged against a stale snapshot, others against live values |
| **Flattened multi-dimensional signal** | A warning blocks deployment, or a real fault is silently skipped | Two orthogonal facts (severity, existence) collapsed into one scalar (`len()`, a bare `None`) |
| **Callers disagree about one contract** | Same class of bug is re-fixed every round, in a new caller each time | One contract consumed N different ways because the mapping lives in each caller |

**Rule:** when a fix keeps recurring in new call sites, the defect is in the
contract, not in the callers. Fix the contract so the mapping cannot be
re-derived inconsistently.

#### Evidence required before moving to Layer 1

- The consumer list, as `path:line`, with the grep that produced it.
- The authoritative source for each consumed value, and why it is authoritative.
- A reproduction that fails *before* the fix and passes *after* — with the
  command and its real output pasted.
- For anything being **tightened**: a counter-test proving the fix does not
  over-report. Every "no longer reported" item must be individually justified
  as a false positive, or the fix has merely traded a false positive for a
  false negative.

### Layer 1 — Architect (before any code is written)

When the request is "build this" or "change this" and the design is not already
settled, delegate a **planning pass to an architect subagent** before writing
code. Brief that subagent to:

1. Load `spec-driven-development` and write the spec first — objectives, scope,
   explicit non-goals, and how completion will be judged.
2. Load `planning-and-task-breakdown` and decompose the spec into ordered tasks
   with acceptance criteria, doing an **anchor analysis**: identify the real
   seams, entry points, and files that each task must touch, and record them as
   concrete `path:line` anchors rather than vague area names.
3. Return the task list with dependencies and anchors — not prose about intent.

The architect does not implement. If the design is genuinely unclear, settle it
with the user first (`grill-me` is good for this) rather than inventing one.

**When Layer 1 is mandatory:** run it whenever the change touches a contract (a
signature, a return shape, a report key, a shared state machine), spans more
than one file, exceeds roughly 100 lines, is the second fix of the same class
this session, or **tightens** a check by removing reports. Skipping the
architect on a contract change is how a fix ships that passes its own tests and
still breaks a caller.

### Layer 2 — Execute

Implement using the Layer 1 task list. Load the relevant skill for the task
shape: `tdd` when correctness matters and the change is not trivial. Work the
tasks in dependency order.

**Isolate the environment before any end-to-end run.** A verification run is
only evidence if the environment is controlled. Before a real pipeline run, and
every time one fails: kill stale workers from earlier attempts (two runs racing
on the same output directory produce failures that look like real defects and
are not), use a fresh output directory per run, capture the unmodified baseline
first so a pre-existing failure is distinguishable from a regression, and
identify non-deterministic failures (model-backed steps) rather than attributing
them to the change. Report which failures were real and which were
environmental — an environmentally-failed run is not evidence in either
direction.

**Verification is not optional.** After each small feature or tool is
implemented, verify it before moving on:

- Load `diagnose` (the Matt Pocock diagnosis discipline) to check the change
  actually does what the spec said — reproduce the intended behaviour and
  confirm it, rather than assuming success from a clean exit code.
- Load `code-review-and-quality` for the five-axis review on non-trivial changes.

**Never claim a stage passed without evidence.** Report what was actually run
and what it printed. If a check was not run, say so plainly. Inventing a
verification result, a file path, an API, or a test outcome is the worst
failure mode in this pipeline — when uncertain, investigate or say "unknown".

### Layer 2.5 — Convergence check (before the audit)

A fix that works but makes the codebase worse is not done. Before the audit,
answer four questions for every change in the round:

1. **Is the same class of bug recurring?** If this is the second or later fix
   this session landing in a *new call site* for one underlying contract, the
   defect is the contract — fix it at the single entry point.
2. **Did the file grow materially?** Record before/after size. Steady growth
   across rounds means patches are accumulating without integration; say so.
3. **Are the new comments design or history?** Comments should state **why the
   current design is this way**. "Changed in round N" is process noise that
   makes the next reader reconstruct which of N layers still applies.
4. **What is the exit condition?** State what would let this area be called
   *done*. If nothing would, the work is unbounded — name that as a risk.

Report a short **Convergence Note**. A failed convergence check is a finding,
not a footnote: fix it or state why it is deferred.

### Layer 3 — Audit (at the end of the work)

Once the implementation is complete, before declaring it done, run an
**independent audit with multiple subagents**. Load `bug-hunt-swarm` and follow
it: launch parallel **read-only** investigators, each given the same bug/change
packet, and have the main agent synthesise ranked hypotheses.

Rules the audit inherits from the skill, and that matter here:

- Investigators are strictly read-only — no edits, no patches, no commits.
- Every finding carries evidence; speculation is discarded at synthesis.
- Prefer two evidence-backed findings over six guesses.

Then report to the user: what was built, what was verified and how, what the
audit found, and what remains unproven.

### Delegation limits on this machine

Subagents cannot delegate further (`maxDepth` defaults to 1), and at most 8
continuable children may be alive at once. Layer 1 and Layer 3 subagents are
therefore leaves — brief them completely and do not expect recursion. For the
audit, four investigators is the shape `bug-hunt-swarm` prescribes and fits
within the cap.

### Before first use of the repo-workflow skills

`to-issues`, `to-prd`, `triage`, `diagnose`, `tdd`,
`improve-codebase-architecture`, and `zoom-out` assume the repository has
declared where its issues live, what its triage labels are called, and where
its domain docs sit. If that context is missing, run
`setup-matt-pocock-skills` first — it is user-invocable only, so ask the user
to invoke it rather than calling it unprompted.

## GraphFlow — shared memory and context

GraphFlow is installed as a DSH plugin (desktop profile) and exposes its tools
as `mcp__graphflow__*`. It is a **memory and context harness, not an
orchestrating executor** — task execution still belongs to the host agent.

### Reading before writing

Before a broad code read, a refactor, or any question about how a subsystem
works, call `graphflow_context` with `rootDir` set to the **project's absolute
path** and a specific query. It returns compressed anchors and summaries —
pointers, not full bodies — which is the whole point: it is cheaper than
reading files. Expand a specific `anchorId` when the actual source is needed.

Never pass a home directory, `AppData`, or an unexpanded placeholder as
`rootDir`; GraphFlow refuses unsafe roots. If a call answers
`unsafe workspace root`, retry the same call without `rootDir`.

Use `graphflow_plan` before broad changes, and `graphflow_index` after
substantial edits so the graph stays current.

### Writing memory back — subagents must close the loop

This is the rule that makes the graph accumulate experience instead of being
re-read from scratch every session:

- When work is executed from a `graphflow_run` execution descriptor, the run
  **must** be closed with `graphflow_report_outcome`, passing the `episodeId`
  from the run result, a `success` boolean, and `lessons` where any were
  learned. An unclosed episode leaves the learning flywheel empty.
- Subagents that complete a meaningful unit of work should record what they
  learned this way before returning, so the next session — and every sibling
  agent — inherits it rather than rediscovering it.
- Report outcomes honestly. A `success: true` with fabricated lessons poisons
  the skill flywheel for every later session. When the work did not succeed,
  say so and record why.

### What GraphFlow does not do

It does **not** watch a subagent's context window and compress at a threshold.
DSH manages context per session with its own compaction
(`compaction-basic`, `/compact`, tool-result pruning), and a parent agent
cannot observe or throttle a child's context. GraphFlow's contribution is to
make each read smaller in the first place, and to persist what was learned.

### Judgement

These skills assume a real software repository with history, issues, and
documentation. For a quick question, a one-line edit, or a scratch script,
loading one is overhead with no payoff — just do the work.

Prefer the skill's procedure when the task is genuinely that shape. Do not
announce the routing; just follow it.
