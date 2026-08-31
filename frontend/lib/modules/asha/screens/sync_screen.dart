import 'package:flutter/material.dart';
import 'package:smriti/core/repository_listener.dart';
import 'package:smriti/core/theme.dart';
import 'package:smriti/modules/asha/data/asha_repository.dart';
import 'package:smriti/modules/asha/widgets/sync_status_badge.dart';
import 'package:smriti/widgets/sign_out_button.dart';

/// Panel 3 of 3. A status view, never a gate — the app stays fully usable regardless
/// of what's shown here. Demo behavior: airplane mode on, use the app, reconnect, watch it drain.
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> with RepositoryListener {
  final _repo = AshaRepository.instance;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    // Anything logged on the other panels lands in this outbox.
    listenTo([_repo.onChange]);
  }

  @override
  Widget build(BuildContext context) {
    final outbox = _repo.outbox.reversed.toList();
    final pendingCount = outbox.where((e) => e.state != SyncState.synced).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Sync'), actions: const [SignOutButton()]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    pendingCount == 0
                        ? 'Everything is synced.'
                        : '$pendingCount item${pendingCount == 1 ? '' : 's'} waiting for connectivity.',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                  onPressed: pendingCount == 0 || _syncing
                      ? null
                      : () async {
                          setState(() => _syncing = true);
                          await _repo.drainOutbox();
                          setState(() => _syncing = false);
                        },
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('Sync now'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: outbox.isEmpty
                ? const Center(child: Text('Nothing queued yet.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: outbox.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = outbox[index];
                      return Card(
                        child: ListTile(
                          title: Text(entry.description),
                          trailing: SyncStatusBadge(state: entry.state),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
