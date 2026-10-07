# Smart WMS Agent Instructions

## Project overview

Smart WMS is a Flutter application for warehouse inventory management. The main workflows are authentication, inbound receiving, inventory lookup, outbound picking, barcode/QR scanning, OCR, realtime stock updates, and an AI assistant.

## Technology constraints

- Flutter/Dart application.
- Riverpod with code generation is the state-management approach.
- Supabase is the backend and authentication provider.
- GoRouter owns navigation.
- `fpdart` is used for typed functional error handling.
- Freezed and JSON serialization are used where immutable serialized models are needed.
- Do not replace Riverpod with Signals, Supabase with Dio, or introduce GetIt/Hive unless explicitly requested.

## Architecture

Features use Clean Architecture boundaries:

```text
presentation -> domain <- data
```

- `presentation/` contains screens, widgets, and Riverpod controllers/view models.
- `domain/` contains entities, repository contracts, and use cases.
- `data/` contains models, data sources, and repository implementations.
- `core/` contains infrastructure and reusable technical services.
- `app/` contains app composition, routing, and theme.

Dependencies should point inward. Widgets must not call Supabase directly. Business rules belong in domain use cases, not screens or data sources.

## State and error handling

- Use Riverpod providers/controllers for feature state.
- Keep asynchronous UI state in `AsyncValue` or an equivalent typed state.
- Repositories should return `Either<Failure, T>` when the operation can fail.
- Translate transport/backend errors at the data boundary.
- UI should render a user-facing localized message, not a raw exception.
- Navigation, dialogs, snackbars, and other one-shot UI effects belong to the widget layer.

## Supabase rules

- Access Supabase through data sources or dedicated core services.
- Keep table names, RPC calls, and response parsing out of widgets and domain code.
- Preserve the existing authentication and schema contracts unless the task explicitly changes them.
- Never commit secrets; use `.env` and `.env.example` appropriately.

## Change workflow

Before changing code:

1. Read the relevant feature and its tests.
2. Check `docs/system-architecture.md` and `docs/code-standards.md`.
3. Keep changes scoped to the requested feature.
4. Reuse existing patterns before introducing a new abstraction.

After changing annotated Dart code or generated models:

```bash
dart run build_runner build
flutter analyze
flutter test
```

Do not edit generated `.g.dart` files by hand.

## Feature checklist

For a new or substantially changed feature, verify:

- Domain entity/model and repository contract are defined.
- Use cases contain business decisions.
- Data source owns Supabase/transport details.
- Repository implementation maps data errors to domain failures.
- Riverpod controller/view model exposes loading, success, and error states.
- Screen and widget tests cover important states and user actions.
- Routing and authorization are updated when needed.

## Current feature areas

- `features/auth/` — authentication and profiles.
- `features/inventory/` — products, locations, stock, and realtime inventory.
- `features/inbound/` — receiving orders, batch scanning, and OCR.
- `features/outbound/` — outbound orders, pick lists, and scan verification.
- `features/ai_assistant/` — natural-language intent parsing and stock queries.
