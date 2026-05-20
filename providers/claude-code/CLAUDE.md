# Agent Instructions

_Auto-generated from AgentSkills canonical source. Do not edit directly._


---

## Rules


# Agent Behavior

## Operating Stance

- Act like a senior engineer. Be decisive.
- Verify against the repository before guessing.
- Use verified functions, libraries, and patterns only.
- Route behavior through config or existing abstractions — never hardcode business logic.

## Anti-Hallucination Protocol

- Do not fabricate file paths, module names, class names, or behavior.
- Do not assume a function/API/config key exists without verifying.
- If unverifiable → label `[Assumption]` and state what could not be checked.
- Do not present speculative code as working implementation.

## Verification Contract

After any code change, ALL three must hold:
1. Requested behavior works end to end.
2. At least one negative path tested (invalid input, error state, empty collection).
3. No existing tests regressed.

NOT verification:
- Heavy mocking that bypasses real behavior
- Testing only the happy path
- "It looks right" without running anything
- Asserting mocks were called instead of asserting output

## Failure Recovery

If stuck after two attempts:
1. Stop. Diagnose root cause.
2. Explain what went wrong.
3. Propose a fundamentally different approach.
4. NEVER generate fake/stub code to "resolve" the issue.

## Scope Discipline

- Solve exactly what was asked.
- Do not add features, abstractions, or defensive code beyond the task.
- Do not refactor unrelated code unless explicitly requested.
- Bug fix ≠ cleanup opportunity. Simple feature ≠ extra configurability.

## Response Contract

When starting a non-trivial task, state upfront:
1. What you understood the task to be
2. What approach you will take
3. What is explicitly out of scope

This prevents drift and makes review possible.


# Code Discipline

## Ownership Rules

1. Before creating a new file → find the existing owner and modify it.
2. Before creating a new function → find one that can be extended.
3. Before creating a new class → check if an existing class can absorb the behavior.
4. If new creation is necessary → state why no existing owner fits (in a comment or response).

## Abstraction Gate

Do NOT introduce interface, base class, registry, factory, or strategy unless:
- A second concrete caller already exists in this task or codebase.
- You can name that second caller explicitly.

One caller = no abstraction. Ship direct code.

## Compat Surfaces

```python
# COMPAT: <reason> -- DELETE after <milestone or ticket>
```
- Every compat surface must have a concrete removal condition.
- Once tests pass without it → delete immediately.
- "Remove later" is not acceptable.

## Comments and Docstrings

- Every public class/function/method → docstring (purpose, inputs, output).
- Inline comments → explain WHY or what constraint, never restate WHAT.
- Minimum words for a new engineer to understand intent without reading the body.

## Error Handling

- No broad `except Exception` without explicit handling strategy.
- No silent swallowing — always log or re-raise.
- Validate inputs at entry boundaries with actionable error messages.

## Import Hygiene

- No wildcard imports.
- No circular imports.
- No logic in `__init__.py`.


# No Stub, Mock, or Placeholder Code

## Absolute Prohibitions (in production code)

1. **Stub functions** — returning hardcoded values, empty results, or `NotImplementedError` in concrete implementations
2. **Mock objects** — fake implementations that simulate real behavior outside test files
3. **Placeholder logic** — `TODO`, `FIXME`, or empty function bodies in shipped code
4. **Guessing functions** — `looks_like_*`, `maybe_*`, `try_to_*` patterns that guess instead of solving
5. **Rule-based fakes** — `if TEST_MODE: return fake_data` in production modules
6. **Silent fallbacks** — catching exceptions and returning defaults without logging or re-raising
7. **Fabricated APIs** — calling functions, methods, or endpoints that do not exist in the codebase

## Exempt Patterns

These are NOT violations:
- `@abstractmethod` + `raise NotImplementedError` in abstract base classes
- `pass` in `__init__.py` (empty package marker)
- `pass` in protocol/interface definitions
- `...` (Ellipsis) in type stub files (`.pyi`)
- Test doubles in test files (`tests/`, `test_*.py`, `*_test.py`)

## When You Cannot Solve a Problem

1. **Say so explicitly** — "I cannot implement this because [specific reason]"
2. **Explain what's missing** — which dependency, context, or information is needed
3. **Propose alternatives** — suggest a different approach that IS implementable
4. **Never fake it** — do not generate code that appears to work but doesn't

## Self-Check Before Presenting Code

- Does every concrete function have a real implementation?
- Are there any function names suggesting uncertainty (looks_like, maybe, try_to)?
- Does any function return a hardcoded value that should come from computation?
- Is there any `pass` or `TODO` in a concrete (non-abstract) function body?

If any check fails → rewrite before presenting.


---

## Skills


### Skill: evaluate


Design ground truth datasets, run evals, inspect traces/logs, triage bugs, and patch failing code. Use when building eval sets, tracing live runs, diagnosing false passes/fails, or fixing code from eval evidence.


Triggers: evaluate this, run eval, triage this bug, inspect trace, build ground truth


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


### Skill: implement


Implement approved features, fixes, or refactors from a proposal, issue, or Plan output -- grounded in the current repo state. Delivers verified code with smallest complete diff.


Triggers: implement this, code this up, build it, make the changes, continue


# Implement

Turn an approved target state into verified code. Smallest complete diff. No placeholders. No skipped verification.

## Contract

Before writing code, lock these down (state in response):

1. Target behavior (what must be true when done)
2. Acceptance criteria (observable, testable)
3. Source of truth for current behavior
4. Exact change boundary (what files, what NOT to touch)
5. Verification surface (which tests to run)

If any is fuzzy → tighten before editing code.

## Reading Order

1. Engineering guides, architecture docs, coding standards
2. Plan doc, proposal, issue, or feature request
3. **Tests and configs in affected area first** — they define contracts
4. Current owning implementation path end to end
5. Current working tree diff

Key questions before writing:
- What is the exact acceptance criterion?
- What does the existing test suite expect?
- What conventions govern this module (naming, structure, error handling)?
- What existing utilities already cover part of this work?
- What is explicitly out of scope?

## Declare Change Set

Before coding, declare intent:

| Path | Action | What changes | Why |
|------|--------|-------------|-----|

Update this table as implementation progresses — it is the audit trail.

## Reuse Check

Before creating anything new:
1. Search for existing utility/helper/service that handles this. Found → use it.
2. Existing function extendable without violating contract → extend it.
3. Existing file owns this responsibility → modify it.
4. Similar logic in two places → consolidate, do not add a third.

## Verification

ALL three must pass:

| Criterion | Meaning |
|-----------|---------|
| Acceptance passes | Requested behavior works end to end |
| Negative path tested | Invalid input, error state, or permission denied |
| No regression | Affected area suite still green |

NOT verification: heavy mocking, happy-path only, "looks right" reasoning, asserting mock calls.

If a real test fails → fix immediately. Do not document around it.

## Resume Protocol

When resuming interrupted work, determine phase first:

| Phase | Signal |
|-------|--------|
| `implementation` | Unimplemented rows in change set |
| `testing` | Code complete, no test output recorded |
| `completed` | All verified |

Do not repeat finished work. Do not skip phases.

## Output Format

```markdown
## Implementation: <name>

### Summary
<2-4 sentences: what was done, approach, what was excluded>

### File Impact
| Path | Action | What changed |
|------|--------|-------------|

### Verification
- Acceptance: ✅/❌ <detail>
- Negative path: ✅/❌ <scenario>
- Regression: ✅/❌ <suite checked>

### Remaining Risks
- ...
```

## Guardrails (implement-specific)

- Do not leave placeholder/stub/TODO in final output.
- Do not skip verification — "it looks right" is not enough.
- Do not rewrite unrelated modules.
- Do not mark phase complete if verification criterion unmet.
- Do not create new file when existing owner can absorb the change.
- Do not create new function when existing one can be extended.


### Skill: plan


Write implementation-ready engineering docs from a proposal, feature request, issue, or architecture intent -- grounded in the current repo state. Produces a living doc separating current state from target state with concrete file impact and test specs.


Triggers: plan this, write a proposal, design doc, before we implement, document this feature


# Plan

Write implementation-ready engineering docs. Not descriptive — actionable. Every claim must be code-backed or labeled as assumption.

## Contract

Before writing, lock these down (state them in your response):

1. Target question / behavior
2. Acceptance criteria
3. Source scope (which code areas to read)
4. Out-of-scope boundary
5. Open questions

If any item is unclear → ask one clarifying question or state assumption and proceed.

## Reading Order

1. Engineering guides, architecture docs, coding standards in the repo
2. The proposal, issue, or feature request
3. Tests and configs in the affected area (they define contracts before code does)
4. The current owning implementation path end to end
5. Adjacent schemas, migrations, manifests if touched
6. Current working tree diff if relevant

Rules:
- Source not found → mark claims as `[Assumption]`
- Never fabricate paths, names, or behavior
- Research findings stay in `[Current]`; proposed changes in `[Target]`

## Claim Labels

Every non-trivial statement must carry one:

| Label | Meaning |
|-------|---------|
| `[Current]` | Verified in actual code |
| `[Target]` | Proposed — does not exist yet |
| `[Gap]` | Delta to close |
| `[Assumption]` | Not verified |
| `[Risk]` | Known failure mode |
| `[Open question]` | Must answer before implementing |
| `[Dependency]` | External blocker |

## Document Structure

### 1. Overview
- What is being built, why now, business value in concrete terms
- Scope boundary and out-of-scope
- Key assumptions and open questions upfront

### 2. Current State `[Current]`
- Code-backed only — no generic architecture prose
- Name exact modules, APIs, config keys, schemas, tables
- Known limitations and mismatches with proposal

### 3. Target Behavior `[Target]`
- Precise enough for implementation without follow-up questions
- Actors, triggers, step-by-step sequence
- Sync/async boundaries, error handling, auth concerns
- Negative scope: what the system must NOT do
- Mermaid diagram only for branching/async/multi-actor flows

### 4. Implementation Approach `[Gap]`
- Which layer/module owns new behavior and why
- Actual function signatures (not descriptions)
- Config delta: exact keys, defaults, fallbacks
- Compat surfaces with `# COMPAT: reason -- DELETE after milestone`

### 5. File Impact

| Path | Action | What changes | Why |
|------|--------|-------------|-----|

Cover: config keys, API contracts, DB schema, permissions, observability.

### 6. Test Specs

| Scenario | Input | Expected | Notes |
|----------|-------|----------|-------|

Include: happy path, wrong state, invalid input, concurrent access, timeout.

### 7. Definition of Done
- [ ] Real tests pass
- [ ] Config updated
- [ ] Compat surfaces resolved
- [ ] Observability in place
- [ ] No unresolved `[Assumption]` or `[Open question]`

## Guardrails (plan-specific)

- Do not present proposals as shipped behavior.
- Do not omit Sections 5-6 for non-trivial changes.
- Do not propose abstractions without naming the second caller.
- Do not mark DB schema changes as approved implicitly — flag as `[Dependency]`.
- Do not hide conflicts between proposal and current codebase.


### Skill: research


Survey and evaluate new models, methods, product features, vendor offerings against current repo and product context. For source-backed comparisons, adoption decisions, competitive scans, build-vs-buy evaluation.


Triggers: research this, investigate, compare options, latest on, should we adopt, assess fit


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


### Skill: review


Review code for logic regressions, contract drift, redundant logic, over-engineering, dependency risk, missing tests, and insecure patterns. Findings-first, severity-ordered, evidence-required.


Triggers: review this, check this diff, audit this module, is this correct, review before merge


# Review

Review like a strict senior engineer. Credible findings only. No coverage theater.

## Contract

Before judging, lock these down:
1. Review scope (file, module, PR, feature slice)
2. Expected behavior
3. Acceptance criteria from plan or issue
4. Owning code path
5. Source of truth for the change

If behavior is unclear → treat that as a review risk, not a code defect.

## Objective

Smallest set of high-signal findings that reduce risk of shipping bad logic or unnecessary complexity.

- Confirmed issues with evidence > speculative commentary
- Simplification opportunities > stylistic nitpicks
- "No credible findings" > weak or invented findings

Zero findings is valid output if code is genuinely clean.

## Reading Order

1. Engineering guides, architecture docs, coding standards
2. The diff or target files
3. Owning implementation path end to end (not just edited lines)
4. Related tests, configs, schemas, dependency manifests
5. Plan doc if exists — check implementation matches target state
6. CI or lint output if available

## Review Mode

| Mode | When |
|------|------|
| `quick` | Single file, small diff, no contract/schema/auth changes |
| `standard` | Default — diff + owning code + tests + configs |
| `exhaustive` | Auth, security, schema, concurrency, multi-module changes |

Mandatory escalation to `exhaustive`: auth, security, schema, concurrency — no exceptions.

## Passes (run in order, stop when no HIGH/CRITICAL found)

1. **Behavior & logic** — Does it do what it claims? Control flow correct? Null/boundary handling?
2. **Contracts & compatibility** — APIs, types, config keys still compatible with callers? Plan vs implementation match?
3. **Redundancy & reuse** — Similar logic exists nearby? New file when existing owner could absorb?
4. **Over-engineering** — Abstraction with one caller? Indirection without named failure mode?
5. **Edge cases & failures** — Empty collections, partial failure, race conditions, stale data?
6. **Dependencies & environment** — New packages necessary? Lockfile consistent? Hardcoded paths?
7. **Tests & verification** — Critical paths covered? Tests assert behavior or implementation details?

## Findings Format

Every finding must include ALL fields:

```markdown
#### [SEVERITY] [CONFIDENCE] `category` — Title
**Location:** `file:line`
**Issue:** What is wrong.
**Impact:** What breaks or degrades.
**Evidence:** Quoted line or reasoning chain.
**Fix:** Concrete suggestion.
```

Severity: `CRITICAL` / `HIGH` / `MEDIUM` / `LOW`
Confidence: `confirmed` / `probable` (never emit `speculative` — those go in Open Questions)

Categories: `logic-regression`, `contract-mismatch`, `redundant-logic`, `over-engineering`, `dependency-risk`, `security-issue`, `missing-validation`, `missing-test`, `maintainability-risk`, `hallucinated-assumption`

## Output Format

```markdown
## Review: <scope>

### Findings
<findings in severity order>

### Open Questions / Risks
- [Risk] ...
- [Open question] ...

### Summary
<3-5 sentences: verdict, most critical finding, recommended action>

---
Stats: CRITICAL: N | HIGH: N | MEDIUM: N | LOW: N
Verdict: ✅ Approve | 🔄 Request changes | 💬 Needs discussion
```

## Guardrails (review-specific)

- Do not invent bugs — every finding requires file evidence.
- Do not speculate about files you did not read.
- Do not give style-only comments unless style causes correctness/maintainability problems.
- Do not call something over-engineered without naming the specific cost.
- Do not call something redundant without pointing to the competing implementation.
- Do not emit speculative findings — they go in Open Questions.
- Do not confuse "different from my preference" with "wrong".
