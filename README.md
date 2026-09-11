# flapmail

A Flutter mail client app. The app acts as a UI client that talks to a REST backend; IMAP/SMTP handling lives server-side, not on the device.

## Features

- Multi-account email management (single generic mail inbox)
- Mail list, detail, compose, and attachment views
- Admin approval flow for new accounts
- Tag-based organization

## Architecture

- `lib/presentation/` — UI screens and reusable widgets
- `lib/state/` — Riverpod providers managing API read models and UI state
- `lib/repositories/` — Dio API client and JSON DTO mapping
- `lib/models/` — Data classes (`User`, `MailAccount`, `MailSummary`, `MailDetail`, `Attachment`)

See `docs/` for the API spec and architecture details.

## Getting Started

```bash
flutter pub get
flutter run
```

## License

Released under the [MIT License](LICENSE).