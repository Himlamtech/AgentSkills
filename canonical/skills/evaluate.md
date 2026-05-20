---
name: evaluate
description: >
  Design ground truth datasets, run evals, inspect traces/logs, triage bugs, and patch failing agent/runtime code. Use when building or updating eval sets, tracing live runs, diagnosing false passes/fails, adding logging, or fixing code from eval evidence.
triggers:
  - "evaluate this"
  - "run eval"
  - "triage this bug"
  - "inspect trace"
  - "build ground truth"
---

# Evaluate

## Overview

Use this skill to turn eval into a build-test-debug loop. Keep one path: define ground truth, run against the real runtime, inspect trace, localize the bug, add missing logs only when needed, then fix owning code and rerun.

## When To Use

Use when the request is about:

- building or revising benchmark JSON for a feature
- deciding how many items and what kinds of items to include
- running `agent_core` eval against live runtime
- reading traces, tokens, latency, or tool calls from eval output
- diagnosing false pass or false fail
- adding logs only because current trace is too thin
- fixing code from eval evidence

## Workflow

1. Read repo contract first.
2. Define ground truth and failure classes.
3. Run eval on the real runtime.
4. Inspect trace, token, latency, tool calls, memory, and error stage.
5. Add logs only when trace is too thin.
6. Fix the smallest owning file.
7. Re-run the same eval and lock regression.

## Ground Truth Design

Use mixed coverage, not flat random questions. One feature should feel like a test matrix, not a trivia list.

- 20-30 items minimum for one feature.
- 50-80 items for high-risk feature or release gate.
- 10-15 items only for smoke check.

Good mix:

1. Easy single-hop facts.
2. Medium multi-hop facts.
3. Hard or trap questions.
4. Questions that confuse similar competencies.
5. Ambiguous or underspecified requests.
6. Follow-up or memory-dependent questions.
7. Negative cases: no answer, wrong source, wrong tool, wrong format.

Recommended split for one feature:

- 30% direct fact or direct action
- 20% medium multi-hop
- 15% trap or confusion with similar competency
- 15% ambiguous or underspecified
- 10% follow-up or memory
- 10% negative or failure cases

If feature is tool-heavy, raise tool and trajectory coverage. If feature is RAG-heavy, raise groundedness and source coverage. If feature is planner-heavy, raise hop count, dependency order, and parallel-ready cases.

Use [references/groundtruth.md](references/groundtruth.md) for schema and sizing rules.

## Run Eval

- Prefer the existing repo eval entrypoint.
- Keep benchmark data in current eval benchmark files before adding a new layout.
- Run the smallest useful command first, then the full run.
- Compare output against expected answer, key facts, source ids, tool path, token, latency, and error reason.

Typical `agent_core` commands:

- `python evals/evals.py semantic --no-upload --no-run`
- `python evals/evals.py semantic --no-llm-judge`
- `python evals/evals.py semantic --concurrency 1`

What to read from result:

- `correct` / `incorrect`
- `review`
- `token_consuming`
- `time_consuming`
- `error_reason`
- `retrieved_doc_ids`
- `intent`
- `route_target`

Use [references/eval-runbook.md](references/eval-runbook.md) for command order and checkpoints.

## Bug Triage

- If the answer is wrong, classify stage first: dataset, scoring, harness, planner, worker, tool, memory, output.
- If the bug does not show, add logs at the existing callsite, not a new noisy wrapper.
- Log trace id, run id, item id, tool call, token, latency, failure stage, and compact state diff.
- Do not add broad debug chatter.
- Prefer patching the owning file over creating an adapter or compatibility layer.

Fast localization order:

1. Ground truth wrong.
2. Scoring too weak or too strict.
3. Harness not carrying trace or evidence.
4. Planner chose wrong route or wrong step order.
5. Worker called wrong competency or wrong input.
6. Tool returned wrong data or too little evidence.
7. Memory missing or stale.
8. Output normalization trimmed useful content.

If trace is missing, add log at the nearest owning layer:

- `evals/runners/langsmith_runner.py` for eval harness visibility
- `agents/agent/nodes/planner.py` for plan decision visibility
- `agents/agent/nodes/worker.py` for step execution visibility
- competency owner file for tool-level visibility
- `agents/agent/nodes/normalize_output.py` for final shaping issues

## Fix Order

1. Fix ground truth if expected answer is wrong.
2. Fix scoring if rubric or judge is wrong.
3. Fix harness if trace, error, latency, or token is missing.
4. Fix runtime if behavior is wrong.
5. Add a new file only if the existing owner file cannot absorb the change.

Do not start with new abstraction. Fix exact failure surface first. If one change can solve it in existing owner file, do that.

## Repo Rule For agent_core

- Use `evals/evals.py` and `evals/runners/langsmith_runner.py` first.
- Keep schema in existing benchmark JSON.
- Reuse runtime traces already emitted by root graph and competency execution.
- Preserve existing file ownership and avoid unrelated refactors.

## Good Ground Truth Item Shapes

- single fact extraction
- list or aggregation
- comparison / substitution reasoning
- multi-hop synthesis
- trap item that is easy to confuse with another competency
- ambiguous item that should force clarification or cautious answer
- no-answer / not-found item
- memory-dependent follow-up
- tool-required item
- planner-required item with 2-5 ordered steps

## References

- [groundtruth.md](references/groundtruth.md)
- [eval-runbook.md](references/eval-runbook.md)
