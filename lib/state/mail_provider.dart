import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mail_summary.dart';
import '../models/mail_detail.dart';
import '../models/enums.dart';
import '../repositories/mail_repository.dart';

class MailListState {
  final List<MailSummary> mails;
  final List<MailSummary> allMails;
  final bool isLoading;
  final String? error;
  final int totalCount;
  final int page;
  final int pageSize;

  const MailListState({
    this.mails = const [],
    this.allMails = const [],
    this.isLoading = false,
    this.error,
    this.totalCount = 0,
    this.page = 1,
    this.pageSize = 30,
  });

  MailListState copyWith({
    List<MailSummary>? mails,
    List<MailSummary>? allMails,
    bool? isLoading,
    String? error,
    int? totalCount,
    int? page,
    int? pageSize,
  }) {
    return MailListState(
      mails: mails ?? this.mails,
      allMails: allMails ?? this.allMails,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  int unreadCountForAccount(String accountId) =>
      allMails.where((m) => m.mailAccountId == accountId && !m.isRead).length;

  int unreadCountAll(MailFolderType folder) =>
      allMails.where((m) => m.folderType == folder && !m.isRead).length;
}

class MailListNotifier extends Notifier<MailListState> {
  @override
  MailListState build() {
    Future.microtask(() => load());
    return const MailListState();
  }

  MailRepository get _repo => ref.read(mailRepositoryProvider);

  Future<void> load({
    String? accountId,
    MailFolderType? folderType,
    String? folderId,
    int page = 1,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.getMails(
        accountId: accountId,
        folderType: folderType,
        folderId: folderId,
        page: page,
      );
      state = MailListState(
        mails: res.items,
        allMails: res.items,
        totalCount: res.totalCount,
        page: res.page,
        pageSize: res.pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
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

  Future<void> markAsRead(String mailId) async {
    MailSummary mark(MailSummary m) =>
        m.id == mailId && !m.isRead ? m.copyWith(isRead: true) : m;
    state = state.copyWith(
      mails: state.mails.map(mark).toList(),
      allMails: state.allMails.map(mark).toList(),
    );

    try {
      await _repo.markAsRead(mailId, true);
    } catch (_) {
      // Ignore error if already read or handled by UI
    }
  }
}

final mailListProvider =
    NotifierProvider<MailListNotifier, MailListState>(
  MailListNotifier.new,
);

Future<MailDetail?> loadMailDetail(String mailId, {MailRepository? repo}) async {
  if (repo == null) return null;
  return repo.getMailDetail(mailId);
}

Future<void> markMailAsRead(String mailId) async {
  // Handled via MailListNotifier
}
