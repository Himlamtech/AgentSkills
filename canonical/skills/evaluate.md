---
name: evaluate
description: >
  Design ground truth datasets, run evals, inspect traces/logs, triage bugs, and patch failing code. Use when building eval sets, tracing live runs, diagnosing false passes/fails, or fixing code from eval evidence.
triggers:
  - "evaluate this"
  - "run eval"
  - "triage this bug"
  - "inspect trace"
  - "build ground truth"
---

# Evaluate

Turn eval into a build-test-debug loop: define ground truth → run against real runtime → inspect trace → localize bug → fix owning code → rerun.

## Workflow

1. Read repo contract and eval infrastructure first.
2. Define ground truth and failure classes.
3. Run eval on real runtime (smallest useful command first).
4. Inspect: trace, token, latency, tool calls, memory, error stage.
5. Add logs only when trace is too thin to diagnose.
6. Fix the smallest owning file.
7. Re-run same eval and confirm regression locked.

## Ground Truth Design

Mixed coverage, not flat random questions:

| Category | Share | Purpose |
|----------|-------|---------|
| Direct fact/action | 30% | Baseline correctness |
| Multi-hop | 20% | Reasoning chains |
| Trap/confusion | 15% | Similar competency disambiguation |
| Ambiguous/underspecified | 15% | Clarification behavior |
| Follow-up/memory | 10% | Context carry-over |
| Negative/no-answer | 10% | Graceful failure |

Sizing: 20-30 items per feature, 50-80 for release gate, 10-15 for smoke check.

Adjust by feature type:
- Tool-heavy → raise tool/trajectory coverage
- RAG-heavy → raise groundedness/source coverage
- Planner-heavy → raise hop count and dependency order

See [references/groundtruth.md](references/groundtruth.md) for schema and sizing rules.

## Bug Triage

Classify failure stage FIRST, then fix:

| Priority | Stage | Fix target |
|----------|-------|-----------|
| 1 | Ground truth wrong | Benchmark JSON |
| 2 | Scoring too weak/strict | Rubric or judge config |
| 3 | Harness missing trace | Eval runner |
| 4 | Planner wrong route/order | Planner node |
| 5 | Worker wrong competency/input | Worker node |
| 6 | Tool wrong data/evidence | Competency owner |
| 7 | Memory missing/stale | Memory layer |
| 8 | Output normalization trimmed content | Output node |

If trace is too thin to diagnose → add minimal log at existing callsite (trace_id, item_id, stage, error_reason). Do not add broad debug layers.

See [references/eval-runbook.md](references/eval-runbook.md) for command order and checkpoints.

## Fix Rules

- Fix exact failure surface first — not a new abstraction.
- Patch owning file — do not create adapter or compatibility layer.
- Reproduce with one item → fix → re-run item → run batch → run full.
- New file only if existing owner cannot absorb the change.

## Guardrails (evaluate-specific)

- Do not change ground truth to make a broken runtime pass.
- Do not add logs everywhere — only where trace is insufficient.
- Do not create new eval infrastructure when existing entrypoint works.
- Do not skip re-run after fix — confirmation is mandatory.
