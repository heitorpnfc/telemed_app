# Plan: Automatic Dashboard Refresh via FCM Push Notifications

This plan details the implementation for real-time, automatic Dashboard updates in the Flutter app (`telemed_app`) triggered whenever an event occurs on the IoT Box (Raspberry Pi 3B+) and a Firebase Cloud Messaging (FCM) push notification is received.

## User Review Required

> [!IMPORTANT]
> **Server Synchronization:** This feature relies on the backend (`core_api` FCM worker) sending FCM push notifications to the user's registered device token whenever a telemetry event (e.g. compartment opened, medicine taken/missed) is recorded.
> **Foreground Behavior:** When a push notification arrives while the user is looking at the Dashboard, the app will silently fetch the latest data from the backend and refresh the UI in real-time, showing an optional Toast/SnackBar notifying the user of the new telemetry event.

---

## Proposed Changes

### Mobile Application (`telemed_app`)

#### [MODIFY] [home_page.dart](file:///home/stephan/Documents/telemed_app/lib/pages/home_page.dart)

- **Import `firebase_messaging`:** Add `import 'package:firebase_messaging/firebase_messaging.dart';`
- **Stream Subscriptions:** Add `StreamSubscription<RemoteMessage>? _fcmForegroundSubscription;` and `StreamSubscription<RemoteMessage>? _fcmOpenedSubscription;` to `_HomePageState`.
- **Initialization (`initState`):**
  - Listen to `FirebaseMessaging.onMessage` (foreground notifications):
    - Trigger `_loadData()` automatically.
    - Increment `_dashboardKey` to force a clean widget rebuild.
    - Show a subtle SnackBar (e.g. *"Novo evento da caixinha recebido! Dashboard atualizado."*).
  - Listen to `FirebaseMessaging.onMessageOpenedApp` (user tapped notification in system tray):
    - Trigger `_loadData()` to ensure freshest data upon resuming.
- **Cleanup (`dispose`):**
  - Cancel both FCM stream subscriptions to prevent memory leaks.

---

## Verification Plan

### Automated Verification
- Run `flutter analyze` inside `telemed_app` to verify zero static analysis errors or warnings regarding stream subscriptions and lifecycle management.

### Manual Verification
1. Open the app on an Android device or emulator with `HomePage` visible.
2. Send a test FCM data message (via Firebase Console or `POST /users/me/fcm-token` backend trigger).
3. Confirm that `_loadData()` is executed automatically without restarting the app or manual pulling, and the adherence metrics / logs refresh live on screen.
