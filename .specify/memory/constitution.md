<!--
SYNC IMPACT REPORT
==================
Version change: (none) → 1.0.0
Added sections:
  - Core Principles (I. Code Quality, II. Test Standards, III. UX Consistency, IV. Performance Requirements)
  - Quality Gates
  - Development Workflow
  - Governance
Modified principles: N/A (initial ratification)
Removed sections: N/A
Templates requiring updates:
  - .specify/templates/plan-template.md ✅ aligned (Constitution Check section uses principle-based gates)
  - .specify/templates/spec-template.md ✅ aligned (Success Criteria supports perf metrics; FR uses MUST)
  - .specify/templates/tasks-template.md ✅ aligned (test tasks map to Test-First principle)
Follow-up TODOs: none
-->

# POS Constitution

## Core Principles

### I. Code Quality (NON-NEGOTIABLE)

All production code MUST meet the following standards without exception:

- **Readability first**: Code MUST be self-explanatory through naming; comments are reserved for
  non-obvious invariants, constraints, or workarounds only.
- **No dead code**: Unused variables, functions, imports, or feature flags MUST be removed before
  merge — no commented-out blocks left in place.
- **Single responsibility**: Each module, class, and function MUST have one clear purpose; mixing
  concerns at any layer is a violation.
- **No hardcoded values**: Business constants (prices, timeouts, limits) MUST be extracted to
  configuration or constants files; secrets MUST be environment variables.
- **Dependency hygiene**: Only add a dependency when it solves a problem that cannot be reasonably
  solved in-house; every added dependency MUST be pinned to a stable, actively maintained version.

*Rationale*: A POS system handles real financial transactions. Unclear or tangled code increases the
risk of silent bugs that are costly to detect in production.

### II. Test Standards (NON-NEGOTIABLE)

Tests are a first-class deliverable, not an afterthought:

- **Test-First (TDD)**: Tests MUST be written and confirmed to fail before the implementation is
  written. The Red → Green → Refactor cycle is mandatory.
- **Coverage floor**: Unit test coverage MUST remain at or above 80% for all business-logic
  modules; coverage reports MUST be part of CI.
- **Test pyramid**: Unit tests MUST outnumber integration tests; integration tests MUST outnumber
  end-to-end tests. No inversion of the pyramid is permitted.
- **No mocking persistence in integration tests**: Integration tests MUST hit a real (or
  containerised) database. In-memory or mock stores are permitted only for unit tests.
- **Acceptance scenarios are executable**: Every user-story acceptance scenario defined in spec.md
  MUST map to at least one automated test; untested acceptance criteria block release.
- **Flaky tests MUST be fixed immediately**: A flaky test MUST be quarantined and fixed within one
  sprint; it MUST NOT be merged in a flaky state.

*Rationale*: Financial correctness cannot be validated manually at scale. Automated, trustworthy
tests are the primary safety net for payment and inventory logic.

### III. User Experience Consistency

The UX across all POS interfaces MUST feel like a single, cohesive product:

- **Design token conformance**: All UI components MUST use shared design tokens (colors, spacing,
  typography); raw hex values or pixel literals in component code are a violation.
- **Error messages are actionable**: Every user-facing error MUST state what went wrong AND what
  the user can do next. Generic messages ("Something went wrong") are not permitted.
- **Accessibility (WCAG 2.1 AA)**: All interactive surfaces MUST meet WCAG 2.1 Level AA. Keyboard
  navigation and screen-reader support are non-optional.
- **Consistent interaction patterns**: Destructive actions (void, refund, delete) MUST require
  explicit confirmation. Form submission patterns MUST be consistent across all screens.
- **Offline-aware feedback**: When the device is offline or a network call fails, the UI MUST
  communicate state clearly and prevent data loss (optimistic updates require rollback handling).

*Rationale*: POS operators work under time pressure with real customers present. Inconsistent or
confusing UX directly causes transaction errors and customer dissatisfaction.

### IV. Performance Requirements

Performance targets are hard constraints, not aspirational goals:

- **Transaction response time**: Payment processing and order submission MUST complete in under
  **2 seconds** at p95 under normal load (up to 100 concurrent sessions).
- **Screen transition time**: All route/page transitions MUST render within **300 ms** on
  target hardware; heavy data loads MUST use pagination or virtualisation.
- **API response time**: Internal API calls MUST return within **500 ms** at p95; calls exceeding
  **1 second** MUST be flagged in code review and require architectural justification.
- **Bundle/startup size**: The client application MUST start up in under **3 seconds** on the
  minimum supported hardware. Bundle size increases above 10 % MUST be explicitly approved.
- **Regression prevention**: Performance benchmarks MUST be part of CI; a PR that regresses any
  target by more than 10 % MUST NOT be merged without a documented remediation plan.

*Rationale*: Slow transactions create queues, frustrate customers, and may cause retry errors that
corrupt financial records.

## Quality Gates

These gates MUST pass before any code is merged to the main branch:

- **Static analysis**: Linter and formatter checks MUST pass with zero warnings (warnings-as-errors
  mode enabled in CI).
- **Type safety**: The codebase MUST use strong typing (TypeScript strict mode, or equivalent);
  `any` / untyped escapes MUST be reviewed and minimised.
- **Security scan**: Dependency vulnerability scan (e.g., `npm audit`, `trivy`) MUST produce zero
  critical findings; high-severity findings MUST be addressed within 48 hours.
- **Test suite green**: All unit, integration, and contract tests MUST pass in CI before merge.
- **Performance benchmarks green**: Automated perf benchmarks (Principle IV) MUST pass in CI.
- **Peer review**: Every PR MUST have at least one approving review from a team member who did not
  write the code; self-merges are prohibited.

## Development Workflow

- **Branch per feature**: Every feature and bug fix MUST live on its own branch following the
  naming convention `[###-feature-name]`.
- **Commit discipline**: Each commit MUST be atomic and pass all checks independently. Commit
  messages MUST follow the Conventional Commits format (`feat:`, `fix:`, `refactor:`, etc.).
- **Spec before code**: A feature MUST have an approved `spec.md` before implementation begins;
  unspecified features MUST NOT be merged.
- **Plan before tasking**: An approved `plan.md` MUST exist before `tasks.md` is generated or
  implementation is started.
- **Definition of Done**: A task is done when: code is implemented, tests pass, PR is reviewed and
  approved, CI is green, and the spec's acceptance criteria are verified.

## Governance

This constitution supersedes all other development guidelines and conventions within this project.
Any practice that conflicts with a principle defined here MUST be resolved in favour of the
constitution.

**Amendment procedure**:
1. Propose the change in a dedicated PR with justification and impact analysis.
2. Obtain approval from at least two team members.
3. Update `CONSTITUTION_VERSION` (MAJOR/MINOR/PATCH per semantic versioning rules defined below).
4. Update `LAST_AMENDED_DATE` to the amendment date.
5. Propagate changes to all dependent templates (plan, spec, tasks).

**Versioning policy**:
- MAJOR: removal or redefinition of a principle in a backward-incompatible way.
- MINOR: addition of a new principle or material expansion of an existing section.
- PATCH: clarification, wording improvement, or non-semantic refinement.

**Compliance review**: All PRs and code reviews MUST verify adherence to this constitution.
Complexity or deviation MUST be explicitly justified with a documented rationale; undocumented
violations are merge blockers.

**Version**: 1.0.0 | **Ratified**: 2026-04-18 | **Last Amended**: 2026-04-18
