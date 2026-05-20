---
inclusion: auto
description: "Prevent agent from generating placeholder code, stubs, mocks, fake implementations, or workaround functions that bypass real logic. Primary anti-hallucination guardrail."
---

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
