# Architecture

## Three-layer rule

Dependencies always point inward. Outer layers know about inner layers, never the reverse.

```
Presentation  →  Domain  ←  Data
(Flutter/Riverpod)  (Pure Dart)  (Supabase/HTTP)
```

- **Domain**: pure Dart, no Flutter/Supabase imports. Entities, repository interfaces, use cases.
- **Data**: implements domain interfaces. Knows Supabase. No widgets.
- **Presentation**: knows Flutter and Riverpod. Calls use cases via providers. Never imports Supabase directly.

## Feature-first folder structure

```
mobile/lib/
├── main.dart
├── app.dart                        ← ProviderScope + MaterialApp.router
├── core/
│   ├── supabase/supabase_client.dart + supabase_provider.dart
│   ├── router/app_router.dart + app_routes.dart
│   ├── theme/app_theme.dart + app_colors.dart
│   ├── error/app_exception.dart + failure.dart
│   └── utils/extensions.dart
├── features/
│   ├── auth/domain/ data/ presentation/
│   ├── jobs/domain/ data/ presentation/
│   ├── profile/
│   ├── agent/
│   └── offers/
└── shared/widgets/ models/
```

Each feature: `domain/entities/`, `domain/repositories/` (interfaces), `domain/usecases/`, `data/models/`, `data/datasources/`, `data/repositories/` (impls), `presentation/screens/`, `presentation/widgets/`, `presentation/providers/`.

## Data flow

```
Supabase DB → RemoteDatasource (models) → RepositoryImpl (entities) → UseCase → AsyncNotifier → ConsumerWidget
```

Models (data layer): map 1:1 to Supabase JSON, have `fromJson`/`toJson`, convert to entities via `toEntity()`.
Entities (domain layer): pure Dart, immutable, no JSON knowledge.

## Riverpod patterns

**Repository provider:**
```dart
@riverpod
JobsRepository jobsRepository(Ref ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return JobsRepositoryImpl(JobsRemoteDatasource(supabase));
}
```

**AsyncNotifier (standard pattern):**
```dart
@riverpod
class JobsNotifier extends _$JobsNotifier {
  @override
  Future<List<Job>> build() async {
    _subscribeToRealtime();
    ref.onDispose(() => _subscription?.cancel());
    return ref.watch(jobsRepositoryProvider).fetchOpenJobs();
  }
}
```

**Optimistic updates:**
```dart
final previous = state;
state = AsyncData(updatedList);
try {
  await ref.read(jobsRepositoryProvider).submitOffer(offer);
} catch (e) {
  state = previous;
  rethrow;
}
```

**Realtime — subscribe in providers, never in widgets:**
```dart
_subscription = supabase.from('jobs').stream(primaryKey: ['id']).listen((data) {
  final newJobs = data.map(JobModel.fromJson).map((m) => m.toEntity()).toList();
  if (!_listEquals(state.valueOrNull ?? [], newJobs)) state = AsyncData(newJobs);
});
```

**Provider rules:**
- `autoDispose` on screen-scoped providers (job detail, agent session)
- NO `autoDispose` on global providers (auth, profile) — must persist for app lifetime
- Never call Supabase from a widget — always through a provider
- Use `select()` to prevent unnecessary rebuilds

**Realtime subscriptions:**
- Subscribe to: new Jobs in the feed, Quotes status changes for current musician
- Do NOT subscribe to: profile data, historical offers, admin-only data

## Routing (go_router)

Route names live in `core/router/app_routes.dart` as constants — never use raw path strings.

```dart
abstract class AppRoutes {
  static const login = 'login';
  static const jobs = 'jobs';
  static const jobDetail = 'job-detail';
  static const profile = 'profile';
  static const agent = 'agent';
  static const offers = 'offers';
}
```

- Use `StatefulShellRoute.indexedStack` for bottom nav — keeps each tab's scroll position.
- Auth redirect guard driven by Riverpod auth state, not widget logic.
- Job detail route (`/jobs/:jobId`) must be deep-linkable directly from push notifications.
- Always: `context.goNamed(AppRoutes.jobDetail, pathParameters: {'jobId': id})` — never `context.go('/jobs/123')`.

## Error handling

```dart
sealed class AppException { const AppException(this.message); final String message; }
class NetworkException extends AppException { ... }
class AuthException extends AppException { ... }
class DatabaseException extends AppException { ... }
class AgentException extends AppException { ... }
```

Use `AsyncValue.guard()` in notifiers. Widgets handle error state declaratively — no try/catch in `build()`.

## Naming conventions

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/functions: `camelCase`
- Providers: `jobsProvider`, `agentProvider`, `authProvider`
