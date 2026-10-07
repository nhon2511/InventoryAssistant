# Smart WMS System Architecture

## Scope

Smart WMS is a Flutter client backed by Supabase. The application manages authentication, inbound receiving, inventory, outbound picking, scanning/OCR, realtime stock updates, and AI-assisted warehouse queries.

## Application composition

```text
main.dart
  -> bootstrap.dart
  -> Supabase and environment initialization
  -> ProviderScope
  -> App
  -> GoRouter
  -> feature screens
```

- `lib/main.dart` is the application entry point.
- `lib/bootstrap.dart` initializes Flutter, environment variables, Supabase, logging, and system configuration.
- `lib/app/app.dart` configures `MaterialApp.router`, theme, locale, and router.
- `lib/app/router/` owns routes and navigation guards.
- `lib/app/theme/` owns application theme and colors.

## Feature architecture

Each feature follows this flow:

```text
Screen / Widget
      |
      v
Riverpod Controller or ViewModel
      |
      v
Use Case
      |
      v
Domain Repository Contract
      ^
      |
Repository Implementation
      |
      v
Remote or Local Data Source
      |
      v
Supabase / cache / device capability
```

Dependencies point toward the domain layer. Presentation does not depend directly on Supabase. Data implements domain repository contracts.

## Directory responsibilities

```text
lib/
├── app/        app composition, router, theme
├── core/       errors, network, shared technical services and widgets
└── features/   business features with data/domain/presentation boundaries
```

Feature layout:

```text
lib/features/<feature>/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── controllers/
    ├── screens or widgets/
    └── widgets/
```

The current project uses Riverpod controllers. They are the feature state owners and may be gradually renamed or reorganized as view models without changing the state-management package.

## Request and error lifecycle

1. A screen invokes a controller method or watches a provider.
2. The controller calls a domain use case.
3. The use case calls a repository contract.
4. The repository implementation calls a data source.
5. The data source communicates with Supabase and parses transport data.
6. Failures are mapped to the project's `Failure` types.
7. The controller exposes an `AsyncValue` or typed feature state.
8. The UI renders loading, data, empty, or localized error states.

## Authentication and routing

Supabase Auth is the source of truth for the current session. Routing should eventually use an auth session service/provider to redirect unauthenticated users to `/login` and authenticated users to the main shell. Role checks belong in a reusable authorization layer, not duplicated across screens.

## Realtime and device workflows

- Inventory realtime subscriptions belong in a dedicated inventory service/controller with explicit cleanup.
- Barcode/QR scanning belongs to inbound/outbound presentation and domain use cases; scanner widgets should not contain stock mutation rules.
- OCR extracts values at the device/data boundary. Validation and business decisions remain in domain use cases.
- Offline cache and queue are future infrastructure concerns and should be added only after the online workflows are stable.

## AI assistant flow

```text
AiChatScreen
  -> AiChatController
  -> ParseIntentUseCase
  -> QueryStockUseCase or another intent handler
  -> AiAssistantRepository
  -> Supabase Edge Function / backend
```

The assistant must not directly mutate inventory without a domain use case and an explicit confirmation flow.
