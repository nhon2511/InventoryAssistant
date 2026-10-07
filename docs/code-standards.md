# Smart WMS Code Standards

## Naming and files

- Dart files use `snake_case.dart`.
- Types use `PascalCase`.
- Variables, methods, and provider functions use `camelCase`.
- Screens use the suffix `_screen.dart`.
- Reusable UI components use descriptive names and live under `widgets/`.
- Riverpod state owners use `_controller.dart`; use `_view_model.dart` when a class is intentionally presented as a view model.
- Use cases use the suffix `_usecase.dart` to match the existing project convention.
- Generated files end in `.g.dart` and must not be edited manually.

## Layer rules

### Presentation

- Reads state from Riverpod providers/controllers.
- Owns layout, user interaction, navigation, dialogs, snackbars, and localization.
- Does not call Supabase directly.
- Does not contain repository construction or business rules.

### Domain

- Contains entities, repository contracts, and use cases.
- Contains business decisions and validation rules.
- Should not import Flutter UI or Supabase implementation details.
- Returns typed results, preferably `Either<Failure, T>` for fallible operations.

### Data

- Contains DTO/model conversion, Supabase queries, and repository implementations.
- Translates backend and transport errors into project `Failure` types.
- Keeps response parsing at the data boundary.

## Riverpod conventions

- Use generated providers with `@riverpod` where the project already follows that pattern.
- Keep provider state focused on one feature responsibility.
- Expose loading, data, empty, and error states intentionally.
- Avoid constructing the full datasource/repository graph repeatedly inside every controller; prefer dedicated providers as the DI layer is introduced.
- Dispose stream subscriptions, timers, and realtime channels at the owner that creates them.

## Supabase conventions

- Keep Supabase client access in `core/network` or feature data sources.
- Use repository methods to express business operations rather than leaking table queries upward.
- Do not expose raw `PostgrestException` or `AuthException` to presentation.
- Keep credentials in environment configuration and never commit real secrets.

## UI conventions

- Reuse existing loading, error, empty-state, and confirmation widgets.
- Keep screens composable and move repeated UI into feature or shared widgets.
- Navigation belongs to GoRouter and widget callbacks, not domain use cases.
- User-visible strings should support the existing Vietnamese/English localization direction.

## Models and generated code

- Use immutable models when serialization or value equality matters.
- Parse JSON only at data boundaries.
- After changing annotations, models, or providers, run:

```bash
dart run build_runner build
```

## Testing

- Place tests under `test/` with a structure that mirrors `lib/` where practical.
- Test domain use cases independently from Supabase.
- Test controllers for loading, success, error, refresh, and important state transitions.
- Test parser/utilities with edge cases.
- Add widget tests for important user interactions and UI states.

## Verification commands

```bash
flutter analyze
flutter test
```

For release-related changes, also verify the relevant platform build after the local test suite passes.
