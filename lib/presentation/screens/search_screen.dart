import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/mail_provider.dart';
import '../widgets/mail_list_body.dart';
import '../widgets/mail_list_item.dart';
import 'mail_detail_screen.dart';

/// Full-screen mail search.
///
/// Typing filters the currently loaded messages client-side (subject, sender
/// name, sender address). Clearing the query restores the full loaded list.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _queryCtrl = TextEditingController();

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    setState(() {});
    ref.read(mailListProvider.notifier).search(q);
  }

  void _clearQuery() {
    _queryCtrl.clear();
    setState(() {});
    ref.read(mailListProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final MailListState state = ref.watch(mailListProvider);
    final results = state.displayedMails;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _queryCtrl,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search mail',
            border: InputBorder.none,
          ),
          onChanged: _onQueryChanged,
        ),
        actions: [
          if (_queryCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear search',
              onPressed: _clearQuery,
            ),
        ],
      ),
      body: state.isLoading && state.mails.isEmpty
          ? const MailListSkeleton()
          : results.isEmpty
              ? const EmptyMailState(
                  title: 'No results',
                  message: 'No messages match your search.',
                )
              : ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final mail = results[index];
                    return MailListItem(
                      mail: mail,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MailDetailScreen(mailId: mail.id, mail: mail),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}