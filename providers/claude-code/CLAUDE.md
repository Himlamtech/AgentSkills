# Agent Instructions

_Auto-generated from AgentSkills canonical source. Do not edit directly._


---

## Rules


# Agent Behavior Rules

## Operating Stance

- Act like a senior engineer. Be decisive.
- Verify against the repository before you guess.
- Use verified functions, libraries, and patterns only.
- Do not hard-code business logic; route behavior through config or existing abstractions.

## Anti-Hallucination

- Do not fabricate file paths, module names, class names, or behavior.
- Do not assume a function, API, or config key exists without verifying.
- If you cannot verify something, label it `[Assumption]` and state what you could not check.
- Do not present speculative code as working implementation.

## Verification Contract

After any code change:
1. The originally requested behavior must work end to end.
2. At least one negative path must be tested (invalid input, error state, empty collection).
3. No existing tests may regress.

What does NOT count as verification:
- Mocking so much that the test does not exercise real behavior
- Testing only the happy path
- Marking "verified" based on static reasoning without running anything
- Writing tests that assert mocks were called rather than asserting observable output

## When Stuck

If you cannot solve a problem after two attempts:
1. Stop and diagnose the root cause.
2. Explain what went wrong.
3. Propose a fundamentally different approach.
4. Never generate fake/stub code to "resolve" the issue.

## Scope Discipline

- Solve the problem that was asked about.
- Do not add features, abstractions, or defensive code beyond what the task requires.
- Do not refactor unrelated code unless the task explicitly requires it.
- A bug fix does not need surrounding code cleaned up.
- A simple feature does not need extra configurability.


# Code Discipline

## SOLID Principles

- One responsibility per module, class, and function.
- Extend existing owners instead of splitting behavior across parallel paths.
- Depend on stable contracts, not concrete implementation details.
- Prefer composition over inheritance unless the existing hierarchy is the owning contract.
- Do not introduce abstractions without a second concrete caller.

## File and Function Ownership

- Before creating a new file, find the file that owns this responsibility and modify it.
- Before creating a new function, find the function that can be extended and extend it.
- Before creating a new class, check whether an existing class can absorb this behavior.
- When creating something new is genuinely necessary, state the reason explicitly.

## No Over-Engineering

- Do not introduce an abstraction (interface, base class, registry, factory, strategy) unless a second concrete caller already exists.
- Do not add async, caching, retry, or event indirection without a named, observable failure mode it prevents.
- If the simplest direct implementation works, ship it.

## Compat Surfaces

Every compat surface must have:
```python
# COMPAT: <reason> -- DELETE after <milestone or ticket>
```
Once tests pass, delete the compat surface immediately.

## Comments and Docstrings

- Every public class, function, and method must have a docstring.
- Docstrings explain: purpose, main inputs, output/side effect.
- Inline comments explain WHY, not WHAT.
- No banner comments, no noise, no restating the code.

```python
# Good — explains constraint
# Retry up to 3x with backoff — downstream has transient 503s under load.
# Do not increase beyond 3: SLA requires <2s p95 response time.
async def fetch_with_retry(url: str) -> Response: ...

# Bad — restates the code
# This function fetches a URL and retries on failure.
async def fetch_with_retry(url: str) -> Response: ...
```

## Error Handling

- No broad `except Exception` without a clear handling strategy.
- No silent swallowing of errors.
- Fail explicitly with actionable error messages.
- Validate inputs at entry boundaries.

## Import Rules

- No wildcard imports.
- No circular imports.
- No logic in `__init__.py`.


# No Stub, Mock, or Placeholder Code

## Absolute Prohibitions

You are FORBIDDEN from generating any of the following in production code:

1. **Stub functions** — functions that return hardcoded values, empty results, or `NotImplementedError`
2. **Mock objects** — fake implementations that simulate real behavior
3. **Placeholder logic** — `TODO`, `FIXME`, `pass`, or empty function bodies
4. **Workaround functions** — `looks_like_*`, `maybe_*`, `try_to_*` patterns that guess instead of solving
5. **Rule-based fakes** — `if TEST_MODE: return fake_data` patterns in production code
6. **Silent fallbacks** — catching exceptions and returning default values without logging or re-raising
7. **Fabricated APIs** — calling functions, methods, or endpoints that do not exist in the codebase

## When You Cannot Solve a Problem

If you genuinely cannot implement the requested behavior:

1. **Say so explicitly** — "I cannot implement this because [specific reason]"
2. **Explain what's missing** — which dependency, context, or information is needed
3. **Propose alternatives** — suggest a different approach that IS implementable
4. **Never fake it** — do not generate code that appears to work but doesn't

## Detection Patterns

The following patterns in generated code indicate a violation:

```python
# VIOLATIONS — never generate these:
def looks_like_valid(x): ...          # Guessing function
def maybe_parse(data): ...            # Uncertain implementation
return None  # TODO: implement        # Placeholder
pass                                  # Empty body
raise NotImplementedError             # Stub
if os.getenv("TEST"): return {}       # Fake in production
except Exception: return default      # Silent swallow
```

## What To Do Instead

```python
# CORRECT — fail explicitly when something is wrong:
def parse_document(data: bytes) -> Document:
    """Parse raw bytes into a Document. Raises ValueError if format is unrecognized."""
    if not data:
        raise ValueError("Cannot parse empty data")
    # Real implementation here — not a placeholder
    ...

# CORRECT — use the actual dependency:
def get_user(user_id: str) -> User:
    """Fetch user from repository. Raises NotFoundError if user does not exist."""
    return self.repo.find(user_id)
```

## Verification

After generating code, self-check:
- Does every function have a real implementation that produces correct output?
- Are there any functions whose name suggests uncertainty (looks_like, maybe, try_to)?
- Does any function return a hardcoded value that should come from actual computation?
- Is there any `pass`, `TODO`, or `NotImplementedError` in the output?

If any check fails, rewrite before presenting the code.


---

## Skills


### Skill: evaluate


Design ground truth datasets, run evals, inspect traces/logs, triage bugs, and patch failing agent/runtime code. Use when building or updating eval sets, tracing live runs, diagnosing false passes/fails, adding logging, or fixing code from eval evidence.


Triggers: evaluate this, run eval, triage this bug, inspect trace, build ground truth


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


### Skill: implement


Implement approved features, fixes, or refactors from a proposal, issue, or Plan output -- grounded in the current repo state. Delivers verified code changes.


Triggers: implement this, code this up, build it, make the changes, continue


# Implement

Turn an approved target state into verified code. Smallest complete diff. No placeholders. No skipped verification.

## Implementation Contract

Before writing code, lock these down:

- target behavior
- acceptance criteria
- source of truth for current behavior
- exact change boundary
- verification surface

If any of these are fuzzy, tighten them before editing code.

## Objective

Produce the minimal complete implementation that satisfies the requested behavior -- aligned with current architecture, conventions, and runtime constraints. Do not over-build. Do not under-verify.

## Step 1 -- Read before touching any file

Read in this order:

1. Engineering guides, architecture docs, coding standards -- whatever convention files exist in the repo
2. The Plan doc, proposal, issue, or feature request
3. **Tests and configs in the affected area first** -- they define contracts before implementation does
4. The current owning implementation path end to end
5. Current working tree diff -- understand what has already changed

**Key questions to answer before writing a single line:**
- What is the exact acceptance criterion -- what observable behavior must exist when done?
- What does the existing test suite expect from the areas being changed?
- What conventions govern naming, structure, error handling, and logging in this module?
- What existing utilities, helpers, or services already cover part of this work?
- Are there any existing functions that can be extended rather than replaced?
- What part of the request is explicitly out of scope for this diff?

## Step 2 -- Declare the minimal change set

Before writing code, declare intent:

| Path | Action | What changes | Why |
|------|--------|-------------|-----|
| `path/to/file.py` | Modify | Add `cancel()` with state guard | Domain owns state machine |
| `config/settings.yaml` | Modify | Add `order.cancel_timeout_seconds: 30` | Replace hardcoded value |
| `tests/test_cancel.py` | Add | Coverage for new cancel paths | New behavior |

Mark tentative paths explicitly. Update this table as implementation progresses -- it is the audit trail for the Review step.

**Reuse rules -- check before creating anything new:**
- Search for an existing utility, helper, or service that already handles any part of this work. If found, use it.
- If an existing function can be extended without violating its contract, extend it -- do not write a parallel version.
- If an existing file owns this responsibility, modify it -- do not create a new file and deprecate the old one. That is always wrong.
- If similar logic already exists in two places, consolidate into one -- do not add a third copy.

## Step 3 -- Code discipline

These rules apply to every line written. Violating them is a defect, not a style issue.

### No over-engineering

Do not introduce an abstraction -- interface, base class, registry, factory, strategy pattern -- unless a **second concrete caller already exists** in this task or codebase. One caller = no abstraction. Name the second caller or write direct code.

Do not add async, caching, retry, or event indirection without a named, observable failure mode it prevents. "It might be useful later" is not a reason.

If the simplest direct implementation works, ship it. Every layer of indirection is a permanent maintenance cost.

### SOLID is mandatory

All new code and refactors must follow SOLID at the smallest practical scope.

- Keep one responsibility per module, class, and function.
- Extend existing owners instead of splitting behavior across parallel paths.
- Depend on stable contracts, not concrete implementation details, when a boundary already exists.
- Prefer composition over inheritance unless the existing hierarchy is already the owning contract.
- Do not introduce abstractions without a second concrete caller or a real reuse boundary.

### Modify existing before creating new

Before creating a new file, find the file that owns this responsibility and modify it.  
Before creating a new function, find the function that can be extended and extend it.  
Before creating a new class, check whether an existing class can absorb this behavior.

When creating something new is genuinely necessary, state the reason explicitly in a comment or issue note: "No existing owner for this responsibility because X."

### Compat surfaces are temporary by definition

If backward-compat code is needed to pass tests during a transition, add it with:

```python
# COMPAT: <reason> -- DELETE after <milestone or ticket number>
```

**Once tests pass, delete the compat surface immediately.** Do not leave it for a follow-up that never happens. If deletion must be deferred, it must go into the implementation report under "Compat surfaces remaining" with a concrete owner and removal date.

### Comments: explain why, not what

Every non-trivial function, class, module, and critical logic block must have a docstring or inline comment that explains **why it exists or what contract it enforces** -- not a restatement of what the code does. Reading the code already tells you what it does.

```python
# Good -- explains why and the constraint
# Retry up to 3× with exponential backoff -- downstream has transient 503s under load.
# Do not increase beyond 3: SLA requires <2s p95 response time.
async def fetch_with_retry(url: str) -> Response: ...

# Bad -- restates the code
# This function fetches a URL and retries on failure.
async def fetch_with_retry(url: str) -> Response: ...
```

Target: minimum words for a new engineer to understand intent without reading the body. Too long = defect. Missing entirely on non-trivial code or critical logic = defect.

### No mocks, stubs, or fakes in production code

Test doubles belong exclusively in test files. Never in `src/`, `app/`, or any production module.

Do not ship rule-based fallback logic that mimics a real service. If a dependency is unavailable in a given environment, raise an explicit, actionable error -- do not silently return fake data.

```python
# Wrong -- silent fake in production code
def get_user(user_id: str) -> User:
    if settings.TEST_MODE:
        return User(id=user_id, name="Test User")  # fake
    return self.repo.find(user_id)

# Right -- fail explicitly, keep test doubles in test files
def get_user(user_id: str) -> User:
    return self.repo.find(user_id)  # raises NotFoundError if missing
```

## Step 4 -- Verification contract

Verification is incomplete unless all three criteria are met:

| Criterion | What it means |
|-----------|--------------|
| Acceptance scenario passes | The originally requested behavior works end to end |
| At least one negative path tested | Invalid input, error state, empty collection, or permission denied |
| No existing tests regressed | Affected area suite still green |

**Common verification mistakes that do not count as verification:**
- Mocking so much that the test does not exercise real behavior
- Running tests on a different code path than what changed
- Testing only the happy path
- Marking "verified" based on static reasoning without actually running anything
- Writing a test that asserts mocks were called rather than asserting observable output

**For AI-system or E2E behavior -- real test format:**

```text
Input:    <exact user input or API call -- no paraphrasing>
Setup:    <fixtures, seed data, environment state required>
Expected: <behavior in plain language -- what the system does, not just what it returns>
Pass rule: <observable, objective criterion>
Fail rule: <what failure looks like -- hallucination pattern, wrong format, missing field, wrong status>
```

If a real test fails -> fix the implementation immediately. Do not document around it or defer.

## Step 5 -- Continue workflow

When resuming an interrupted task, determine the current phase before doing anything else.

| Phase | Signal |
|-------|--------|
| `implementation` | File impact table has unimplemented rows; code changes incomplete |
| `testing` | Code complete; test files modified but no run output recorded |
| `deployment` | Tests passing; no deploy confirmation |
| `documentation` | Deploy done; docs or config comments not updated |
| `completed` | All above confirmed |

Determine phase by inspecting: git diff, test output files, deploy logs. If ambiguous, re-run targeted tests to confirm current state. Do not repeat already-finished work. Do not skip a phase because resuming feels like starting fresh.

## Output format

```markdown
## Implementation: <feature or fix name>

### Summary
<2-4 sentences: what was done, what approach was taken, what was deliberately excluded>

### File impact
| Path | Action | What changed |
|------|--------|-------------|
| ... | ... | ... |

### Compat surfaces remaining
- `path/to/file:line` -- COMPAT: reason -- DELETE by: <milestone> -- Owner: <name>
(or: none)

### Verification results
- Acceptance scenario: ✅ / ❌ <detail>
- Negative path tested: ✅ / ❌ <which scenario>
- Regression check: ✅ / ❌ <suite or area checked>

### Remaining risks
- ...
```

## Guardrails

- Do not leave placeholder, stub, or TODO code in final output.
- Do not skip the verification contract -- "it looks right" is not verification.
- Do not write tests that only mock everything -- they must exercise real behavior.
- Do not rewrite unrelated modules to make the diff feel cleaner.
- Do not mark a phase complete if its verification criterion is not met.
- Do not deploy using guesswork -- use the project's established deploy path only when explicitly in scope.
- Do not add a new abstraction without naming the second concrete caller that justifies it.
- Do not create a new file when an existing file owns the responsibility.
- Do not create a new function when an existing function can be extended.
- Do not leave a compat surface alive after tests pass -- delete it now.
- Do not place mocks, stubs, or fakes in production code.
- Do not write comments that restate what the code does -- explain why.


### Skill: plan


Write implementation-ready engineering docs from a proposal, feature request, issue, or architecture intent -- grounded in the current repo state. Use before coding starts. Produces a living doc that separates current state from target state with concrete file impact and test specs.


Triggers: plan this, write a proposal, design doc, before we implement, document this feature


# Plan

Write implementation-ready engineering docs. Not descriptive -- actionable. Every claim must be code-backed or explicitly labeled as an assumption.

## Decision Contract

Before writing, lock these down:

- target question
- target behavior
- acceptance criteria
- source scope
- out-of-scope boundary
- open questions

If the request is about a new model, method, vendor, or recent change, ground the plan in current sources first and label stale or missing evidence.

## Objective

Produce a document that makes three things unambiguous:
- **What exists today** -- verified from actual code, not inferred
- **What the target state is** -- proposed behavior with clear boundaries
- **What must change** -- concrete files, config deltas, test specs

## Step 1 -- Read before writing

Read the repo before forming any claim. Do not write from the feature request alone.

**Reading order:**
1. Engineering guides, architecture docs, coding standards -- whatever convention files exist in the repo
2. The proposal, issue, or feature request
3. Tests and configs in the affected area -- they reveal contracts before implementation does
4. The current owning implementation path end to end
5. Adjacent schemas, migrations, manifests if the change touches them
6. Current working tree diff if relevant

**Rules:**
- If a source does not exist, mark every claim derived from it as `[Assumption]`
- Do not fabricate file paths, module names, class names, or behavior
- If you are unsure whether something exists, say so -- do not guess
- Do not turn research notes into shipped behavior; keep research findings in `[Current]` and proposed changes in `[Target]`

## Step 2 -- Label every claim

Use these labels inline throughout the document. Every non-trivial statement must be traceable.

| Label | Meaning |
|-------|---------|
| `[Current]` | Verified in actual code right now |
| `[Target]` | Proposed -- does not exist yet |
| `[Gap]` | Delta between current and target that must be closed |
| `[Assumption]` | Not verified -- source not found or ambiguous |
| `[Risk]` | Known failure mode or uncertainty that could block delivery |
| `[Open question]` | Must be answered before implementation can start safely |
| `[Dependency]` | External blocker -- another team, service, or unmerged ticket |

## Step 3 -- Write the document

Sections 1-4 are always required. Sections 5, 6, 7 are non-optional for any non-trivial change -- skipping them means the doc is not implementation-ready.

### 1. Overview

- What is being built and why it matters now
- User or business value in concrete terms -- not "improve UX" but "user can do X without Y step"
- Explicit scope boundary: what is out of scope and why
- Key assumptions and open questions surfaced upfront, not buried at the end

### 2. Current state `[Current]`

Code-backed description only. Do not pad with generic architecture prose.

- Relevant architecture: which layers, modules, and services own this area
- Current user or system flow: who triggers what, in what order, what the system returns
- Existing APIs, services, config keys, schemas, DB tables, jobs, queues involved -- name them exactly as they appear in the codebase
- Known limitations, technical debt, or mismatches with the proposal -- be specific

If something is partially implemented, state exactly which parts exist and which do not.

### 3. Target behavior `[Target]`

Describe proposed behavior with enough precision that an engineer can implement it without follow-up questions.

- Actors and trigger points
- Step-by-step sequence of events -- not a vague summary
- Sync vs async boundaries: where does the caller block? where does work continue in the background?
- Error handling: what happens on timeout, invalid input, partial failure, permission denied?
- Auth, multi-tenancy, rate limiting concerns if applicable
- What the system must NOT do (negative scope) when relevant

Include a Mermaid diagram only when the flow has branching, async steps, or multiple actors interacting. Skip for linear single-actor flows -- a diagram of a straight line adds noise, not clarity.

```mermaid
sequenceDiagram
  Actor->>Service: trigger
  Service-->>Queue: enqueue job
  Worker->>DB: persist result
```

### 4. Implementation approach `[Gap]`

How the target behavior fits into the current architecture. Be precise -- "we'll add a service" is not an implementation approach.

- Which layer and module owns the new behavior, and why that layer
- Interfaces to add or change -- show the actual function signature, not a description of it
- **File and function reuse rule:** prefer modifying an existing file over creating a new one. Prefer extending an existing function over writing a new one. When proposing a new file or function, explicitly justify why no existing owner can absorb this responsibility. Creating a new file + deprecating an old one that does the same job is always wrong.
- Config delta: exact keys to add or change, which hardcoded values move to config, what the runtime fallback is when config is missing
- Compat surfaces: if backward compatibility is needed during transition, label every surface with `# COMPAT: <reason> -- DELETE after <milestone>`. Every compat surface must have a concrete, dated removal condition. "Remove later" is not acceptable.
- **Abstraction rule:** do not propose an interface, base class, registry, strategy, or factory unless a second concrete caller is already identified in this task. Name the second caller explicitly or drop the abstraction entirely.

### 5. File impact

Show the full change surface. Be specific -- "various files" is not acceptable.

```text
project/
├── src/
│   ├── domain/
│   │   └── order.py          ← Modify: add cancel() with state guard
│   └── infrastructure/
│       └── order_repo.py     ← Modify: persist cancellation
├── tests/
│   └── test_order_cancel.py  ← Add: unit + integration specs
└── config/
    └── settings.yaml         ← Modify: add order.cancel_timeout_seconds
```

| Path | Action | What changes | Why |
|------|--------|-------------|-----|
| `src/domain/order.py` | Modify | Add `cancel()` with state validation | Domain owns the state machine |
| `config/settings.yaml` | Modify | Add `order.cancel_timeout_seconds: 30` | Replace hardcoded value |
| `tests/test_order_cancel.py` | Add | Happy path + invalid state + timeout | New behavior needs coverage |

Also cover explicitly:
- Config keys added, changed, or removed and their default values
- API contract changes: request/response shape, status codes, headers
- DB schema changes and whether a migration is required
- Permission or auth model changes
- Observability: new logs, metrics, traces added or changed

### 6. Test specs

Define coverage for every critical path. A failing real test = implementation bug, not a doc gap.

**Unit and integration scenarios:**

| Scenario | Input | Expected | Notes |
|----------|-------|----------|-------|
| Happy path | Valid order in `pending` state | State → `cancelled`, event emitted | -- |
| Wrong state | Order already `shipped` | `InvalidStateError` raised | Must not silently ignore |
| Invalid input | `order_id = None` | `ValueError` with specific message | Validate at entry boundary |
| Concurrent cancel | Two simultaneous requests | One succeeds, one gets 409 | Requires row-level lock |
| Timeout | Downstream slow | Retry N times then raise | N from config |

**Real tests (required for AI-facing or E2E paths):**

```text
Input:    POST /orders/123/cancel with valid auth token
Setup:    Order 123 in DB with status=pending, user has cancel permission
Expected: Response 200, DB status=cancelled, cancellation event in queue
Pass rule: All three conditions verified in a single test run against real DB and queue
Fail rule: Any condition missing, or DB status still=pending after 200 response
```

For AI system behavior -- also define:
- Keywords or structural patterns that must appear in the response
- Patterns that constitute a failure: hallucination, wrong format, refusal when the answer is known

### 7. Definition of done

- [ ] Real tests pass -- not just unit tests
- [ ] Config updated with correct keys and documented defaults
- [ ] All compat surfaces deleted or explicitly deferred with a removal ticket and owner
- [ ] Observability in place: logs at entry/exit of changed critical paths, metrics for new async work
- [ ] No `[Assumption]` items unresolved that would block correct implementation
- [ ] No `[Open question]` items unanswered that would change the design

## Code discipline

Every design decision in this document must follow these rules. Violating them in the plan means the implementation will inherit the defect.

**No over-engineering.** Do not propose an abstraction with one caller. Do not propose async, caching, or retry without naming the specific failure mode it prevents. The simplest design that satisfies the requirement is the correct design.

**Modify before create.** Propose modifying an existing file or function before creating a new one. Justify every new file and function explicitly. Creating a new file alongside a deprecated old one doing the same job is always wrong.

**Compat is temporary.** Every compat surface must have a concrete deletion condition tied to a milestone or ticket. No open-ended compat surfaces.

**Comments explain why, not what.** Every non-trivial function and class gets a one-line comment explaining why it exists or what contract it enforces -- not a restatement of the code. Too long = defect. Too short = defect. The minimum words needed for a new engineer to understand intent without reading the body.

**No mocks or fakes in production code.** Test doubles belong in test files only. If a dependency is unavailable in some environment, the system must fail explicitly -- not silently fall back to fake behavior.

## Guardrails

- Do not present proposals as shipped behavior -- use `[Target]`.
- Do not invent file paths, module names, or signatures -- verify or label `[Assumption]`.
- Do not write a generic implementation section that ignores actual repo ownership.
- Do not hide conflicts between the proposal and what the codebase currently supports.
- Do not omit Sections 5 and 6 for non-trivial changes -- they are the implementation contract.
- Do not propose a new abstraction without naming its second caller.
- Do not mark DB schema changes as approved implicitly -- flag as `[Dependency]` requiring sign-off.
- Do not accept compat surfaces without a concrete, dated removal condition.


### Skill: research


Survey and evaluate new models, methods, product features, vendor offerings, and current news against current repo and product context. Use for source-backed comparisons, adoption decisions, competitive scans, build-vs-buy evaluation.


Triggers: research this, investigate, compare options, latest on, should we adopt, assess fit


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


### Skill: review


Review changed code, generated files, existing modules, or feature slices for logic regressions, contract drift, redundant logic, over-engineering, dependency risk, missing tests, and insecure patterns. Use after implementation. Findings-first, severity-ordered, evidence-required.


Triggers: review this, check this diff, audit this module, is this correct, review before merge


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
