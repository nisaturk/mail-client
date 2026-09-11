# REST API Specification

## 1. Authentication & Admin
* `POST /api/auth/register` — Self-service registration[cite: 2].
* `POST /api/auth/login` — Authenticates user and returns JWT token[cite: 2].
* `GET /api/admin/users` — Admin list of all users[cite: 2].
* `POST /api/admin/users` — Admin user creation[cite: 2].
* `PATCH /api/admin/users/{id}/approve` — Approves pending registrations[cite: 2].
* `PATCH /api/admin/users/{id}/disable` — Disables user access[cite: 2].
* `PATCH /api/admin/users/{id}/enable` — Enables user access[cite: 2].
* `POST /api/admin/users/{id}/reset-password` — Resets user password[cite: 2].

## 2. Mail Accounts
* `GET /api/mail-accounts` — List all connected email accounts for current user[cite: 2].
* `POST /api/mail-accounts` — Add new IMAP/SMTP account configuration[cite: 2].
* `GET /api/mail-accounts/{id}` — Get single account details[cite: 2].
* `PUT /api/mail-accounts/{id}` — Update account details[cite: 2].
* `DELETE /api/mail-accounts/{id}` — Delete connected account[cite: 2].
* `POST /api/mail-accounts/{id}/test` — Tests IMAP/SMTP connections without sending an email[cite: 2].

## 3. Folders & Mail Listing
* `GET /api/mail-accounts/{id}/folders` — Retrieve account folder structure[cite: 2].
* `GET /api/mails?folderType=Inbox&page=1&pageSize=30` — Query Unified Inbox[cite: 2].
* `GET /api/mails?accountId={id}&folderType=Inbox&page=1&pageSize=30` — Query specific account Inbox[cite: 2].
* `GET /api/mails?folderType=Sent&page=1&pageSize=30` — Query Unified Sent items[cite: 2].
* `GET /api/mails?folderId={id}` — Query specific folder items[cite: 2].

## 4. Mail Details & Actions
* `GET /api/mails/{id}` — Fetch detailed content of a single email[cite: 2].
* `PATCH /api/mails/{id}/read` — Update read/unread state (triggers two-way IMAP flag sync)[cite: 2].
* `GET /api/mails/{id}/attachments/{attachmentId}` — Download email attachment[cite: 2].
* `POST /api/mail-accounts/{accountId}/send` — Send email from selected account (handles optional Sent folder append)[cite: 2].

## 5. FCM Push Devices
* `POST /api/devices/register` — Registers device push token (`pushToken`, `platform`) linked to current JWT user[cite: 2].