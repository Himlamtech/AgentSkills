# Eval Runbook

## Run Order

1. Validate benchmark JSON structure.
2. Upload or refresh dataset only when ground truth changed.
3. Run `--no-run` first for schema and upload check.
4. Run a single benchmark with low concurrency.
5. Inspect per-item fail reason.
6. Patch owning code.
7. Re-run the same benchmark.

## What Good Looks Like

A good eval loop gives these outputs for each item:

- pass or fail
- why it passed or failed
- which stage failed
- which evidence was missing
- which file should be patched
- whether a new log line is needed
- whether the dataset itself was wrong

## What To Inspect

- final answer
- expected answer
- key facts
- retrieved docs or sources
- trace / event sequence
- tool calls
- token usage
- latency
- error reason
- planner or worker step state

If answer is wrong but trace looks clean, inspect scoring first. If answer is wrong and trace is noisy or incomplete, inspect harness or runtime first.

## Decision Tree

### 1. Dataset wrong

- expected answer mismatch
- key facts mismatch
- source doc ids wrong
- item scope too broad or too narrow

Fix benchmark JSON only.

### 2. Harness wrong

- trace missing
- token missing
- latency missing
- `error_reason` empty when run obviously failed
- run output lost tool or memory detail

Fix `evals/runners/langsmith_runner.py` first.

### 3. Runtime wrong

- planner picked wrong route
- worker executed wrong competency
- tool arguments wrong
- memory not used or used stale
- final output normalized away useful data

Fix owning runtime file.

### 4. Visibility wrong

- fail exists but bug is hidden
- no stage signal
- no state diff

Add log at existing callsite only.

## Bug Labels

- `dataset_wrong`
- `scoring_wrong`
- `harness_missing_trace`
- `planner_wrong`
- `worker_wrong`
- `tool_wrong`
- `memory_wrong`
- `output_wrong`
- `provider_error`

## Logging Rule

If the bug is invisible, add minimal logs at the existing callsite:

- trace id
- run id
- item id
- stage
- token usage
- latency
- failure reason
- compact state diff

Do not add broad debug-only layers when existing runtime trace can carry signal.

## Minimal Log Shape

Use plain text or compact dict, not verbose dumps:

```text
[eval] item=FX-001 stage=worker token=124 latency=2334ms error=tool_timeout
```

If needed, add one compact state diff line:

```text
[eval] diff=runtime_key:agent->brainz; tool:semantic_search; refs:0->3
```

## Fix Pattern

1. Reproduce with one item.
2. Check whether failure is dataset, harness, runtime, or visibility.
3. Patch owning file only.
4. Re-run same item.
5. Run small batch.
6. Then run full benchmark.
