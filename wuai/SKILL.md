---
name: wuai
description: Full multi-agent delivery workflow. Use when the user types /wuai or asks to build, analyze, or change a codebase with the complete architect → execute → audit pipeline. Also use when the user asks for maximum parallelism, thorough analysis, or a guarantee that boundaries are clear and no bugs ship.
user-invocable: true
---

# WUAI — the full delivery workflow

One command: `/wuai <what you want built or analyzed>`.

This is the heavy pipeline. It spends agents and tokens freely in exchange for
a clear boundary analysis, verified implementation, and an independent audit.
It replaces improvising.

Do not ask whether to run it. The user typed `/wuai` — start.

The six phases, in order:

```
Phase 0    Reconnaissance      project root, graph, project rules, boundary
Phase 0.5  Consumer analysis   what consumes this, who reads it, which reader is broken
Phase 1    Architect           spec + anchor analysis (no code) — mandatory on contract changes
Phase 2    Execute             parallel writers, one per file, controlled environment
Phase 2.5  Convergence check   is the same bug recurring? did the file grow? what ends this?
Phase 3    Audit               independent read-only investigators, synthesised
Report     Boundary → built → verified → findings → unproven
```

Phase 0.5 is not optional for a bug fix. A fix aimed at the wrong consumer
costs a whole round; naming the consumer chain first is what makes the fix
land in one pass.

---

## Phase 0 — Reconnaissance (before anything else is delegated)

Establish ground truth. Nothing downstream is trustworthy if this is wrong.

1. **Resolve the project root.** Ask the user if it is ambiguous. Never guess.
   Never use a home directory, `AppData`, or an unexpanded placeholder.
2. **Check for an existing graph.** Call `graphflow_context` with
   `rootDir = <project root>`. If the graph is empty or stale, call
   `graphflow_index` first so every downstream agent inherits anchors instead
   of re-reading files.
3. **Read the project's own rules.** `AGENTS.md`, `CLAUDE.md`, `CONTEXT.md`,
   `docs/adr/`, README. These outrank this workflow wherever they disagree.
4. **Record the boundary statement.** In your own words, state:
   - what the project is,
   - what is in scope for this request,
   - what is explicitly **out** of scope,
   - which directories are the blast radius.

Write it down. The user reviews it. Every subagent receives it verbatim.

**Gate:** do not proceed until the boundary statement is written and the
project root is confirmed.

---

## Phase 0.5 — Consumer analysis (before diagnosing any bug)

**Every fix starts by answering one question: "what consumes this?"**

A bug is rarely where it appears. Before proposing any fix, name the consumer
chain explicitly.

1. **What is consumed** — the exact artefact: a field, a parameter, a return
   value, a report key. Not "the config" — `spec.slots[].max_chars`.
2. **Who consumes it** — every reader, by `path:line`. Grep the field name and
   the function name. Do **not** trust comments or docs: verify line numbers on
   the spot, because this project has a documented history of drift (an
   architecture doc claimed `run()` at :1076 when it was at :2064) and of
   comments that contradict the code beside them.
3. **What each consumer assumes** — the implicit contract. Is the value always
   present? Static or upstream-mutable? Is `None` meaningful?
4. **Which consumer is actually broken** — usually one, and often not the one
   that reported the symptom.

**Fix at the point of consumption, and prefer the authoritative source.** If
the value under validation literally exists on the object being validated, read
it there. Do not accept a copy handed in by the caller — a hand-off parameter
can be omitted, and the omission silently changes the result.

### The four failure modes this phase exists to catch

Each is a real defect observed in this project, not a hypothetical:

| Failure mode | Symptom | Root cause |
| --- | --- | --- |
| **Optional parameter decides correctness** | Production passes, a standalone repro fails — or the reverse | A `param=None` whose omission flips behaviour; the caller forgot to pass it |
| **Mixed baseline** | The same check passes for some items, fails for others, with no visible pattern | Some items judged against a stale snapshot, others against live values |
| **Flattened multi-dimensional signal** | A warning blocks a deploy, or a real fault is silently skipped | Two orthogonal facts (severity, existence) collapsed into one scalar (`len()`, a bare `None`) |
| **Callers disagree about one contract** | The same class of bug gets re-fixed every round, in a different caller each time | One contract consumed N ways because the state→verdict mapping lives in each caller |

**Rule:** when a fix keeps recurring in new call sites, the defect is in the
**contract**, not in the callers. Fix the contract so the mapping cannot be
re-derived inconsistently — one entry point, consumed by all callers.

### Evidence required before Phase 1

- The consumer list as `path:line`, plus the grep that produced it.
- The authoritative source for each consumed value, and why it is authoritative.
- A reproduction that fails **before** the fix and passes **after** — command
  and real output pasted, not summarised.
- For anything being **tightened**: a counter-test proving it does not
  over-report. Every "no longer reported" item must be individually justified
  as a false positive, or the fix has merely traded a false positive for a
  false negative.

Report this as a short **Consumer Map** in the boundary document, so every
subagent inherits it verbatim.

---

## Phase 1 — Architect (spec and anchor analysis)

Delegate to **one architect subagent**. Brief it completely — it cannot
delegate further (`maxDepth` is 1).

The architect must:

1. Load `spec-driven-development`. Write the spec **before** any plan:
   objective, scope, explicit non-goals, success criteria, boundaries
   (always / ask-first / never).
2. Load `planning-and-task-breakdown`. Decompose into ordered tasks.
3. Do **anchor analysis**: for each task, name the concrete files, entry
   points, and `path:line` anchors it touches. Vague area names are rejected.
4. Identify **dependencies between tasks** and what can run in parallel.
5. Return: the spec, the task list with anchors and dependencies, and the
   risks. Not prose about intent.

The architect **does not write code**.

If the design is genuinely unclear, stop and resolve it with the user
(`grill-me` is the right tool) rather than inventing a design.

### When Phase 1 is mandatory

Phase 1 is skippable only for a genuinely small fix. **Run it** when any of
these is true:

- The change touches a **contract** (a signature, a return shape, a report
  key, a shared state machine).
- The change spans **more than one file**.
- The diff is expected to exceed roughly **100 lines**.
- The same class of bug has already been fixed **twice** in this session.
- You are **tightening** a check (removing reports) — over-tightening is a
  silent regression, and needs a design review to bound it.

Skipping Phase 1 on a contract change is how a fix ships that passes its own
tests and still breaks a caller. If in doubt, run it: one architect is far
cheaper than the round it saves.

---

## Phase 2 — Execute (fan out aggressively)

Implement the task list. **Parallelize whenever tasks are genuinely
independent** — this is where the user wants the agent budget spent.

Rules that make fan-out safe:

- **One writer per file.** Never let two agents edit the same file. Partition
  by file or directory, and record each partition before dispatching.
- **Independent tasks run together.** Dependent tasks run in dependency order.
- **Every implementation agent is briefed with:** the boundary statement, its
  own task and acceptance criteria, the files it owns exclusively, and the
  explicit instruction not to touch files outside its partition.
- Load `tdd` when correctness matters and the change is not trivial.
- Load `incremental-implementation` when landing a change in thin slices.

### Isolate the environment before any end-to-end run

A verification run is only evidence if the environment is controlled.
Before running a real pipeline, and **every time a run fails**:

1. **Kill stale workers.** Check for orphaned processes from an earlier attempt
   before starting a new one. Two writers racing on the same output directory
   produce a failure that looks like a real defect and is not — this project
   hit it repeatedly.
2. **Use a fresh output directory** per run. Never let two runs share one.
3. **Record the known baseline.** Before the change under test, capture what
   the unmodified pipeline does, so a pre-existing failure can be distinguished
   from a regression you introduced.
4. **Distinguish non-deterministic failures.** A model-backed step (copy
   generation, content moderation) can fail for reasons unrelated to the fix.
   Identify those explicitly instead of attributing them to the change.

Report which failures were real and which were environmental. A run that
failed for environmental reasons is **not** evidence, in either direction.

### Verification after every unit of work — non-negotiable

After each feature or tool is implemented, **before moving on**:

1. Run the actual check. Tests, build, the real command.
2. Report **what was run and what it printed**.
3. Load `diagnose` when a result is surprising.

**Never write "verified" without pasted evidence.** If a check was not run,
write "not run". A fabricated pass is the single worst failure in this
workflow — it is worse than a visible failure, because it hides.

### Known limits to respect

- Subagents cannot delegate further (`maxDepth` = 1) — brief them completely.
- At most **8** continuable children alive at once. Queue work rather than
  exceeding it.
- On Windows, pnpm cannot replace files a running process holds open. A
  "file locked" failure is real, not flaky — restart rather than retry.

---

## Phase 2.5 — Convergence check (before the audit)

A fix that works but makes the codebase worse is not done. Before handing off
to the audit, answer these four questions for **every** change in this round.

1. **Is the same class of bug recurring?** If this is the **second or later**
   time this session that a fix landed in a *new call site* for the same
   underlying contract, stop. The defect is the contract. Fix it once, at the
   single entry point, so no caller can re-derive it differently.
2. **Did the file grow materially?** Record the before/after size. A file that
   has grown substantially across rounds is a signal that patches are
   accumulating without integration — say so plainly rather than reporting only
   the passing test.
3. **Are the new comments design or history?** Comments should explain **why
   the current design is this way**. "This was changed in round N" is process
   noise that forces the next reader to reconstruct which of N layers still
   applies. Consolidate history into one statement of current intent.
4. **What is the exit condition?** State what would let this area be declared
   *done* — the point at which further rounds stop being needed. If there is no
   such condition, the work is unbounded; name that as a risk.

Report a short **Convergence Note** alongside the results. If convergence
checks fail, that is a finding, not a footnote: fix it, or state explicitly why
it is deferred.

---

## Phase 3 — Audit (independent, at the end, always)

When implementation is complete and before declaring anything done:

1. **Check the graph is current** — `graphflow_index` if code changed since
   Phase 0.
2. Load **`bug-hunt-swarm`**. Launch **four read-only investigators in
   parallel**, each given the identical packet:
   - reproduction and scope,
   - code path and failure seam,
   - recent changes and regressions,
   - proof plan and observability.

   Every investigator is **strictly read-only** — no edits, no patches, no
   commits. State this in each brief.
3. Load `code-review-and-quality` for a five-axis review of the diff.
4. Synthesise yourself. Discard speculation. Keep only hypotheses with
   evidence, each carrying: hypothesis, supporting evidence, missing evidence,
   smallest proof step, confidence.
5. **Close the loop:** if any work came from a `graphflow_run`, call
   `graphflow_report_outcome` with the `episodeId`, an honest `success`, and
   the real `lessons`. Report failures as failures.

---

## Final report — what the user receives

Deliver exactly this, in this order:

1. **Boundary** — what was in scope, what was deliberately excluded.
2. **What was built** — with `path:line` references to the real artefacts.
3. **Verification** — each check, the command, and its actual output.
4. **Audit findings** — ranked, with evidence and confidence.
5. **Unproven** — what could not be verified, stated plainly.

Never claim completeness that was not proven. "Unknown" is a valid answer;
a confident guess is not.

---

## Why the pipeline looks like this

The three layers exist because they fail differently, and the whole point is
to catch each failure where it happens:

- **Architect first** — most expensive bug in software is building the wrong
  thing well. A spec and anchor analysis catch it before a line is written.
- **Verify each unit** — a bug found one step after it is introduced costs
  minutes. The same bug found at the end costs the whole task.
- **Independent audit** — an agent reviewing its own work shares its own blind
  spots. The audit is only worth running if it is genuinely independent and
  genuinely read-only.

Spend freely on agents and tokens here. The thing that is not negotiable is
that claims carry evidence.
