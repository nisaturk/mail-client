import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mail_summary.dart';
import '../models/mail_detail.dart';
import '../models/enums.dart';
import '../repositories/api_client.dart';

class MailListState {
  final List<MailSummary> mails;
  final bool isLoading;
  final String? error;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;
  final String? searchQuery;

  const MailListState({
    this.mails = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.pageSize = 30,
    this.totalCount = 0,
    this.hasMore = false,
    this.searchQuery,
  });

  MailListState copyWith({
    List<MailSummary>? mails,
    bool? isLoading,
    String? error,
    int? page,
    int? pageSize,
    int? totalCount,
    bool? hasMore,
    String? searchQuery,
  }) {
    return MailListState(
      mails: mails ?? this.mails,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Filtered view used by the UI: applies the live search query to the
  /// currently loaded messages.
  List<MailSummary> get displayedMails {
    final query = searchQuery?.trim().toLowerCase();
    if (query == null || query.isEmpty) return mails;
    return mails
        .where((m) =>
            m.subject.toLowerCase().contains(query) ||
            m.fromDisplayName.toLowerCase().contains(query) ||
            m.fromAddress.toLowerCase().contains(query))
        .toList();
  }

  int unreadCountForAccount(String accountId) =>
      mails.where((m) => m.mailAccountId == accountId && !m.isRead).length;

  int unreadCountAll(MailFolderType folder) =>
      mails.where((m) => m.folderType == folder && !m.isRead).length;
}

String _folderParam(MailFolderType folderType) {
  final name = folderType.name;
  return name[0].toUpperCase() + name.substring(1);
}

class MailListNotifier extends StateNotifier<MailListState> {
  final Dio _dio;
  String? _activeAccountId;
  MailFolderType? _activeFolder;

  MailListNotifier({Dio? dio}) : _dio = dio ?? Dio(), super(const MailListState());

  Future<void> load({
    String? accountId,
    MailFolderType? folderType,
  }) async {
    _activeAccountId = accountId;
    _activeFolder = folderType;
    state = state.copyWith(isLoading: true, error: null, searchQuery: null);
    try {
      final response = await _dio.get('/mails', queryParameters: {
        'accountId': ?accountId,
        if (folderType != null) 'folderType': _folderParam(folderType),
        'page': 1,
        'pageSize': state.pageSize,
      });
      final data = response.data as Map<String, dynamic>;
      final items = _parseItems(data['items']);
      final total = data['totalCount'] as int? ?? items.length;
      state = MailListState(
        mails: items,
        page: 2,
        pageSize: state.pageSize,
        totalCount: total,
        hasMore: items.length < total,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.searchQuery != null) return;
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
      final existingIds = state.mails.map((m) => m.id).toSet();
      final freshItems =
          items.where((m) => !existingIds.contains(m.id)).toList();
      final cumulative = state.mails.length + freshItems.length;
      state = state.copyWith(
        mails: [...state.mails, ...freshItems],
        page: state.page + 1,
        totalCount: total,
        hasMore: cumulative < total,
      );
    } on DioException catch (e) {
      state = state.copyWith(error: _errorMessage(e));
    }
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearch() {
    state = MailListState(
      mails: state.mails,
      isLoading: state.isLoading,
      error: state.error,
      page: state.page,
      pageSize: state.pageSize,
      totalCount: state.totalCount,
      hasMore: state.hasMore,
    );
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
    state = state.copyWith(
      mails: state.mails
          .map((m) => m.id == mailId && m.isRead != read
              ? m.copyWith(isRead: read)
              : m)
          .toList(),
    );
  }

  Future<void> _syncReadState(String mailId, bool read) async {
    try {
      await _dio.patch('/mails/$mailId/read', data: {'isRead': read});
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // ponytail: single refresh on folder conflict, no retry loop.
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

  List<MailSummary> _parseItems(Object? raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => MailSummary.fromJson(e as Map<String, dynamic>))
        .toList();
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