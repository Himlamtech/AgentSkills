---
name: no-stub-mock
description: >
  Prevent agent from generating placeholder code, stubs, mocks, fake implementations,
  or workaround functions that bypass real logic. This is the primary anti-hallucination
  and anti-reward-hacking guardrail.
inclusion: always
priority: critical
---

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
