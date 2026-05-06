# CampusConnect

Recruiter-level Flutter + Firebase campus super-app architecture.

## Stack

- Flutter (Material 3, light/dark mode)
- Firebase Auth
- Cloud Firestore
- Firebase Storage (optional; currently disabled for free-tier mode)
- Firebase Cloud Messaging
- Firebase Analytics

## Features

- College-email authentication with verification and allowed-domain list
- Home feed with mixed content cards
- Marketplace with status, search and price filters (image upload toggle supported)
- Events with registration and reminder notifications
- Lost & Found board
- Student jobs board
- 1:1 chat (Firestore subcollection messages)
- Profile with reputation, listings and ratings hooks
- Report spam workflow
- Admin moderation panel (ban user, approve event, remove spam)

## Setup

1. Install Flutter and Firebase CLI.
2. In project root run:
   - `flutter pub get`
   - `flutterfire configure --project=myflutterapplication-a1ddf --platforms=web,windows --yes`
3. Validate generated config in `lib/firebase_options.dart`.
4. Deploy rules and indexes:
   - `firebase deploy --project myflutterapplication-a1ddf --only firestore:rules,firestore:indexes`
5. Run app (web):
   - `flutter run -d chrome --dart-define=FLUTTER_WEB_USE_SKIA=false`
6. Run app (windows):
   - Enable Developer Mode in Windows settings
   - `flutter run -d windows`

## Firestore Design

Collections used:

- `users/{uid}`
- `marketplace/{postId}`
- `events/{eventId}`
- `lost_found/{id}`
- `jobs/{jobId}`
- `chats/{chatId}/messages/{msgId}`
- `ratings/{ratingId}`
- `reports/{reportId}`

## Notes

- Architecture and state-management documentation: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- College domains are configurable in `lib/core/constants/app_constants.dart`.
- Event approval and anti-spam moderation are admin-gated.
- Push notifications are scaffolded for topic and local reminder usage.
- Stream errors are surfaced in-module (no infinite loaders on failed queries).
- Free-tier mode is enabled by default: `enableFirebaseStorageUploads = false`.
