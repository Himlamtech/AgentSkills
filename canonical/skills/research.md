---
name: research
description: >
  Survey and evaluate new models, methods, product features, vendor offerings, and current news against current repo and product context. Use for source-backed comparisons, adoption decisions, competitive scans, build-vs-buy evaluation.
triggers:
  - "research this"
  - "investigate"
  - "compare options"
  - "latest on"
  - "should we adopt"
  - "assess fit"
---

# Research

Use this skill for evidence-backed decisions, not casual browsing.

## Decision Contract

Before research starts, lock these down:

- target question
- decision to make
- acceptance criteria
- source scope
- deadline or freshness window

If any of these are missing, define them first.

## When To Use

- New model, method, API, vendor, or product feature needs evaluation.
- Current approach looks outdated and needs a fresh survey.
- User wants "latest" news or release status with dates and links.
- User wants fit judgment against this repo, product direction, or runtime constraints.

## Workflow

1. Define the decision target.
   - Exact question.
   - Intended use case.
   - Success criteria.
   - Time window.
2. Read local context first.
   - `AGENTS.md`
   - relevant project docs
   - owning code, tests, configs, and feature docs
   - current feature idea or existing implementation, if any
3. Choose source lanes.
   - One lane per independent topic or option.
   - Keep lanes source-heavy and non-overlapping.
4. Gather primary evidence.
   - Prefer official docs, release notes, papers, pricing pages, changelogs, or repo source.
   - Record dates, version numbers, and exact links.
5. Compare against current repo and product needs.
   - Fit with current architecture
   - Integration cost
   - Eval cost
   - Runtime, security, and operational impact
6. Decide.
   - `Adopt`, `Pilot`, `Watch`, or `Reject`
   - explain why in 2-3 reasons
   - separate verified fact, inference, and recommendation
   - state uncertainty directly

## Subagents

Use subagents when the work has independent lanes or many sources.

- `repo_context`: read local docs/code and map current capability, owners, and gaps.
- `source_scout`: gather dated primary-source facts for one option or topic.
- `fit_evaluator`: compare one external option against repo/product constraints.
- `skeptic`: challenge weak claims, stale sources, and vendor bias.

Never let a subagent write the final recommendation alone.

## Output

Return:
- decision: `Adopt`, `Pilot`, `Watch`, or `Reject`
- decision criteria used
- short summary
- comparison matrix
- fit assessment for this repo/product
- risks and unknowns
- next step
- source list with dates

## Acceptance Criteria

A research result is complete only when:

- the decision target is explicit
- sources are dated and cited
- repo fit is evaluated against current code or docs
- recommendation is tied to the stated acceptance criteria
- uncertainty is named, not hidden

## Guardrails

- Use current sources; call out stale evidence.
- Cite every nontrivial claim.
- Keep fact, inference, and recommendation separate.
- Prefer primary sources over summaries.
- If evidence is thin, say so and lower confidence.

## References

- `references/source_policy.md`
- `references/comparison_rubric.md`
- `references/output_contract.md`
- `references/news_model_tracking.md`
