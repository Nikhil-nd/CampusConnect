# CampusConnect — DoD Implementation Guide

A file-by-file reference showing **where each DoD criterion is implemented,
what the code does, and how it flows at runtime.**

---

## 1. FUNCTIONAL COMPLETENESS

### Core Features

| Feature | Primary Screen | Service Method |
|---|---|---|
| Marketplace (buy/sell) | `lib/screens/marketplace/marketplace_screen.dart` | `FirestoreService.watchMarketplace()` L53 |
| Events (register/create) | `lib/screens/events/events_screen.dart` | `FirestoreService.watchEvents()` L84 |
| Jobs board | `lib/screens/jobs/jobs_screen.dart` | `FirestoreService.watchJobs()` L140 |
| Lost & Found | `lib/screens/lostfound/lostfound_screen.dart` | `FirestoreService.watchLostFound()` L126 |
| Real-time Chat | `lib/screens/chat/chat_screen.dart` + `chat_list_screen.dart` | `FirestoreService.watchMessages()` L310 |
| Admin Moderation | `lib/screens/admin/admin_panel_screen.dart` | `FirestoreService.watchReports()` L189 |

**How it flows:**
Every feature uses a `StreamBuilder` connected to a Firestore `watch*()` stream.
When data changes in Firestore, the stream emits, `StreamBuilder` rebuilds only
the relevant widget subtree — not the full page.

### Feature Integration

All features share **one `FirestoreService`** instance (registered as a Provider in
`lib/main.dart` L95). No feature talks to Firestore directly — they all go through
`FirestoreService`. This makes the features interconnected:

- A new marketplace item triggers the feed on `HomeScreen`.
- Registering for an event updates `registeredUsers` array in the same document
  already displayed on the events list — no extra fetch needed.
- Chat IDs are deterministic (`sorted UIDs joined by _`) so two users always
  reuse the same thread (`FirestoreService.createOrGetChat()` L252–L285).

### Extended Features (2+)

1. **Admin Panel + Moderation** — `lib/screens/admin/admin_panel_screen.dart`
   Admins can approve/reject events, resolve spam reports, and ban users.
   Gate: `UserModel.isAdmin` field checked before rendering admin nav entry.

2. **Scheduled Event Reminders** — `lib/services/notification_service.dart` L74
   `scheduleEventReminder()` uses `flutter_local_notifications` with timezone-aware
   `zonedSchedule()`. Falls back to inexact alarm if exact-alarm permission is denied.

3. **Reputation/Rating System** — `FirestoreService.addRating()` L163
   After a marketplace transaction, buyer can rate the seller. Ratings stored in
   a separate `ratings` collection, linked by `sellerId`.

---

## 2. EDGE CASES HANDLING

### Empty States
**File:** `lib/widgets/empty_state.dart` (entire file, 54 lines)

`EmptyState` is a reusable widget rendered by every screen's `StreamBuilder`
when `snapshot.data` is an empty list. It accepts optional `icon`, `subtitle`,
and `actionLabel`/`onAction` so each screen customises the message.

**Flow:** `StreamBuilder` → `data.isEmpty` → `EmptyState(title: '...', icon: ...)`

### No Internet
**File:** `lib/widgets/offline_banner.dart`

- `_initializeConnectivity()` (L163) — checks status on app start.
- `onConnectivityChanged` stream (L28) — reacts to changes in real time.
- `_hasInternetRoute()` (L33) — triple-checks via TCP socket + HTTPS probe
  before declaring offline, preventing false positives on captive portals.
- Banner shown as `AnimatedContainer` collapsing to `height: 0` when online,
  expanding with `MediaQuery.padding.top` offset when offline.

### Invalid Input
**File:** `lib/core/utils/validators.dart`

- `requiredText()` L25 — empty field guard used on all form fields.
- `positiveNumber()` L32 — price validation for marketplace posts.
- `isCollegeEmailInDomains()` L10 — rejects non-college emails at signup
  before even calling Firebase, throwing a custom `FirebaseAuthException`
  with code `invalid-email-domain`.

---

## 3. UI/UX — CUSTOM DESIGN SYSTEM

### Color System + Typography Hierarchy
**File:** `lib/core/theme/app_theme.dart`

- `AppTheme.seed` (L49) = `Color(0xFF0B7285)` — one seed color drives the
  entire Material 3 `ColorScheme.fromSeed()` for both light and dark.
- `AppSemanticColors` (L4–L44) — a custom `ThemeExtension` adding four
  semantic slots: `success`, `warning`, `info`, `surfaceTint`. Used
  via `Theme.of(context).extension<AppSemanticColors>()`.
- `_textTheme()` (L64–L78) — full scale from `displayLarge` (57px/700w)
  down to `labelLarge` (14px/600w), all with explicit `height` line-height.
- `AppBarTheme`, `CardThemeData`, `InputDecorationTheme`,
  `NavigationBarThemeData`, `SnackBarThemeData`, `FilledButtonThemeData`
  — all customised so no screen needs ad-hoc overrides.

### Reusable Widgets (3+)

| Widget | File | Purpose |
|---|---|---|
| `EmptyState` | `lib/widgets/empty_state.dart` | Empty list / no-data state |
| `AppSearchField` | `lib/widgets/app_search_field.dart` | Search input with icon, used on Marketplace + Jobs + Events |
| `CampusHeroHeader` | `lib/widgets/campus_hero_header.dart` | Gradient header with semantic-colour chips on Home |
| `AppBottomNavBar` | `lib/widgets/app_bottom_nav_bar.dart` | Shared bottom nav for all 5 tabs |
| `OfflineBannerShell` | `lib/widgets/offline_banner.dart` | App-wide offline notification |
| `ReportsTrendChart` | `lib/widgets/insights/reports_trend_chart.dart` | Custom-painted bar chart |

### Micro-interactions

1. **Offline banner slide** — `AnimatedContainer` height animates from `0` → auto
   on disconnect (`lib/widgets/offline_banner.dart` build method).
2. **Navigation indicator** — Material 3 `NavigationBar` pill indicator animates
   between tabs via `NavProvider.setIndex()` → `IndexedStack` swap.
3. **Marketplace sort toggle** — `FeedProvider.togglePriceSort()` triggers
   a `notifyListeners()` which re-sorts and rebuilds only the list widget.

---

## 4. STATE MANAGEMENT

### Provider (ChangeNotifier)

| Provider | File | Owns |
|---|---|---|
| `AuthProvider` | `lib/providers/auth_provider.dart` | Firebase auth session, `isReady`, `isLoggedIn`, `isEmailVerified` |
| `FeedProvider` | `lib/providers/feed_provider.dart` | Search query string + marketplace sort direction |
| `NavProvider` | `lib/providers/nav_provider.dart` | Bottom nav selected index |

**Layer separation:**
- `AuthService` (`lib/services/auth_service.dart`) — raw Firebase calls only.
- `AuthProvider` (`lib/providers/auth_provider.dart`) — session state + calls
  `FirestoreService.upsertUserProfile()` on signup. If Firestore write fails,
  it **deletes the Firebase Auth user** (L52–54) to keep state consistent.
- UI screens call `context.watch<AuthProvider>()` — never `FirebaseAuth` directly.

### Bloc (SearchCubit)

**File:** `lib/providers/search_cubit.dart`

`SearchCubit extends Cubit<String>` — simplest possible Bloc unit.
`updateQuery(String)` emits the new query; screens wrap lists in
`BlocBuilder<SearchCubit, String>` to re-filter without touching Provider.
Registered in `main.dart` L111 via `BlocProvider`.

### No setState Misuse

`HomeShellScreen` (`lib/screens/home/home_shell_screen.dart`) is `StatelessWidget`.
`NavProvider.setIndex()` drives tab switches — no `setState` in the shell.
Screens that manage form input (login, signup) use `StatefulWidget` only for
`TextEditingController` and `GlobalKey<FormState>` — appropriate use.

### State Flow (Auth)

```
Firebase.initializeApp()
  └─ AuthProvider() constructor
       └─ authStateChanges().listen()
            ├─ user != null → RootGate shows HomeShellScreen
            ├─ user != null, email unverified → EmailVerificationScreen
            └─ user == null → LoginScreen
```

Defined in `lib/main.dart` `RootGate` widget (L150–L174).

---

## 5. BACKEND & DATA HANDLING

### Authentication
**Files:** `lib/services/auth_service.dart`, `lib/providers/auth_provider.dart`

- College-email domain allowlist enforced at `AuthService.signUpWithCollegeEmail()` L17.
- Email verification sent at signup (L29); `EmailVerificationScreen` polls
  `reloadUser()` until `emailVerified == true`.
- Password reset via `forgotPassword()` L43.

### Firestore Integration
**File:** `lib/services/firestore_service.dart`

Collections: `users`, `marketplace`, `events`, `jobs`, `lost_found`, `chats`,
`chats/{id}/messages`, `reports`, `ratings`.

All reads use **real-time streams** (`snapshots()`), not one-shot `get()`.
Writes use `add()` or `set(..., merge: true)` — never blind overwrites.
`sendMessage()` (L319) uses a `WriteBatch` to atomically write the message
and update `lastMessage` on the chat document in one round-trip.

### Data Modeling
**Directory:** `lib/models/`

Every model has:
- `const` constructor with typed, required fields.
- `factory fromMap(Map<String, dynamic>, String id)` with safe null-coalescing (`?? default`).
- `toMap()` returning typed `Map<String, dynamic>`.
- Firestore `Timestamp` ↔ `DateTime` conversion in every model that stores dates.

Example — `UserModel` (`lib/models/user_model.dart`):
Fields: `uid`, `name`, `email`, `branch`, `year`, `profilePic`,
`reputation`, `isAdmin`, `isBanned`, `createdAt`.

### Offline Handling
**File:** `lib/widgets/offline_banner.dart`

Firestore SDK caches the last-seen snapshot on-device automatically.
`StreamBuilder` continues to show cached data; the `OfflineBannerShell`
tells users they are offline and that content shown is cached.
No extra offline-specific code needed — Firestore persistence handles it.

---

## 6. CUSTOM LOGIC

### Event Approval Workflow
**File:** `lib/services/firestore_service.dart` L84–L114

`watchEvents()` filters server-side by `date >= now` then client-side:
- If `event.approved == true` → always visible.
- If `approved == false` → only visible to the organizer (`event.organizerId == _uid`).

This means pending events are invisible to other users without any
extra security rule complexity.

### Deterministic Chat ID
**File:** `lib/services/firestore_service.dart` L252–L285

```dart
final List<String> participants = [me, other]..sort();
final String chatId = participants.join('_');
```

Sorting UIDs alphabetically before joining guarantees User A→B and
User B→A always resolve to the same document. No duplicate threads.

### Spam Report System
`reportSpam()` (L172) writes to `reports` collection with `resolved: false`.
Admin panel streams `watchReports(unresolvedOnly: true)` (L189).
`resolveReport()` (L206) flips `resolved: true`.
`watchPendingEvents()` (L223) feeds the admin's approval queue separately.

### College Email Domain Validation
**File:** `lib/core/utils/validators.dart` + `lib/core/constants/app_constants.dart`

`AppConstants.allowedCollegeEmailDomains` (L6) lists permitted domains.
`Validators.isCollegeEmailInDomains()` (L10) checks regex + domain suffix.
Thrown as `FirebaseAuthException(code: 'invalid-email-domain')` so the
existing auth-error mapping in `lib/core/utils/auth_error_message.dart` shows
a user-friendly message.

---

## 7. DATA VISUALIZATION

### Reports Trend Chart
**File:** `lib/widgets/insights/reports_trend_chart.dart`
**Screen:** `lib/screens/admin/insights_screen.dart`

**How it works:**
1. `_lastNDays(7)` generates the last 7 date keys.
2. `watchReports(unresolvedOnly: false)` streams all reports.
3. Reports are bucketed by `createdAt` date key into a `Map<String, int>`.
4. `_BarChartPainter` (L101–L129) is a `CustomPainter` that draws rounded
   bars scaled to `maxValue`, with a `gap` of 6px between bars.
5. Insight text (L59–L73) computes the % change between the last 3 days
   and the previous 4 days and prints "Increasing / Decreasing / Stable".

**What insight does this give?**
Moderators can see at a glance whether spam is spiking (needs action) or
falling (moderation is working) without reading individual reports.

---

## 8. TESTING

### Widget Tests
**Directory:** `test/`

| File | Tests |
|---|---|
| `test/screens/auth/login_screen_test.dart` | 3 tests — renders fields, renders Login button, shows Create Account + Forgot Password links |
| `test/widgets/empty_state_test.dart` | Tests EmptyState renders title, subtitle, icon, action button |
| `test/widgets/app_search_field_test.dart` | Tests AppSearchField renders hint text and fires onChanged |
| `test/widget_test.dart` | Basic smoke test — app renders without crashing |

### How tests work
Each test wraps the widget in `MaterialApp` + `MultiProvider` with real
service instances (no mocks needed for stateless UI tests).
`pumpWidget` → `expect(find.text(...), findsOneWidget)` pattern throughout.

---

## 9. PERFORMANCE

### Efficient Rebuilds

- `IndexedStack` in `HomeShellScreen` (L28) keeps all 5 tab pages alive in memory.
  Switching tabs does **not** re-fetch Firestore data — streams stay open.
- `context.read<>()` used for one-time actions (button taps).
- `context.watch<>()` used only where rebuild on change is needed.
- `StreamBuilder` scoped as low as possible (inside list items, not at screen root).

### Image Optimization

`cached_network_image` package (`pubspec.yaml` L24) wraps all network images.
Images are cached to disk on first load; subsequent renders are instant.

---

## 10. DEPLOYMENT READINESS

### App Icon
**Config:** `pubspec.yaml` L41–L45
```yaml
flutter_launcher_icons:
  android: true
  image_path: web/icons/Icon-512.png
```
Run `flutter pub run flutter_launcher_icons` → generates all mipmap densities.

### Splash Screen
**Config:** `pubspec.yaml` L47–L52
```yaml
flutter_native_splash:
  color: "#0175C2"
  image: web/icons/Icon-512.png
```
Run `flutter pub run flutter_native_splash:create`.

### App Name
`AppConstants.appName = 'CampusConnect'` (`lib/core/constants/app_constants.dart` L4)
Used as `MaterialApp.title` in `main.dart` L114.
Android label set in `android/app/src/main/AndroidManifest.xml`.

### Notification Integration (FCM)
`NotificationService` (`lib/services/notification_service.dart`) subscribes to
FCM topics `events` and `marketplace` (L70–71) and handles foreground messages
via `FlutterLocalNotificationsPlugin` on channel `campusconnect_channel`.

---

## 11. PROJECT STRUCTURE

```
lib/
├── core/
│   ├── constants/app_constants.dart   ← App-wide string/list constants
│   ├── theme/app_theme.dart           ← Design system (colors, typography)
│   └── utils/
│       ├── auth_error_message.dart    ← Firebase error code → human message
│       └── validators.dart            ← Pure validation functions
├── models/                            ← 8 typed data models
├── providers/                         ← AuthProvider, FeedProvider, NavProvider, SearchCubit
├── routes/app_router.dart             ← Centralized named-route map
├── screens/                           ← 9 feature folders, each self-contained
├── services/                          ← AuthService, FirestoreService, NotificationService, StorageService, AnalyticsService
└── widgets/                           ← 6 shared reusable widgets + insights/
```

### Naming Consistency

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Provider methods: verb-first camelCase (`setIndex`, `togglePriceSort`, `updateQuery`)
- Firestore collections: `snake_case` (`lost_found`, `marketplace`)
- Route constants: `AppRouter.login`, `AppRouter.signup`, etc.

---

## 12. GITHUB & DOCUMENTATION

### README (`README.md`)
- Setup instructions (Firebase config, run commands)
- Feature list
- Screenshots section

### Firestore Rules (`firebase/firestore.rules`)
- Authenticated reads/writes enforced.
- Admin-only write paths for `events.approved`, `users.isBanned`.

### Architecture Doc (`docs/ARCHITECTURE.md`)
- Layer diagram, data flow, state management explanation.

### Report (`report.md`)
- Problem understanding, feature justification, architecture diagram,
  state management walkthrough, challenges, AI usage disclosure.

### DoD Validation (`DoD_VALIDATION.md`)
- Checklist form of this guide for quick review.

### Testing Guide (`TESTING.md`)
- Manual test scenarios (happy path + edge cases).
- Widget test run instructions.

---

## QUICK LOOKUP TABLE

| DoD Criterion | Primary File(s) | Key Line(s) |
|---|---|---|
| Core features | `lib/screens/*/` + `firestore_service.dart` | All `watch*()` methods |
| Feature integration | `lib/main.dart` + `firestore_service.dart` | L92–L145 (MultiProvider) |
| Extended features | `admin_panel_screen.dart`, `notification_service.dart` | L74 (reminders) |
| Edge cases — empty | `lib/widgets/empty_state.dart` | Full file |
| Edge cases — offline | `lib/widgets/offline_banner.dart` | L33, L163, build() |
| Edge cases — invalid input | `lib/core/utils/validators.dart` | L10, L25, L32 |
| Custom design system | `lib/core/theme/app_theme.dart` | L4–L179 |
| Reusable widgets | `lib/widgets/*.dart` | All 6 widget files |
| Micro-interactions | `offline_banner.dart`, `home_shell_screen.dart` | AnimatedContainer, IndexedStack |
| Provider usage | `lib/providers/auth_provider.dart` | L10–L84 |
| Bloc usage | `lib/providers/search_cubit.dart` | Full file |
| Layer separation | `services/` vs `providers/` vs `screens/` | Architecture |
| No setState misuse | `lib/screens/home/home_shell_screen.dart` | StatelessWidget |
| Authentication | `lib/services/auth_service.dart` | L13–L31 |
| Database integration | `lib/services/firestore_service.dart` | All methods |
| Data modeling | `lib/models/*.dart` | `fromMap`, `toMap` in each |
| Offline handling | `lib/widgets/offline_banner.dart` | L33–L91 |
| Custom logic | `firestore_service.dart` | L84–L114, L252–L285 |
| Originality | Admin panel + chat + notification + rating system | Multiple files |
| Data visualization | `lib/widgets/insights/reports_trend_chart.dart` | L101–L129 |
| Insight explanation | `lib/screens/admin/insights_screen.dart` | L20–L27 |
| Widget tests | `test/screens/auth/login_screen_test.dart` | 3 test cases |
| Widget tests | `test/widgets/empty_state_test.dart` | Multiple cases |
| Widget tests | `test/widgets/app_search_field_test.dart` | Multiple cases |
| Efficient rendering | `home_shell_screen.dart` | IndexedStack L28 |
| App branding | `pubspec.yaml` L41–L52 | flutter_launcher_icons |
| Naming consistency | `lib/core/constants/app_constants.dart` | L4 |
| Project structure | `lib/` directory tree | All folders |
| Commit clarity | `.git/` | See git log |
| README | `README.md` | Full file |
| Problem & scope | `report.md` | Section 1 |
| Architecture design | `docs/ARCHITECTURE.md` | Full file |
| Feature justification | `report.md` | Section 2 |
| Custom logic explanation | `report.md` | Section 4 |
| Challenges & learning | `report.md` | Section 6 |
| AI usage transparency | `report.md` | Section 7 |
| Manual contribution | Validators, deterministic chat ID, approval logic | See Section 5 above |
