---
name: review
description: >
  Review code for logic regressions, contract drift, redundant logic, over-engineering, dependency risk, missing tests, and insecure patterns. Findings-first, severity-ordered, evidence-required.
triggers:
  - "review this"
  - "check this diff"
  - "audit this module"
  - "is this correct"
  - "review before merge"
---

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
