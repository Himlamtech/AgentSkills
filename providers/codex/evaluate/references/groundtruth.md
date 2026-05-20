# Ground Truth

## Target Schema

Use existing benchmark JSON shape first:

```json
{
  "benchmark_name": "feature-x",
  "dataset_name": "feature-x-eval",
  "description": "Short purpose",
  "application_name": "aiz",
  "metadata": {
    "benchmark_type": "feature_eval",
    "version": "v1"
  },
  "items": [
    {
      "input": {
        "question": "User question",
        "context": [],
        "conversation_history": [],
        "mode": "normal"
      },
      "expected_output": {
        "answer": "Canonical answer",
        "key_facts": [],
        "source_doc_ids": [],
        "answer_type": "extraction"
      },
      "metadata": {
        "id": "FX-001",
        "category": "single_hop",
        "difficulty": "easy",
        "required_hops": 1,
        "trap_description": "Why this item is tricky",
        "required_tools": [],
        "expected_trajectory": [],
        "failure_modes": [],
        "scoring_config": {
          "rule_based": [],
          "llm_judge": []
        }
      }
    }
  ]
}
```

## Item Anatomy

Use this order inside each item:

1. `input`
2. `expected_output`
3. `metadata`
4. `scoring_config`

Keep `input.question` short and clean. Put evidence in `context` or `source_chunks`, not inside question text. Put grading intent in metadata, not in the answer text.

## Sizing Rule

- 5 easy items.
- 5 medium or multi-hop items.
- 5 trap or confusion items.
- 5 ambiguous or follow-up items.
- 3-5 negative or no-answer items.
- Add memory/tool/format items if feature uses them.

## Recommended Mix By Feature Type

### Retrieval feature

- direct extract
- source attribution
- multi-hop synthesis
- trap with similar chunk
- no-answer case

### Planner or agent feature

- instant answer
- single-step tool call
- multi-step dependent plan
- parallelizable branch
- wrong-competency trap

### Memory feature

- first-turn answer
- follow-up answer
- stale-memory trap
- context carry-over
- memory should be ignored case

### Tool feature

- correct tool choice
- correct tool args
- tool returns error
- tool returns partial evidence
- tool not needed case

## Metadata To Keep

- `id`
- `category`
- `difficulty`
- `required_hops`
- `trap_description`
- `required_tools`
- `expected_trajectory`
- `failure_modes`
- `scoring_config`

## Example Metadata Meaning

- `required_hops`: how many reasoning or retrieval transitions are required
- `required_tools`: which tools must or may be used
- `expected_trajectory`: rough order of planner or tool behavior
- `failure_modes`: known ways the item can fail
- `trap_description`: why the item is easy to miss or misread

## Example Scoring Notes

Use more than one score only when needed. Keep primary pass gate simple.

- `rule_based`: exact source id, exact number, list coverage, key fact presence
- `llm_judge`: groundedness, completeness, correctness, format

For one item, do not overfit with too many judge prompts. If a rule can check it reliably, use rule first.

## Pass Rule

- Exact answer correctness.
- Key fact coverage.
- Source grounding when available.
- No critical runtime error.
- Format compliance.

## Fail Classification

Label the item failure before changing code:

- `dataset_wrong`: expected answer or key facts are wrong
- `scoring_wrong`: rubric or judge logic is wrong
- `tool_wrong`: competency did not call or returned wrong evidence
- `planner_wrong`: step order, dependency, or route is wrong
- `memory_wrong`: old turn state is stale or ignored
- `output_wrong`: final answer was trimmed or rewritten incorrectly
- `provider_error`: model or provider failed before useful output
