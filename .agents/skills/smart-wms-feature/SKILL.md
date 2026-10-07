---
name: smart-wms-feature
description: Add or refactor a Smart WMS Flutter feature using Riverpod, Supabase, and Clean Architecture.
---

# Smart WMS Feature Workflow

Before changing code, read `AGENTS.md`, `docs/system-architecture.md`, and `docs/code-standards.md`.

## Structure

Use:

```text
lib/features/<feature>/
├── data/
├── domain/
└── presentation/
```

Keep Supabase access in data sources, business rules in use cases, and UI state in Riverpod controllers/view models. Put datasource, repository, and use-case construction in `lib/core/di/` providers.

## Implementation checklist

1. Inspect existing entities, repository contracts, routes, and tests.
2. Add or update the domain contract and use case.
3. Implement data-source and repository mapping.
4. Wire dependencies through Riverpod providers.
5. Update the controller/view model and screen.
6. Add focused tests for success, failure, loading, and important state transitions.
7. Run build generation, `flutter analyze`, and `flutter test` when available.

Do not migrate the project to Signals, Dio, GetIt, or Hive unless explicitly requested.
