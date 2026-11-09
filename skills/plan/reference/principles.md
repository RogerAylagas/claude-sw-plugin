# Design principles for sw plans

Use these to design a change and to review a plan. They are ordered: when two conflict, the
earlier one wins.

1. **Correctness**: meets the acceptance criteria; secure; no data loss.
2. **Consistency**: follows the codebase's existing conventions, even where you'd choose differently
   on a blank page. Propose a convention change as its own plan or ADR, not as a side effect.
3. **Minimal change**: fewest files, lines and new concepts that meet the criteria.
4. **Simplicity**: KISS and YAGNI.
5. **Pattern and architecture purity.**

## Minimal change

- **Reuse first.** Search for an existing function, module or library already in the dependency
  tree before writing new code. Duplicating existing logic is a defect.
- **Extend, don't rewrite.** Prefer adding a parameter, branch or small function to an existing
  unit over restructuring it. Refactor only what the change needs, and as separate steps.
- **No drive-by changes.** No unrelated renames, reformatting or "while I'm here" fixes; propose
  them separately.
- **No new dependency** unless it replaces a meaningful amount of code or risk. Justify each one:
  maintenance status, license, size, transitive dependencies.
- Every file in the plan's Changes table must trace back to an acceptance criterion.

## Simplicity

- Build for today's requirements. Add an extension point only when there is a second concrete
  use, not a hypothetical one (rule of three for abstractions).
- Prefer plain functions and data over class hierarchies; composition over inheritance.
- Prefer the language's and framework's standard tools over custom infrastructure.
- Fewer moving parts beats cleverness: one process, one datastore, synchronous code, until a
  requirement says otherwise.

## Design patterns: use one only when its problem is present

Name the pattern in the plan and give the one-line reason the simpler option isn't enough.

| Problem you actually have | Pattern that fits | Simpler option to try first |
|---|---|---|
| Several interchangeable algorithms chosen at runtime | Strategy | A dict of functions; an `if` for two cases |
| Code needs a third-party or legacy interface in your own shape | Adapter | A thin wrapper function |
| Complex construction or a family of related objects | Factory / Builder | Constructor with defaults; named constructors |
| Business logic tangled with storage or I/O | Repository / ports and adapters | Separate pure functions from I/O calls |
| Many consumers must react to an event without coupling | Observer / pub-sub | Direct calls when there are one or two consumers |
| Add behavior around calls (retries, caching, logging) | Decorator / middleware | Inline code at the single call site |
| A complex subsystem needs a simple entry point | Facade | A module-level function |
| Undo, queueing or audit of operations | Command | Plain function calls plus a log line |
| Behavior varies by state with many transitions | State machine | An enum plus a match/switch |

Smells that a pattern is over-engineering: an interface with one implementation and no test
double; a factory that builds one type; an event bus with one subscriber; layers that only pass
calls through.

## Architecture

- **Separation of concerns**: keep domain logic pure and free of I/O; push I/O (HTTP, DB, files,
  clocks, randomness) to the edges ("functional core, imperative shell"). This also makes unit
  tests cheap.
- **Dependency direction**: high-level policy must not import low-level details; depend on narrow
  interfaces at module boundaries, and only where a second implementation or a test needs it.
- **Explicit boundaries and contracts**: validate input at the edges; typed, documented public
  functions; version public APIs; plan migrations for schema and contract changes.
- **Errors**: fail fast on programmer errors; handle expected failures explicitly; never swallow
  exceptions; make operations idempotent where retries can happen.
- **Configuration**: from the environment or config files, not hard-coded; secrets never in code
  or logs.
- **Observability**: log decisions and failures with context at boundaries; add metrics or traces
  only where someone will look at them.
- **Security by design**: least privilege; parameterized queries; encode output; validate and
  limit input sizes; keep dependencies current.

## Computational and economic cost

Optimize what matters, measured, not everything.

- **Hot paths**: state the time and space complexity of code that runs per request, per record or
  in loops. Avoid accidental O(n²) (nested scans, repeated lookups in lists; use sets or dicts).
- **I/O dominates**: batch database and network calls; avoid N+1 queries; paginate; stream large
  data instead of loading it in memory; set timeouts on every network call.
- **Cache only with a plan for invalidation**, and only for measured repeated work.
- **Paid resources**: count calls to paid APIs and LLMs (tokens × price × volume), cloud egress,
  storage growth, always-on compute. Prefer the cheapest tier or model that meets the
  requirement; make expensive features configurable.
- **Measure first**: no optimization without a number that shows the problem (profile, benchmark,
  query plan). Cold paths stay simple.

## Tests

- Every acceptance criterion maps to at least one test.
- **Unit tests**: fast and deterministic, no network, clock or file system (inject them); cover
  the happy path, edge cases and error paths of new and changed code; use the project's existing
  test style and helpers.
- **Integration tests** are needed when the change crosses a boundary: a database, the network, a
  third-party API, the file system, another process or service, or serialization formats shared
  with other systems. Use real dependencies where practical (containers, local servers), fakes
  otherwise; never production.
- Fix flaky tests; don't retry them.
