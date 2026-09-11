class Attachment {
  final String id;
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final bool isInline;

  const Attachment({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    this.isInline = false,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      contentType: json['contentType'] as String? ?? 'application/octet-stream',
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      isInline: json['isInline'] as bool? ?? false,
    );
  }

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1048576) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / 1048576).toStringAsFixed(1)} MB';
  }
}
