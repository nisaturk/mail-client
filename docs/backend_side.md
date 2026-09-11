# Posta Köprüsü — Revised Multi-Account Mail Client Implementation Plan

> **Status:** Revised master plan  
> **Target:** Thunderbird-like, server-backed multi-account email client  
> **Backend:** ASP.NET Core / .NET 10  
> **Client:** Flutter  
> **Mail protocols:** IMAP + SMTP via MailKit/MimeKit  
> **Primary push:** Firebase Cloud Messaging  
> **Database:** PostgreSQL + EF Core  
> **Attachment storage:** Local server filesystem first  
> **Realtime strategy:** 30-second polling first; IMAP IDLE deferred  
> **Supersedes:** Previous single-mailbox MVP plan

---

## 1. Product Goal

Build a customer-facing email client where:

- A user can create an application account and log in.
- An admin can also create, approve, disable, or reactivate users.
- A user can connect multiple existing email accounts such as:
  - `ahmet@tekyazilim.com`
  - `destek@tekyazilim.com`
  - `muhasebe@baskafirma.com`
- Each connected mail account has its own IMAP/SMTP configuration.
- Flutter never connects directly to IMAP or SMTP.
- ASP.NET Core is the only component that talks to hosting mail servers.
- IMAP is authoritative for mailbox state.
- PostgreSQL acts as the application cache/read model/index.
- The first synced folders are Inbox and Sent.
- The data model must support Drafts, Trash, Junk, Archive, and custom folders later without redesigning the schema.
- Read/unread state is synchronized in both directions.
- Sending mail behaves like a normal desktop mail client:
  - SMTP performs the send.
  - The MIME message is appended to Sent via IMAP when the account is configured to save a sent copy.
- Incoming attachments and inline MIME resources are stored on the server filesystem.
- FCM is the primary notification mechanism.
- Android periodic polling is available only as an explicit fallback mode.
- SignalR, Redis, Hangfire, IMAP IDLE, OAuth2 mail login, and distributed workers are out of scope for this version.

---

## 2. Architectural Principles

### 2.1 High-level architecture

```text
                              ┌─────────────────────────┐
                              │   Hosting Mail Server   │
                              │       IMAP / SMTP       │
                              └────────────┬────────────┘
                                           │
                                           │ MailKit / MimeKit
                                           ▼
┌───────────────────┐             ┌──────────────────────┐
│      Flutter      │◄───────────►│ ASP.NET Core / .NET │
│                   │    REST/JWT │          10          │
│ - Auth            │             │                      │
│ - Accounts        │             │ - API                │
│ - Inbox/Sent      │             │ - IMAP sync worker   │
│ - Compose         │             │ - SMTP sender        │
│ - Notifications   │             │ - FCM                │
└─────────▲─────────┘             └──────┬────────┬──────┘
          │                              │        │
          │ FCM                          │        │
          │                              ▼        ▼
          │                         PostgreSQL  Local files
          │                              │        attachments
          └──────── Firebase ─────────────┘
```

### 2.2 Source of truth

```text
IMAP server = authoritative mailbox state
PostgreSQL  = local cache/read model
Flutter     = client of our REST API
```

For example:

```text
Flutter marks mail read
        ↓
Backend writes IMAP \Seen
        ↓
Backend updates local DB

External webmail marks mail unread
        ↓
IMAP flags change
        ↓
Flag reconciliation
        ↓
Local DB becomes unread
        ↓
Flutter sees updated state
```

### 2.3 User account and mail account are different concepts

The application's login identity is independent from connected mailbox identities.

Example:

```text
Application User
  email: user.login@example.com

Connected Mail Accounts
  - ahmet@tekyazilim.com
  - destek@tekyazilim.com
  - muhasebe@another-company.com
```

Do not assume `User.Email == MailAccount.EmailAddress`.

---

## 3. Explicit Decisions

### Product / business

- Multi-account support is required.
- There is no Customer / Organization / Tenant entity.
- Each application `User` is the ownership boundary.
- Self-service registration is supported.
- Admin-created users are supported.
- Registration defaults to approval-required.
- Admins manage users but do not automatically gain permission to read user mail bodies, attachments, or mailbox credentials.

### Backend

- .NET 10 remains the target.
- Clean Architecture project split remains:
  - `Api`
  - `Application`
  - `Domain`
  - `Infrastructure`
- Application must not reference Infrastructure.
- Infrastructure may implement Application interfaces.
- Do not add generic repositories or Unit of Work just to wrap EF Core.
- Infrastructure services may use `AppDbContext` directly.

### Mail protocol

- IMAP/SMTP security is configurable:
  - `None`
  - `SslOnConnect`
  - `StartTls`
- `None` is allowed only for local/test systems such as GreenMail.
- Production accounts must use TLS.
- New-mail polling begins at 30 seconds.
- IMAP IDLE is deferred.
- Initial sync folders:
  - Inbox
  - Sent
- Folder model is generic from day one.

### Attachments

- Incoming attachments are persisted.
- Inline MIME resources are persisted.
- Storage abstraction remains simple:
  - `IFileStorage`
  - `LocalFileStorage`
- No S3/Azure/MinIO in the first implementation.
- DB stores metadata and path only; never base64 blobs.

### Notifications

- FCM is primary.
- Workmanager periodic polling is fallback only.
- Both notification modes must not run simultaneously.
- SignalR is not used in this plan.

---

## 4. Revised Domain Model

```text
User
│
├── DeviceToken
│
└── MailAccount
     │
     ├── MailFolder
     │     └── SyncState
     │
     └── Mail
           └── Attachment
```

### 4.1 User

```csharp
User
- Id : Guid
- Email : string
- PasswordHash : string
- DisplayName : string
- Role : UserRole
- Status : UserStatus
- CreatedAt : DateTime
- LastLoginAt : DateTime?
```

Enums:

```text
UserRole
- User
- Admin

UserStatus
- Pending
- Active
- Disabled
```

Constraints:

- Unique index on normalized email.
- Only `Active` users may log in.
- Admin-created users may be created directly as Active or Pending according to endpoint intent.
- Passwords are hashed, never encrypted or stored plaintext.

### 4.2 MailAccount

```csharp
MailAccount
- Id : Guid
- UserId : Guid
- EmailAddress : string
- DisplayName : string
- Username : string
- EncryptedPassword : string

- ImapHost : string
- ImapPort : int
- ImapSecurity : MailSecurity

- SmtpHost : string
- SmtpPort : int
- SmtpSecurity : MailSecurity

- SaveSentCopy : bool
- IsActive : bool
- CreatedAt : DateTime
- UpdatedAt : DateTime
```

`MailSecurity`:

```text
None
SslOnConnect
StartTls
```

Notes:

- `SaveSentCopy` defaults to `true`.
- Account credentials are encrypted at rest.
- The user can edit or deactivate their own accounts.
- Do not expose `EncryptedPassword` through DTOs.
- Admin endpoints may expose technical account status but not decrypt credentials.

### 4.3 MailFolder

```csharp
MailFolder
- Id : Guid
- MailAccountId : Guid
- Name : string
- FullName : string
- FolderType : MailFolderType
- UidValidity : uint
- IsSyncEnabled : bool
```

`MailFolderType`:

```text
Inbox
Sent
Drafts
Trash
Junk
Archive
Custom
Unknown
```

Initial behavior:

- Inbox: enabled
- Sent: enabled
- Other discovered folders: persisted but disabled for sync

Folder discovery should prefer IMAP special-use metadata where available and use minimal fallback name matching only when necessary.

### 4.4 SyncState

```csharp
SyncState
- Id : Guid
- MailFolderId : Guid
- UidValidity : uint
- LastUid : uint
- LastNewMailSyncAt : DateTime?
- LastFlagSyncAt : DateTime?
```

Unique index:

```text
MailFolderId
```

Important:

- UIDs are meaningful only within their folder / UIDVALIDITY context.
- If UIDVALIDITY changes, the local sync state for that folder must be treated as invalid and safely reset/rebuilt.

### 4.5 Mail

```csharp
Mail
- Id : Guid
- MailAccountId : Guid
- MailFolderId : Guid

- Uid : uint
- UidValidity : uint
- MessageId : string

- Subject : string
- FromAddress : string
- FromDisplayName : string
- ToAddress : string

- BodyHtml : string
- BodyText : string

- ReceivedAt : DateTime
- IsRead : bool
- HasAttachments : bool
```

Unique index:

```text
(MailFolderId, UidValidity, Uid)
```

Recommended additional index:

```text
(MailAccountId, ReceivedAt)
```

Notes:

- `MessageId` is retained now because it is cheap and useful later for duplicate analysis/threading.
- Threading via `References` / `In-Reply-To` is deferred.

### 4.6 Attachment

```csharp
Attachment
- Id : Guid
- MailId : Guid
- FileName : string
- ContentType : string
- SizeBytes : long
- StoragePath : string
- IsInline : bool
- ContentId : string
```

Do not store file bytes in PostgreSQL.

### 4.7 DeviceToken

```csharp
DeviceToken
- Id : Guid
- UserId : Guid
- Token : string
- Platform : string
- RegisteredAt : DateTime
- LastSeenAt : DateTime?
```

Constraints:

- Token should be unique.
- Device registration obtains `UserId` from JWT, never from request body.

### 4.8 Removed entity

Remove:

```text
SentMail / SentMails
```

Sent mail is represented as a normal `Mail` row in the account's Sent folder.

---

## 5. Security Model

### 5.1 Application passwords

Use one-way password hashing.

Recommended:

- `BCrypt.Net-Next`, or
- ASP.NET Core `PasswordHasher<TUser>`

Do not store application passwords encrypted.

### 5.2 Mailbox credentials

Mailbox passwords must be decryptable by the backend to authenticate to IMAP/SMTP, therefore use encryption-at-rest.

Create:

```csharp
public interface ICredentialProtector
{
    string Protect(string plaintext);
    string Unprotect(string protectedValue);
}
```

Implementation:

```text
ASP.NET Core Data Protection
```

Data Protection key ring:

- must not be committed,
- must survive application restarts,
- must use a persistent server path in production,
- may use an ignored local path in development.

Do not log:

- mailbox password,
- decrypted credentials,
- JWTs,
- Firebase service account content,
- full mail body.

### 5.3 Ownership authorization

Every user-owned resource must be scoped using JWT user identity.

Do not authorize only by resource GUID.

Example:

```text
requested mail
    ↓
Mail.MailAccountId
    ↓
MailAccount.UserId
    ↓
must equal current JWT UserId
```

Apply this rule to:

- mail accounts,
- folders,
- mails,
- attachments,
- device tokens.

### 5.4 Admin boundary

Admin may:

- list users,
- create users,
- approve users,
- disable/enable users,
- initiate/reset password flow,
- inspect non-sensitive account health/status.

Admin must not receive implicit permission to:

- open user mail body,
- download user attachments,
- decrypt mailbox credentials.

Support impersonation is out of scope.

---

# 6. Revised Execution Order

---

## Task 1 — Revise Foundation and Database Schema

### Goal

Replace the old single-mailbox data model with the new user-owned multi-account/folder model before continuing IMAP work.

### Create

```text
Domain/Entities/User.cs
Domain/Entities/MailAccount.cs
Domain/Entities/MailFolder.cs
Domain/Entities/Mail.cs
Domain/Entities/Attachment.cs
Domain/Entities/SyncState.cs
Domain/Entities/DeviceToken.cs

Domain/Enums/UserRole.cs
Domain/Enums/UserStatus.cs
Domain/Enums/MailSecurity.cs
Domain/Enums/MailFolderType.cs
```

### Modify

```text
Infrastructure/Persistence/AppDbContext.cs
Infrastructure/Persistence/Configurations/*
```

### Remove

```text
SentMail entity/table
old single-mailbox assumptions
```

### Required indexes

```text
User.Email                     UNIQUE
DeviceToken.Token              UNIQUE
SyncState.MailFolderId         UNIQUE
Mail(MailFolderId,
     UidValidity,
     Uid)                      UNIQUE
MailAccount(UserId,
            EmailAddress)      recommended UNIQUE
```

### Migration strategy

Before changing migrations, inspect the current repository state.

If the DB only contains disposable local development data, a clean migration reset is acceptable.

If non-disposable data exists, create an additive/transform migration instead.

Do not destroy existing data without explicit confirmation.

### Tests

- entity defaults,
- relationship configuration,
- unique index metadata where practical,
- SentMail no longer exists.

### Acceptance

- build passes,
- migration applies,
- schema matches this plan.

---

## Task 2 — Authentication, Registration, and Admin User Management

### Goal

Build real Users + JWT before user-owned mail-account and FCM APIs.

### Endpoints

```text
POST /api/auth/register
POST /api/auth/login

GET  /api/admin/users
POST /api/admin/users
PATCH /api/admin/users/{id}/approve
PATCH /api/admin/users/{id}/disable
PATCH /api/admin/users/{id}/enable
POST /api/admin/users/{id}/reset-password
```

### Registration configuration

```text
RegistrationMode
- ApprovalRequired   (default)
- Open
- Disabled
```

Behavior:

```text
ApprovalRequired:
register -> Pending -> admin approval -> Active

Open:
register -> Active

Disabled:
public registration rejected
```

### Rules

- only Active users can log in,
- JWT contains stable user identifier and role,
- admin endpoints require Admin role,
- do not use hardcoded admin as the primary auth model,
- a development seed admin is allowed through ignored/local secret configuration.

### Tests

- password hash verifies,
- valid Active user gets JWT,
- Pending/Disabled user cannot log in,
- User cannot call admin endpoints,
- Admin can approve a user.

---

## Task 3 — Credential Protection and Mail Account Management

### Goal

Allow each authenticated user to connect multiple IMAP/SMTP accounts safely.

### Create

```text
Application/Interfaces/ICredentialProtector.cs
Application/Interfaces/IMailAccountService.cs
Infrastructure/Security/DataProtectionCredentialProtector.cs
Infrastructure/Services/MailAccountService.cs
Api/Controllers/MailAccountsController.cs
```

### Endpoints

```text
GET    /api/mail-accounts
POST   /api/mail-accounts
GET    /api/mail-accounts/{id}
PUT    /api/mail-accounts/{id}
DELETE /api/mail-accounts/{id}
POST   /api/mail-accounts/{id}/test
```

### Account request fields

```text
EmailAddress
DisplayName
Username
Password
ImapHost
ImapPort
ImapSecurity
SmtpHost
SmtpPort
SmtpSecurity
SaveSentCopy
```

### Rules

- UserId comes from JWT.
- Password is protected before persistence.
- Password is never returned from GET.
- `None` mail security is rejected outside Development/Test.
- Test endpoint:
  - IMAP connect/authenticate,
  - SMTP connect/authenticate,
  - no mail is sent.
- A failed test must return a useful sanitized error.

### Local GreenMail

`appsettings.Local.json` may contain development-only GreenMail defaults or seed data and must remain git-ignored.

Environment variables/secrets must retain higher priority.

---

## Task 4 — IMAP Folder Discovery

### Goal

Discover server folders for each active account and persist a generic folder model.

### Behavior

On account creation/test activation or explicit refresh:

```text
Connect IMAP
  ↓
List folders
  ↓
Detect special use
  ↓
Persist MailFolder rows
  ↓
Enable Inbox + Sent sync
  ↓
Persist others disabled
```

### Endpoints

```text
GET  /api/mail-accounts/{id}/folders
POST /api/mail-accounts/{id}/folders/refresh
PATCH /api/mail-accounts/{id}/folders/{folderId}/sync
```

The last endpoint may remain internal/disabled in the first UI if only Inbox/Sent are exposed.

### Special folder strategy

Prefer server metadata / MailKit special folders.

Fallback string matching should be minimal and isolated.

Do not hardcode application logic around `"INBOX"` everywhere.

---

## Task 5 — IMAP Background Sync + Incoming Attachments

### Goal

Poll all active mail accounts every 30 seconds and sync new messages for enabled folders.

Initial enabled folders:

```text
Inbox
Sent
```

### Worker

```csharp
MailSyncService : BackgroundService
```

Dependencies:

```text
IServiceScopeFactory
ILogger<MailSyncService>
ICredentialProtector
```

Do not inject scoped `AppDbContext` directly into the hosted singleton.

### Main loop

```text
while running
    load active accounts
    for each account
        for each enabled folder
            sync folder
    wait 30 seconds
```

Initial implementation may be sequential.

Do not add queues, Hangfire, Redis, or distributed scheduling.

### Per-folder sync

```text
Connect
Authenticate
Open folder
Read server UIDVALIDITY

if UIDVALIDITY changed:
    safely invalidate/rebuild folder sync state

Read SyncState.LastUid
Search UIDs > LastUid
Order ascending

for each new UID:
    fetch message
    map MIME -> Mail
    persist attachments
    persist inline resources
    add Mail row

update LastUid only after successful persistence
commit
disconnect
```

### Mapping

Extract a deterministic mapping function and unit-test it.

At minimum map:

```text
Uid
UidValidity
MessageId
Subject
FromAddress
FromDisplayName
ToAddress
BodyHtml
BodyText
ReceivedAt
IsRead
MailAccountId
MailFolderId
HasAttachments
```

Fallbacks:

```text
null subject -> "(no subject)"
missing address -> ""
```

### Attachment storage

Path pattern may be:

```text
data/attachments/{accountId}/{mailId}/{attachmentId-or-safe-filename}
```

Requirements:

- sanitize filenames,
- prevent path traversal,
- retain original filename in DB metadata,
- store `ContentId` for inline resources,
- enforce configurable per-file and per-message size limits.

Virus scanning is deferred but the storage/API boundary must allow adding it later.

### Error isolation

A single account/folder error must not kill the worker.

Log sanitized context:

```text
accountId
folderId
host
exception type/message
```

Never log credentials or message bodies.

---

## Task 6 — IMAP Flag Reconciliation and Two-Way Read/Unread

### Goal

Support read/unread synchronization in both directions.

Important: `LastUid` alone only finds new messages and cannot detect flag changes on existing messages.

### Client -> IMAP

Endpoint:

```text
PATCH /api/mails/{id}/read
```

Behavior:

```text
authorize ownership
open account/folder ReadWrite
write/remove IMAP \Seen
if IMAP succeeds:
    update local DB IsRead
```

IMAP remains authoritative.

Do not report success if the IMAP operation failed.

### IMAP -> local DB

Add lightweight flag reconciliation.

MVP strategy:

- keep 30-second new-mail polling,
- perform a flags-only reconciliation on a slower configurable interval,
- default example: 120 seconds,
- fetch flags only, never full bodies,
- update local `IsRead` when server flags differ.

Config:

```text
MailSync:
  PollIntervalSeconds: 30
  FlagSyncIntervalSeconds: 120
```

Future optimization:

```text
CONDSTORE / QRESYNC / IDLE
```

is explicitly deferred.

### Tests

- read adds `\Seen`,
- unread removes `\Seen`,
- local state follows successful server update,
- flag mapper updates existing mail state.

---

## Task 7 — Mail List, Unified Views, Detail, and Attachment APIs

### Goal

Expose user-owned cached mail via REST.

### Endpoints

```text
GET /api/mails
GET /api/mails/{id}
GET /api/mails/{id}/attachments/{attachmentId}
```

### Query behavior

Unified Inbox:

```text
GET /api/mails?folderType=Inbox&page=1&pageSize=30
```

Account Inbox:

```text
GET /api/mails?accountId={id}&folderType=Inbox&page=1&pageSize=30
```

Unified Sent:

```text
GET /api/mails?folderType=Sent&page=1&pageSize=30
```

Folder-specific:

```text
GET /api/mails?folderId={id}
```

### MailService placement

```text
Application:
    IMailService
    DTOs

Infrastructure:
    MailService : IMailService
    uses AppDbContext
```

Application must not reference Infrastructure.

### DTOs

Summary should include:

```text
Id
MailAccountId
MailAccountEmail
FolderType
FromDisplayName
FromAddress
Subject
ReceivedAt
IsRead
HasAttachments
```

Detail should include:

```text
summary fields
ToAddress
BodyHtml
BodyText
Attachments[]
```

### Attachment authorization

Never expose raw StoragePath.

Download must verify:

```text
Attachment
 -> Mail
 -> MailAccount
 -> current JWT User
```

---

## Task 8 — SMTP Send + Sent Folder Behavior

### Goal

Send mail like a normal desktop client.

### Endpoint

```text
POST /api/mail-accounts/{accountId}/send
```

Use:

```text
multipart/form-data
```

### Flow

```text
authorize account ownership
build MimeMessage
connect/auth SMTP
send

if SMTP succeeded:
    do NOT resend on later Sent-copy failure

if SaveSentCopy == true:
    locate Sent folder
    IMAP APPEND same MimeMessage
```

### Important failure semantics

SMTP success means the email was sent.

If Sent append fails:

- do not retry SMTP automatically,
- return or log a clear "sent but sent-copy failed" state,
- allow later repair/manual resync.

### API / Application boundary

Do not make Infrastructure depend on `IFormFile`.

API should map uploaded files into application-level attachment inputs.

Example:

```text
SendMailCommand
- ToAddress
- Subject
- BodyHtml
- Attachments[]
```

Attachment input:

```text
FileName
ContentType
Stream
```

### Sent duplication

`SaveSentCopy` is account-specific because some providers may save Sent automatically.

Default:

```text
true
```

No separate `SentMails` table.

Sent folder sync will bring the message into local `Mail`.

---

## Task 9 — FCM Device Registration and Push Notifications

### Goal

Push new Inbox mail notifications to the current user's devices.

### Endpoints

```text
POST   /api/devices/register
DELETE /api/devices/{id}
```

Register body:

```json
{
  "pushToken": "...",
  "platform": "android"
}
```

Do not accept `userId` from the request.

Derive it from JWT.

### Push payload

Recommended data:

```text
type = new_mail
mailId
accountId
folderId
```

Notification:

```text
title = sender display name / address
body  = subject
```

Optionally include connected account email in a safe UI field if useful.

### Sync integration

After successful DB commit for new Inbox mail:

```text
persist mail
commit
    ↓
best-effort FCM
```

FCM failure must not fail IMAP sync.

Handle invalid/expired tokens by removing or disabling them where Firebase provides a definitive invalid-token response.

### Firebase credentials

Never commit service account credentials.

Use environment/secret path or platform secret management.

---

## Task 10 — Flutter Authentication and Mail Account Management

### Goal

Implement user/admin login flow and connected account management before the main mail UI.

### User screens

```text
Login
Register
Pending approval state
Mail account list
Add mail account
Edit mail account
Connection test
```

### Admin screens

Minimum:

```text
User list
Pending users
Create user
Approve
Disable
Enable
Reset password action
```

Admin UI does not expose mail contents or mailbox credentials.

### Client storage

Store JWT securely using a platform-appropriate secure storage package.

Do not keep passwords or mailbox credentials in plain local preferences.

---

## Task 11 — Flutter Thunderbird-like Mail UI

### Goal

Provide account-centric navigation plus unified views.

### Navigation concept

```text
Unified
├── Inbox
└── Sent

Accounts
├── ahmet@tekyazilim.com
│    ├── Inbox
│    └── Sent
│
└── destek@tekyazilim.com
     ├── Inbox
     └── Sent
```

Do not create duplicate local "Unified Inbox" records.

Unified views are API queries.

### Screens

```text
MailListScreen
MailDetailScreen
ComposeScreen
Account/Folder navigation
```

### List behavior

Show at minimum:

```text
account indicator
sender
subject
received date
read/unread
attachment indicator
```

### Detail

- HTML body via safe rendering,
- fallback text body,
- attachment list,
- inline content resolution,
- mark read through API.

### Compose

User chooses sending account.

Support:

```text
To
Subject
HTML/text body
attachments
```

Reply/Forward can be added after the base compose/send path is stable.

---

## Task 12 — Notification Mode and Background Fallback

### Goal

Use FCM normally, with Android periodic polling as an explicit alternative.

### Configuration

```text
NotificationMode
- Firebase
- PeriodicPolling
```

Both must never be active together.

### Firebase mode

- register FCM token,
- foreground push refreshes relevant mail provider,
- notification tap routes to mail detail.

### PeriodicPolling mode

Android only:

```text
Workmanager
 -> GET lightweight endpoint
 -> local notification if new mail count increased
```

Example endpoint:

```text
GET /api/mails/unread-count?since=...
```

iOS background refresh is not treated as a reliable replacement for push.

---

## Task 13 — End-to-End Integration, Security, and Hardening

### Goal

Verify the complete customer workflow.

### E2E scenario

```text
1. User registers.
2. Admin approves user.
3. User logs in.
4. User connects GreenMail account.
5. Inbox/Sent folders are discovered.
6. External mail arrives.
7. Within one polling cycle:
   - mail saved,
   - attachments saved,
   - SyncState advanced,
   - FCM received.
8. Flutter opens mail.
9. Read state writes IMAP \Seen.
10. External client changes read state.
11. Flag reconciliation updates Flutter state.
12. User sends a mail.
13. SMTP succeeds.
14. Sent copy appears in IMAP Sent.
15. Sent sync brings it into local DB.
16. API restart does not duplicate messages.
```

### Security checklist

- HTTPS enforced outside Development.
- No plaintext application passwords.
- No plaintext mailbox credentials.
- Data Protection key ring persists.
- `appsettings.Local.json` ignored.
- Firebase credentials ignored.
- All mail/account/file APIs are ownership scoped.
- Admin cannot read arbitrary user mail by default.
- Attachment filenames sanitized.
- Attachment size/type limits exist.
- Mail HTML rendering is treated as untrusted content.
- Logs contain no secrets or mail bodies.

### Reliability checklist

- One broken account does not stop other accounts.
- One broken folder does not stop the worker.
- SMTP success is never repeated because Sent append failed.
- FCM failure does not fail sync.
- UIDVALIDITY change does not silently advance bad state.
- Duplicate unique index remains the last-line protection.

---

# 7. Configuration Shape

Tracked configuration should contain placeholders/defaults only.

Example:

```json
{
  "MailSync": {
    "PollIntervalSeconds": 30,
    "FlagSyncIntervalSeconds": 120
  },
  "Registration": {
    "Mode": "ApprovalRequired"
  },
  "Notifications": {
    "Mode": "Firebase"
  },
  "Storage": {
    "AttachmentRoot": "data/attachments",
    "MaxAttachmentBytes": 26214400
  }
}
```

Local development secrets belong in:

```text
appsettings.Local.json
User Secrets
environment variables
```

`appsettings.Local.json` must be ignored.

Production secrets should use environment variables / secret management.

Mail-account server settings do not live globally in appsettings once multi-account support is active; they live per `MailAccount`.

---

# 8. Testing Strategy

## Unit tests

Cover pure logic:

```text
MimeMessage -> Mail mapping
MailSecurity mapping
folder type mapping
credential protect/unprotect
password hashing
JWT creation
DTO mapping
FCM message construction
send-message MIME construction
filename sanitization
```

## Application / Infrastructure tests

Use test DB / GreenMail where practical:

```text
account ownership
folder discovery
new UID sync
no duplicate sync
UIDVALIDITY reset behavior
read/unread IMAP flags
attachment persistence
SMTP send
Sent append
```

## Manual smoke tests

GreenMail is the local protocol test system.

The worker should not depend on a real production mailbox for tests.

---

# 9. Explicit Non-Goals for This Plan

Do not implement unless a later plan explicitly adds them:

```text
SignalR
IMAP IDLE
Redis
Hangfire
distributed workers
multi-node sync coordination
OAuth2 mail providers
Gmail API
Microsoft Graph
conversation threading
mail rules
contacts
signatures
server autodiscovery
advanced search
full Drafts/Trash/Junk/Archive behavior
move/delete synchronization
support impersonation
S3/Azure Blob/MinIO
virus scanning engine
billing/subscriptions
Customer/Organization/Tenant model
```

The schema may leave room for later extension, but no speculative abstractions should be added only for these future features.

---

# 10. Recommended Commit Sequence

```text
feat(db): revise domain for users multi-account folders and sync state
feat(auth): add registration login and admin user management
feat(accounts): add protected multi-account IMAP SMTP configuration
feat(folders): add IMAP folder discovery and inbox sent mapping
feat(sync): add multi-account polling IMAP sync and attachment persistence
feat(flags): add two-way read unread synchronization
feat(api): add unified and account-scoped mail APIs
feat(smtp): add account-scoped send and configurable sent append
feat(push): add authenticated FCM device registration and notifications
feat(flutter-auth): add login registration admin and account setup flows
feat(flutter-mail): add account-centric inbox sent detail and compose UI
feat(notifications): add Firebase mode and periodic fallback mode
feat(integration): harden and verify end-to-end mail client flow
```

---

# 11. Definition of Done

The revised MVP is complete when:

- [ ] Users can self-register.
- [ ] Admin can create/approve/disable/enable users.
- [ ] Users can log in with JWT.
- [ ] One user can connect multiple IMAP/SMTP accounts.
- [ ] Mailbox passwords are encrypted at rest.
- [ ] Inbox and Sent folders are discovered per account.
- [ ] New mail syncs every ~30 seconds.
- [ ] Sync is UIDVALIDITY-aware.
- [ ] Incoming attachments are stored locally.
- [ ] Unified Inbox works without duplicate data.
- [ ] Account-specific Inbox/Sent works.
- [ ] Read/unread synchronizes both ways.
- [ ] SMTP send works.
- [ ] Sent copy behavior is configurable per account.
- [ ] Sent folder sync reflects sent messages.
- [ ] FCM pushes new Inbox mail.
- [ ] FCM failure does not break sync.
- [ ] Workmanager fallback is mutually exclusive with FCM.
- [ ] Flutter supports auth, accounts, Inbox, Sent, detail, compose.
- [ ] Ownership checks prevent cross-user data access.
- [ ] Admin cannot implicitly read user mail content.
- [ ] Build and tests pass.
- [ ] GreenMail end-to-end smoke test passes.
