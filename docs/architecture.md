# App Architecture & State Guidelines

## Core Principles
* **Client Role:** Flutter acts strictly as a UI client using REST APIs[cite: 2]. No IMAP/SMTP protocols or packages (e.g., MailKit) are implemented on the Flutter side[cite: 2].
* **Source of Truth:** IMAP servers serve as the authoritative state; PostgreSQL acts as the server-side cache/read model[cite: 2].
* **Security:** Mail passwords are managed on the backend and are never stored on the mobile device[cite: 2]. JWT tokens are stored securely on the device[cite: 2].

## Layer Structure (`lib/`)
* `presentation/`: UI screens, navigation, and reusable widgets[cite: 2].
* `state/`: Riverpod providers/notifiers managing REST API read models and UI states[cite: 2].
* `repositories/`: Dio API client implementations and JSON DTO mapping[cite: 2].
* `models/`: Data classes (`User`, `MailAccount`, `MailSummary`, `MailDetail`, `Attachment`)[cite: 2].
* `platform/`: Firebase messaging, local notifications, secure storage, and file picker integrations[cite: 2].

## Authentication & Authorization
* **Token Storage:** JWT stored inside `flutter_secure_storage`[cite: 2].
* **Dio Interceptor:** Every request automatically appends `Authorization: Bearer <token>`[cite: 2].
* **Session Lifecycle:** A `401 Unauthorized` response triggers session clearance and navigates the user back to the login screen[cite: 2].
* **Account Status:** Users with a `Pending` status are redirected to an approval waiting screen instead of the mailbox UI[cite: 2].