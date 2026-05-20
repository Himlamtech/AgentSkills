# Copilot Instructions

_Auto-generated from AgentSkills canonical source._


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

## Workflow Skills


### evaluate

Design ground truth datasets, run evals, inspect traces/logs, triage bugs, and patch failing agent/runtime code. Use when building or updating eval sets, tracing live runs, diagnosing false passes/fails, adding logging, or fixing code from eval evidence.


### implement

Implement approved features, fixes, or refactors from a proposal, issue, or Plan output -- grounded in the current repo state. Delivers verified code changes.


**Guardrails:**
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


### plan

Write implementation-ready engineering docs from a proposal, feature request, issue, or architecture intent -- grounded in the current repo state. Use before coding starts. Produces a living doc that separates current state from target state with concrete file impact and test specs.


**Guardrails:**
- Do not present proposals as shipped behavior -- use `[Target]`.
- Do not invent file paths, module names, or signatures -- verify or label `[Assumption]`.
- Do not write a generic implementation section that ignores actual repo ownership.
- Do not hide conflicts between the proposal and what the codebase currently supports.
- Do not omit Sections 5 and 6 for non-trivial changes -- they are the implementation contract.
- Do not propose a new abstraction without naming its second caller.
- Do not mark DB schema changes as approved implicitly -- flag as `[Dependency]` requiring sign-off.
- Do not accept compat surfaces without a concrete, dated removal condition.


### research

Survey and evaluate new models, methods, product features, vendor offerings, and current news against current repo and product context. Use for source-backed comparisons, adoption decisions, competitive scans, build-vs-buy evaluation.


**Guardrails:**
- Use current sources; call out stale evidence.
- Cite every nontrivial claim.
- Keep fact, inference, and recommendation separate.
- Prefer primary sources over summaries.
- If evidence is thin, say so and lower confidence.


### review

Review changed code, generated files, existing modules, or feature slices for logic regressions, contract drift, redundant logic, over-engineering, dependency risk, missing tests, and insecure patterns. Use after implementation. Findings-first, severity-ordered, evidence-required.


**Guardrails:**
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
