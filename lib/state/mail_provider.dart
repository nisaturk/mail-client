import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mail_summary.dart';
import '../models/mail_detail.dart';
import '../models/attachment.dart';
import '../models/enums.dart';
import '../repositories/api_client.dart';
import '../repositories/api_config.dart';

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
    preview: 'Proje teslim tarihi 15 Eylül olarak güncellendi. Lütfen güncel takvimi kontrol edin.',
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
    preview: 'Toplantı notlarını paylaşıyorum: Bütçe görüşmesi gelecek haftaya ertelendi.',
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
    preview: 'Ticket yeni bir güncelleme aldı. Durum: İnceleniyor.',
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
    preview: 'Ağustos ayı faturası ektedir. Ödeme vadesi: 20 Eylül 2025.',
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
    preview: 'Lütfen güncellenen teslim tarihi hakkında bilgi verir misiniz?',
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
    preview: 'İlgili kayıt incelendi, müşteri ile görüşme yapılacak.',
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
    bodyText:
        'Ağustos ayı faturası ektedir. Ödeme vadesi: 20 Eylül 2025.\n\nSaygılarımızla,\nAli Demir',
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
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  const MailListState({
    this.mails = const [],
    this.allMails = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.pageSize = 30,
    this.totalCount = 0,
    this.hasMore = false,
  });

  MailListState copyWith({
    List<MailSummary>? mails,
    List<MailSummary>? allMails,
    bool? isLoading,
    String? error,
    int? page,
    int? pageSize,
    int? totalCount,
    bool? hasMore,
  }) {
    return MailListState(
      mails: mails ?? this.mails,
      allMails: allMails ?? this.allMails,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  int unreadCountForAccount(String accountId) =>
      allMails.where((m) => m.mailAccountId == accountId && !m.isRead).length;

  int unreadCountAll(MailFolderType folder) =>
      allMails.where((m) => m.folderType == folder && !m.isRead).length;
}

String _folderParam(MailFolderType folderType) {
  final name = folderType.name;
  return name[0].toUpperCase() + name.substring(1);
}

class MailListNotifier extends StateNotifier<MailListState> {
  final Dio _dio;
  String? _activeAccountId;
  MailFolderType? _activeFolder;

  MailListNotifier({Dio? dio})
      : _dio = dio!,
        super(const MailListState());

  Future<void> load({
    String? accountId,
    MailFolderType? folderType,
  }) async {
    _activeAccountId = accountId;
    _activeFolder = folderType;
    state = state.copyWith(isLoading: true, error: null);
    if (useMockApi) {
      await Future.delayed(const Duration(milliseconds: 400));
      final list = List<MailSummary>.from(_mockMails);
      state = MailListState(
        mails: list,
        allMails: list,
        totalCount: list.length,
        hasMore: false,
      );
      _applyFilter(accountId: accountId, folderType: folderType);
      return;
    }
    try {
      final response = await _dio.get('/mails', queryParameters: {
        'accountId': ?accountId,
        if (folderType != null) 'folderType': _folderParam(folderType),
        'page': 1,
        'pageSize': 30,
      });
      final data = response.data as Map<String, dynamic>;
      final items = _parseItems(data['items']);
      final total = data['totalCount'] as int? ?? items.length;
      state = MailListState(
        mails: items,
        allMails: items,
        page: 2,
        pageSize: 30,
        totalCount: total,
        hasMore: items.length < total,
      );
      _applyFilter(accountId: accountId, folderType: folderType);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
    }
  }

  Future<void> loadMore() async {
    if (useMockApi || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/mails', queryParameters: {
        'accountId': ?_activeAccountId,
        if (_activeFolder != null) 'folderType': _folderParam(_activeFolder!),
        'page': state.page,
        'pageSize': state.pageSize,
      });
      final data = response.data as Map<String, dynamic>;
      final items = _parseItems(data['items']);
      final total = data['totalCount'] as int? ?? state.totalCount;
      final cumulative = state.mails.length + items.length;
      state = state.copyWith(
        mails: [...state.mails, ...items],
        allMails: [...state.allMails, ...items],
        isLoading: false,
        page: state.page + 1,
        totalCount: total,
        hasMore: cumulative < total,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
    }
  }

  List<MailSummary> _parseItems(Object? raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => MailSummary.fromJson(e as Map<String, dynamic>))
        .toList();
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
    _applyRead(mailId, true);
    _syncReadState(mailId, true);
  }

  void markAsUnread(String mailId) {
    _applyRead(mailId, false);
    _syncReadState(mailId, false);
  }

  void _applyRead(String mailId, bool read) {
    MailSummary mark(MailSummary m) =>
        m.id == mailId && m.isRead != read ? m.copyWith(isRead: read) : m;
    state = state.copyWith(
      mails: state.mails.map(mark).toList(),
      allMails: state.allMails.map(mark).toList(),
    );
  }

  Future<void> _syncReadState(String mailId, bool read) async {
    if (useMockApi) return;
    try {
      await _dio.patch('/mails/$mailId/read', data: {'isRead': read});
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        await load(accountId: _activeAccountId, folderType: _activeFolder);
      }
    }
  }

  Future<MailDetail?> fetchDetail(String mailId) async {
    if (useMockApi) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockDetails[mailId];
    }
    try {
      final response = await _dio.get('/mails/$mailId');
      return MailDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(_errorMessage(e));
    }
  }

  String _errorMessage(DioException e) =>
      e.response?.data is Map
          ? (e.response?.data['message'] ?? e.message)?.toString() ??
              'Failed to load mail'
          : e.message ?? 'Failed to load mail';
}

final mailListProvider =
    StateNotifierProvider<MailListNotifier, MailListState>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return MailListNotifier(dio: dio)..load();
});