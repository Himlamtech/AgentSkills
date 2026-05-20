---
inclusion: manual
description: "Review changed code, generated files, existing modules, or feature slices for logic regressions, contract drift, redundant logic, over-engineering, dependency risk, missing tests, and insecure patterns. Use after implementation. Findings-first, severity-ordered, evidence-required."
---

# Review

Review code like a strict senior engineer. Credible findings only. No coverage theater.

## Review Contract

Before judging the diff, lock these down:

- review scope
- expected behavior
- acceptance criteria from plan or issue
- owning code path
- source of truth for the change

If the requested behavior is unclear, treat that as a review risk before calling the code wrong.

## Objective

Produce the smallest set of high-signal findings that materially reduce the risk of shipping bad logic or unnecessary complexity.

Prefer:
- confirmed issues with file evidence over speculative commentary
- simplification opportunities over stylistic nitpicks
- "no credible findings" over weak or invented findings

A review with zero findings is a valid output if the code is genuinely clean.

## Step 1 -- Read before forming conclusions

1. Engineering guides, architecture docs, coding standards -- whatever convention files exist in the repo
2. The diff or target files -- understand what changed and why
3. The **owning implementation path end to end** -- not just the edited lines; understand the surrounding context
4. Related tests, configs, schemas, dependency manifests
5. The Plan doc if it exists -- check that implementation matches the stated target state
6. CI or lint output if available

Do not review a diff in isolation when the request is about architecture, redundancy, or over-engineering. Inspect adjacent code before drawing conclusions about whether something is duplicated or unnecessary.

## Step 2 -- Select review mode

| Mode | Use when |
|------|---------|
| `quick` | Single file or small diff; no contract, schema, or auth changes |
| `standard` | Default -- diff + owning code + tests + configs |
| `exhaustive` | Auth or security involved; schema or API contract changed; new abstraction layer added; concurrency or persistence logic changed; multi-module or cross-service change |

Mandatory escalation to `exhaustive`: auth, security, schema changes, concurrency -- no exceptions.

## Step 3 -- Run layered passes in order

Run each pass. Stop adding findings when a pass produces zero HIGH or CRITICAL results after inspecting at least 3 distinct areas. Do not run all passes on a trivial single-function change -- use judgment.

### Pass 1: Behavior and logic
- Does the implementation actually satisfy the intended behavior?
- Are control flow, conditionals, and state transitions correct?
- Are fallback and error paths reachable and exercised correctly?
- Off-by-one, null handling, boundary conditions covered?

**Signals to look for:** logic that silently succeeds on invalid input; unreachable branches; conditions that are always true or always false; mutable state shared across async calls without a lock; a function that returns success even when the underlying operation failed.

### Pass 2: Contracts and compatibility
- Are APIs, type shapes, config keys, schema fields, and return values still compatible with all callers?
- Did the change silently rename, reorder, or change the default value of a parameter or config key?
- Does the implementation match what the Plan doc promised?

**Signals:** function signature changed but callers not updated; config key renamed without migration; return type narrowed without updating downstream consumers; Plan says behavior X but code implements behavior Y; error code changed from 400 to 422 without updating API consumers.

### Pass 3: Redundancy and reuse
- Does similar logic already exist nearby and was not reused?
- Was a new helper, adapter, mapper, or utility added when an existing path already handles this?
- Was a new file created when an existing file owned the responsibility?
- Was a new function written when an existing function could have been extended?
- Are constants or config values duplicated instead of referencing a single source of truth?

**Signals:** two functions with identical or near-identical logic; a new `utils.py` created next to an existing `helpers.py`; hardcoded values that exist in config but are re-declared inline; a new file created alongside a deprecated old file that does the same job.

**Rule:** do not call something redundant unless you can point to the competing implementation by file and line.

### Pass 4: Over-engineering and abstraction cost
- Does a new abstraction have only one caller with no named second use case in the codebase?
- Was an interface, base class, registry, strategy, or factory introduced without a second concrete caller identified?
- Was async, caching, retry, or polymorphism added without a named, observable failure mode it solves?
- Did the change add indirection that makes a previously simple flow harder to follow?
- Are there mocks, stubs, or rule-based fakes in production code outside of test files?
- Are there comments that restate what the code does rather than explaining why it does it?

**Rule:** do not call something over-engineered unless you can name the specific added cost -- more files, more state, more call hops, harder testing, harder debugging, weaker readability. One concrete cost required per finding.

### Pass 5: Edge cases and failure paths
- Empty collections, None/null inputs, zero values, max boundary values handled correctly?
- Invalid or malformed input -- is it caught at the boundary and rejected explicitly, or does it propagate silently?
- Partial failure in multi-step operations -- is state left consistent if one step fails mid-sequence?
- Retries -- are they bounded? Do they use backoff? Do they risk duplicate side effects?
- Race conditions -- is shared mutable state accessed across async calls without a lock?
- Stale data -- is a cached or snapshotted value used where fresh data is required for correctness?

### Pass 6: Dependency and environment
- New packages added -- are they necessary, actively maintained, license-compatible?
- Lockfile drift -- does the lockfile reflect the manifest consistently?
- Runtime environment assumptions -- hardcoded paths, env vars that may not exist in all environments, OS-specific behavior?
- Version pinning -- is a transitive dependency pulling in a version that conflicts with another dependency?

**Rule:** do not claim version incompatibility without pointing to the manifest, import, or API surface that shows the conflict.

### Pass 7: Tests and verification
- Are critical and non-obvious paths covered by tests?
- Are tests asserting observable behavior or internal implementation details?
- Would the tests still pass if the implementation were refactored without changing behavior? If yes, the tests are asserting implementation details -- flag it.
- Are edge cases from Pass 5 represented in the test suite?
- For AI-facing or E2E paths: are there real tests that exercise the actual runtime, not just unit tests with heavy mocking?

**Signals:** a test that mocks every dependency and only asserts that mocks were called; 100% line coverage but zero assertions on return values; no test for the primary error path of a function handling auth, payments, or data mutation; tests that break when a private method is renamed.

## Step 4 -- Compat surface audit

Required whenever the task involves refactoring, migration, legacy removal, or simplification.

For each compat surface found (shim, alias, re-export module, fallback branch, deprecated config key):

1. Identify exactly what it is and where it lives
2. Find the canonical owner of that behavior today
3. Search for every caller -- imports, usages, external call sites -- and verify whether any real caller still depends on the legacy surface
4. If no real caller exists -> flag as `redundant-logic`
5. Recommend the narrowest safe deletion: the specific code, tests, docs, and config entries to remove

**Mandatory flags in this pass:**
- `# COMPAT:` comment with no concrete removal milestone -> `maintainability-risk`
- Compat surface added in this PR where tests already pass -> `redundant-logic`, fix: delete it now
- Compat surface surviving from a prior migration that is now complete -> `redundant-logic`
- Compat surface with no comment explaining why it exists -> `maintainability-risk`

**Default rule:** do not preserve a compat surface by reflex. Require concrete evidence that a real caller still depends on it. Evidence means you searched and found an actual import or call site -- not "it might be used somewhere."

## Step 5 -- Findings contract

Every finding must include all fields. Incomplete findings are not findings -- they are noise.

| Field | Requirement |
|-------|-------------|
| **Severity** | `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` |
| **Confidence** | `confirmed` / `probable` / `speculative` |
| **Category** | One of the allowed categories below |
| **Location** | `file:line` -- always specific, never just a filename |
| **Issue** | What is wrong, stated precisely and concisely |
| **Why it matters** | Concrete impact -- what breaks, degrades, or becomes harder |
| **Evidence** | File reference, quoted line, or explicit reasoning chain |
| **Fix direction** | Concrete suggestion -- code snippet when the fix is non-obvious |

**Allowed categories:**

| Category | When to use |
|----------|------------|
| `logic-regression` | Code does not do what it claims, or breaks prior behavior |
| `contract-mismatch` | API, type, config, schema, or return value incompatible with callers; or Plan vs implementation divergence |
| `redundant-logic` | Duplicate implementation -- competing path exists and is verifiable by file |
| `over-engineering` | Unjustified abstraction with named, concrete cost |
| `dependency-risk` | Package, version, lockfile, or environment assumption issue |
| `security-issue` | Auth bypass, injection risk, secret exposure, improper permission check |
| `missing-validation` | Input not validated where contract or prior behavior requires it |
| `missing-test` | Critical path with no test coverage -- name the specific untested scenario |
| `maintainability-risk` | Code that will predictably cause confusion, drift, or bugs -- explain the mechanism |
| `hallucinated-assumption` | Code assumes a file, API, behavior, or contract that does not exist in the repo |

**Confidence rules -- these matter:**
- `confirmed` -- you read the code and can specify the exact input that triggers the issue
- `probable` -- strong evidence but one missing piece (e.g., cannot see an external caller)
- `speculative` -- pattern suggests risk but you cannot confirm without running the code -> **always downgrade to Open question or Risk; never emit as a finding**

**`hallucinated-assumption` detection procedure:** search explicitly for the assumed entity in the repo. If you cannot find it, the evidence must state: "Searched for X in [specific locations], found nothing. Code at [file:line] assumes X exists." Do not emit this category without completing the search.

## Output format

```markdown
## Review: <scope -- file name, feature name, or PR title>

### Findings

#### [SEVERITY] [CONFIDENCE] `category` -- Short descriptive title
**Location:** `file:line`
**Issue:** What is wrong, stated precisely.
**Why it matters:** Concrete impact if not fixed.
**Evidence:** Quoted line or explicit reference.
**Fix:** Concrete suggestion or code snippet.

---

### Open questions / Risks
- **[Risk]** Description -- what could go wrong, what evidence would confirm or rule it out
- **[Open question]** What must be answered before this is safe to merge

### Summary
<3-5 sentences: overall verdict, the single most critical finding, and the recommended action before merge>

### Verification gaps
- What was not checked and why (missing access, no test output, external service not inspectable)

---
Stats: CRITICAL: N | HIGH: N | MEDIUM: N | LOW: N
Verdict: ✅ Approve | 🔄 Request changes | 💬 Needs discussion
```

If no credible findings:
```text
No credible findings.
Residual risks: [list any speculative concerns that did not meet the evidence bar]
Verification gaps: [list what could not be checked]
Verdict: ✅ Approve
```

## Guardrails

- Do not invent bugs. Every finding requires file evidence or an explicit reasoning chain.
- Do not speculate about files you did not read.
- Do not give style-only comments unless style directly causes a correctness or maintainability problem.
- Do not call something over-engineered without naming the specific cost it introduces.
- Do not call something redundant without pointing to the competing implementation by file and line.
- Do not claim version incompatibility without pointing to the manifest, import, or API surface.
- Do not emit `speculative` findings -- they go in Open questions.
- Do not review only the diff when the request is about architecture, redundancy, or over-engineering.
- Do not confuse "different from my preference" with "wrong".
- Always flag: new file created when an existing file could have been modified.
- Always flag: new function written when an existing function could have been extended.
- Always flag: abstraction with only one caller and no named second use case.
- Always flag: compat surface still alive after the tests it enabled now pass.
- Always flag: mock, stub, or rule-based fake found in production code outside test files.
- Always flag: comment that restates what the code does instead of explaining why.
