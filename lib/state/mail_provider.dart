import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mail_summary.dart';
import '../models/mail_detail.dart';
import '../models/enums.dart';
import '../repositories/api_client.dart';

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
    if (!state.hasMore || state.isLoading) return;
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
    try {
      await _dio.patch('/mails/$mailId/read', data: {'isRead': read});
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        await load(accountId: _activeAccountId, folderType: _activeFolder);
      }
    }
  }

  Future<MailDetail?> fetchDetail(String mailId) async {
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