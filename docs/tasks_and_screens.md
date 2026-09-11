# UI Screens & Tasks Roadmap

## Screen Requirements
* **Login & Register Screen:** Email, password inputs, pending registration feedback[cite: 2].
* **Mail Account List Screen:** Shows connected accounts, active state, edit & connection test buttons[cite: 2].
* **Add/Edit Account Screen:** Form fields for IMAP Host/Port, SMTP Host/Port, and Security Enum (`None`, `SslOnConnect`, `StartTls`)[cite: 2].
* **Mail List Screen:** Displays account indicator, sender, subject, date, read status badge, and attachment icons[cite: 2]. Supports Unified and Account-scoped filtering[cite: 2].
* **Mail Detail Screen:** Safely renders HTML/Text content, handles attachment downloads, and triggers read status updates[cite: 2].
* **Compose Screen:** Account selector dropdown, To/Subject fields, body text area, and attachment picker[cite: 2].
* **Admin Screen:** User approval, status toggling, and user creation interface[cite: 2].

## Push Notification Behavior
* Primary push system uses Firebase Cloud Messaging (FCM)[cite: 2].
* Foreground FCM messages trigger local notifications and refresh active REST list providers[cite: 2].
* Notification payload contains `data.mailId` to immediately open `MailDetailScreen`[cite: 2]. Email body is always retrieved via REST API, not the push payload[cite: 2].

## Implementation Tasks (Tasks 10–12)
* **Task 10 (Auth & Accounts UI):** Login/Register, Admin panel, and Mail Account configuration forms[cite: 2].
* **Task 11 (Mail UI):** Unified/Account list views, Mail Detail view, Compose view[cite: 2].
* **Task 12 (Notifications):** FCM integration with background fallback mode[cite: 2].