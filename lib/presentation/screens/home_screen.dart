import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../../state/mail_provider.dart';
import '../widgets/mail_list_body.dart';
import '../widgets/mail_navigation_drawer.dart';
import 'compose_screen.dart';
import 'search_screen.dart';

/// The main mail screen: toolbar, folder-aware mail list and navigation.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _title = 'Inbox';
  String? _accountId;
  MailFolderType? _folder = MailFolderType.inbox;

  void _openFolder({
    required String title,
    String? accountId,
    MailFolderType? folder,
  }) {
    setState(() {
      _title = title;
      _accountId = accountId;
      _folder = folder;
    });
  }

  Future<void> _openSearch() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
    if (!mounted) return;
    ref.read(mailListProvider.notifier).load(
          accountId: _accountId,
          folderType: _folder,
        );
  }

  void _openCompose() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ComposeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Open navigation menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(_title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search mail',
            onPressed: _openSearch,
          ),
        ],
      ),
      drawer: MailNavigationDrawer(onSelectFolder: _openFolder),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCompose,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Compose'),
        tooltip: 'New message',
      ),
      body: MailListBody(
        key: ValueKey('$_accountId|${_folder?.name}'),
        accountId: _accountId,
        folder: _folder,
      ),
    );
  }
}