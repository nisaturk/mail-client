import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mail_summary.dart';
import '../models/mail_detail.dart';
import '../models/attachment.dart';
import '../models/enums.dart';

final _now = DateTime.now();

final _mockMails = [
  MailSummary(
    id: '1',
    mailAccountId: '1',
    mailAccountEmail: 'ahmet@tekyazilim.com',
    folderType: MailFolderType.inbox,
    fromDisplayName: 'Mehmet Yilmaz',
    fromAddress: 'mehmet@example.com',
    subject: 'Proje Teslim Tarihi',
    receivedAt: _now.subtract(const Duration(minutes: 15)),
    isRead: false,
    hasAttachments: true,
  ),
  MailSummary(
    id: '2',
    mailAccountId: '1',
    mailAccountEmail: 'ahmet@tekyazilim.com',
    folderType: MailFolderType.inbox,
    fromDisplayName: 'Zeynep Kaya',
    fromAddress: 'zeynep@firma.com',
    subject: 'Toplanti Notlari - 9 Eylül',
    receivedAt: _now.subtract(const Duration(hours: 2)),
    isRead: false,
    hasAttachments: false,
  ),
  MailSummary(
    id: '3',
    mailAccountId: '2',
    mailAccountEmail: 'destek@tekyazilim.com',
    folderType: MailFolderType.inbox,
    fromDisplayName: 'Destek Sistemi',
    fromAddress: 'noreply@destek.com',
    subject: 'Ticket #4821 Güncellendi',
    receivedAt: _now.subtract(const Duration(hours: 5)),
    isRead: true,
    hasAttachments: false,
  ),
  MailSummary(
    id: '4',
    mailAccountId: '1',
    mailAccountEmail: 'ahmet@tekyazilim.com',
    folderType: MailFolderType.inbox,
    fromDisplayName: 'Ali Demir',
    fromAddress: 'ali@ortak.com',
    subject: 'Fatura - Ağustos 2025',
    receivedAt: _now.subtract(const Duration(days: 1)),
    isRead: true,
    hasAttachments: true,
  ),
  MailSummary(
    id: '5',
    mailAccountId: '1',
    mailAccountEmail: 'ahmet@tekyazilim.com',
    folderType: MailFolderType.sent,
    fromDisplayName: 'Ahmet',
    fromAddress: 'ahmet@tekyazilim.com',
    subject: 'Re: Proje Teslim Tarihi',
    receivedAt: _now.subtract(const Duration(hours: 1)),
    isRead: true,
    hasAttachments: false,
  ),
  MailSummary(
    id: '6',
    mailAccountId: '2',
    mailAccountEmail: 'destek@tekyazilim.com',
    folderType: MailFolderType.sent,
    fromDisplayName: 'Destek',
    fromAddress: 'destek@tekyazilim.com',
    subject: 'Re: Ticket #4821',
    receivedAt: _now.subtract(const Duration(hours: 4)),
    isRead: true,
    hasAttachments: false,
  ),
];

final _mockDetails = <String, MailDetail>{
  '1': const MailDetail(
    id: '1',
    mailAccountId: '1',
    mailAccountEmail: 'ahmet@tekyazilim.com',
    folderType: MailFolderType.inbox,
    fromDisplayName: 'Mehmet Yilmaz',
    fromAddress: 'mehmet@example.com',
    toAddress: 'ahmet@tekyazilim.com',
    subject: 'Proje Teslim Tarihi',
    isRead: false,
    hasAttachments: true,
    bodyHtml:
        '<h3>Merhaba Ahmet,</h3><p>Proje teslim tarihi <strong>15 Eylül</strong> olarak guncellendi. Lutfen guncel takvimi kontrol edin.</p><p>Sorulariniz olursa ulasin.</p><p>Selamlar,<br>Mehmet</p>',
    attachments: [
      Attachment(
          id: 'a1',
          fileName: 'takvim_2025.pdf',
          contentType: 'application/pdf',
          sizeBytes: 245760),
      Attachment(
          id: 'a2',
          fileName: 'proje_plani.xlsx',
          contentType: 'application/vnd.ms-excel',
          sizeBytes: 89600),
    ],
  ),
  '2': const MailDetail(
    id: '2',
    mailAccountId: '1',
    mailAccountEmail: 'ahmet@tekyazilim.com',
    folderType: MailFolderType.inbox,
    fromDisplayName: 'Zeynep Kaya',
    fromAddress: 'zeynep@firma.com',
    toAddress: 'ahmet@tekyazilim.com',
    subject: 'Toplanti Notlari - 9 Eylül',
    isRead: false,
    hasAttachments: false,
    bodyHtml:
        '<p>Toplanti notlarini paylaşıyorum:</p><ul><li>Bütce goruşmesi gelecek haftaya ertelendi</li><li>Yeni musteri sunumu pazartesi</li><li>Stajyer basvurulari degerlendirmede</li></ul><p>Selamlar,<br>Zeynep</p>',
  ),
  '3': const MailDetail(
    id: '3',
    mailAccountId: '2',
    mailAccountEmail: 'destek@tekyazilim.com',
    folderType: MailFolderType.inbox,
    fromDisplayName: 'Destek Sistemi',
    fromAddress: 'noreply@destek.com',
    toAddress: 'destek@tekyazilim.com',
    subject: 'Ticket #4821 Güncellendi',
    isRead: true,
    hasAttachments: false,
    bodyHtml:
        '<p>Ticket <strong>#4821</strong> yeni bir guncelleme aldi:</p><p><strong>Durum:</strong> Inceleniyor<br><strong>Oncelik:</strong> Yuksek</p><p>Musteri geri bildirimi bekleniyor.</p>',
  ),
  '4': const MailDetail(
    id: '4',
    mailAccountId: '1',
    mailAccountEmail: 'ahmet@tekyazilim.com',
    folderType: MailFolderType.inbox,
    fromDisplayName: 'Ali Demir',
    fromAddress: 'ali@ortak.com',
    toAddress: 'ahmet@tekyazilim.com',
    subject: 'Fatura - Ağustos 2025',
    isRead: true,
    hasAttachments: true,
    bodyHtml:
        '<p>Agustos ayi faturasi ektedir. Odeme vadesi: <strong>20 Eylül 2025</strong></p><p>Selamlar,<br>Ali Demir</p>',
    attachments: [
      Attachment(
          id: 'a3',
          fileName: 'fatura_agustos_2025.pdf',
          contentType: 'application/pdf',
          sizeBytes: 156902),
    ],
  ),
};

class MailListState {
  final List<MailSummary> mails;
  final List<MailSummary> allMails;
  final bool isLoading;
  final String? error;

  const MailListState({
    this.mails = const [],
    this.allMails = const [],
    this.isLoading = false,
    this.error,
  });

  MailListState copyWith({
    List<MailSummary>? mails,
    List<MailSummary>? allMails,
    bool? isLoading,
    String? error,
  }) {
    return MailListState(
      mails: mails ?? this.mails,
      allMails: allMails ?? this.allMails,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int unreadCountForAccount(String accountId) =>
      allMails.where((m) => m.mailAccountId == accountId && !m.isRead).length;

  int unreadCountAll(MailFolderType folder) =>
      allMails.where((m) => m.folderType == folder && !m.isRead).length;
}

class MailListNotifier extends StateNotifier<MailListState> {
  MailListNotifier() : super(const MailListState());

  Future<void> load({
    String? accountId,
    MailFolderType? folderType,
  }) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 400));
    var list = List<MailSummary>.from(_mockMails);
    state = MailListState(mails: list, allMails: list);
    _applyFilter(accountId: accountId, folderType: folderType);
  }

  void search({
    String? accountId,
    MailFolderType? folderType,
    required String query,
  }) {
    _applyFilter(accountId: accountId, folderType: folderType, query: query);
  }

  void _applyFilter({
    String? accountId,
    MailFolderType? folderType,
    String? query,
  }) {
    var list = state.allMails;
    if (accountId != null) {
      list = list.where((m) => m.mailAccountId == accountId).toList();
    }
    if (folderType != null) {
      list = list.where((m) => m.folderType == folderType).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      list = list
          .where((m) =>
              m.subject.toLowerCase().contains(q) ||
              m.fromDisplayName.toLowerCase().contains(q) ||
              m.fromAddress.toLowerCase().contains(q))
          .toList();
    }
    state = state.copyWith(mails: list);
  }

  void markAsRead(String mailId) {
    MailSummary mark(MailSummary m) =>
        m.id == mailId && !m.isRead ? m.copyWith(isRead: true) : m;
    state = state.copyWith(
      mails: state.mails.map(mark).toList(),
      allMails: state.allMails.map(mark).toList(),
    );
  }
}

final mailListProvider =
    StateNotifierProvider<MailListNotifier, MailListState>((ref) {
  return MailListNotifier()..load();
});

Future<MailDetail?> loadMailDetail(String mailId) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return _mockDetails[mailId];
}

Future<void> markMailAsRead(String mailId) async {
  await Future.delayed(const Duration(milliseconds: 200));
}
