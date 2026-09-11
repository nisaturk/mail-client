import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/mail_summary.dart';

/// A single dense mail row for the main list.
///
/// Read messages are quiet; unread messages get stronger typography, a faint
/// background tint and a status dot.
class MailListItem extends StatelessWidget {
  const MailListItem({super.key, required this.mail, this.onTap});

  final MailSummary mail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool unread = !mail.isRead;
    final String sender = mail.fromDisplayName.isNotEmpty
        ? mail.fromDisplayName
        : mail.fromAddress;

    final TextStyle senderStyle = theme.textTheme.titleSmall!.copyWith(
      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
      color: unread ? scheme.onSurface : scheme.onSurfaceVariant,
    );
    final TextStyle subjectStyle = theme.textTheme.bodyMedium!.copyWith(
      fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
      color: scheme.onSurface,
    );
    final TextStyle previewStyle = theme.textTheme.bodySmall!.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Semantics(
      button: true,
      label: '$sender, ${mail.subject}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: unread
              ? scheme.surfaceContainerHigh.withValues(alpha: 0.5)
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SenderAvatar(sender: sender, unread: unread),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sender,
                            style: senderStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (mail.hasAttachments) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.attach_file,
                            size: 15,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(mail.receivedAt),
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: unread
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mail.subject,
                      style: subjectStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (mail.preview.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        mail.preview,
                        style: previewStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final DateTime now = DateTime.now();
    if (now.difference(dt).inDays < 1) return DateFormat.Hm().format(dt);
    if (now.difference(dt).inDays < 7) return DateFormat.E().format(dt);
    return DateFormat('d MMM').format(dt);
  }
}

class _SenderAvatar extends StatelessWidget {
  const _SenderAvatar({required this.sender, required this.unread});

  final String sender;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: unread ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          sender.isNotEmpty ? sender[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: unread
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}