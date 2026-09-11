import 'package:flutter/material.dart';
import '../../models/attachment.dart';

/// Icon for an attachment based on its content type.
IconData attachmentTypeIcon(String contentType) {
  if (contentType.contains('pdf')) return Icons.picture_as_pdf;
  if (contentType.contains('image')) return Icons.image_outlined;
  if (contentType.contains('spreadsheet') ||
      contentType.contains('excel') ||
      contentType.contains('xlsx')) {
    return Icons.table_chart_outlined;
  }
  if (contentType.contains('word') || contentType.contains('document')) {
    return Icons.description_outlined;
  }
  return Icons.insert_drive_file_outlined;
}

/// Compact, tappable attachment row used in the mail detail screen.
///
/// Pass a [width] when rendering inside a horizontal list.
class AttachmentItem extends StatelessWidget {
  const AttachmentItem({
    super.key,
    required this.attachment,
    this.onTap,
    this.width,
  });

  final Attachment attachment;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final Widget row = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              attachmentTypeIcon(attachment.contentType),
              size: 20,
              color: scheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.fileName,
                    style:
                        theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    attachment.sizeLabel,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return width != null ? SizedBox(width: width, child: row) : row;
  }
}