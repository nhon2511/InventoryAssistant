# Smart WMS Claude Instructions

Follow the project-wide rules in [AGENTS.md](AGENTS.md).

For Flutter application changes, also follow:

- [System architecture](docs/system-architecture.md)
- [Code standards](docs/code-standards.md)

Keep the existing Riverpod, Supabase, GoRouter, and fpdart stack unless the task explicitly requests a migration. Prefer small feature-scoped changes, preserve existing behavior, regenerate Dart code when required, and run `flutter analyze` and `flutter test` before handing off.
