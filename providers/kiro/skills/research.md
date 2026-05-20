---
inclusion: manual
description: "Survey and evaluate new models, methods, product features, vendor offerings against current repo and product context. For source-backed comparisons, adoption decisions, competitive scans, build-vs-buy evaluation."
---

# Research

Evidence-backed decisions, not casual browsing.

## Contract

Before research starts, lock these down:

1. Target question (what exactly needs answering)
2. Decision to make (adopt/reject/pilot/watch)
3. Acceptance criteria (what would make you say yes or no)
4. Source scope (official docs, papers, community, benchmarks)
5. Freshness window (how recent must sources be)

## Workflow

1. **Define target** — exact question, use case, success criteria, time window.
2. **Read local context** — project docs, owning code, tests, configs, existing implementation.
3. **Choose source lanes** — one per independent topic/option, non-overlapping.
4. **Gather primary evidence** — official docs, release notes, papers, pricing, changelogs. Record dates and versions.
5. **Compare against repo/product** — architecture fit, integration cost, runtime/security/ops impact.
6. **Decide** — `Adopt`, `Pilot`, `Watch`, or `Reject` with 2-3 concrete reasons.

## Decomposition Strategy

For complex research with multiple options:
- Split into independent lanes (one per option/topic)
- Each lane: gather dated primary-source facts independently
- Cross-compare only after all lanes have evidence
- Challenge weak claims and vendor bias before concluding

## Output

```markdown
## Research: <topic>

### Decision: Adopt / Pilot / Watch / Reject
<2-3 concrete reasons>

### Comparison Matrix
| Criterion | Option A | Option B | Current |
|-----------|----------|----------|---------|

### Fit Assessment
- Architecture fit: ...
- Integration cost: ...
- Runtime/security impact: ...

### Risks & Unknowns
- ...

### Next Step
- ...

### Sources
- [title](url) — date — key finding
```

## Guardrails (research-specific)

- Use current sources; call out stale evidence explicitly.
- Cite every nontrivial claim with source and date.
- Keep fact, inference, and recommendation visually separate.
- Prefer primary sources (docs, changelogs) over summaries (blog posts).
- If evidence is thin → say so and lower confidence.
- Do not let vendor marketing language pass as technical assessment.
- Do not recommend without evaluating fit against current codebase.

## References

- [references/source_policy.md](references/source_policy.md)
- [references/comparison_rubric.md](references/comparison_rubric.md)
- [references/output_contract.md](references/output_contract.md)
