import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/note_search.dart';
import '../data/local/note.dart';
import '../data/note_providers.dart';
import '../data/sync.dart';
import '../widgets/add_note_dialog.dart';
import '../widgets/note_tile.dart';
import '../widgets/notes_search_field.dart';

/// Orkestrasi sync milik lapisan presentasi: memanggil use case data layer
/// lalu menyegarkan provider. Sebelumnya fungsi ini tinggal di `lib/data`
/// dan menerima `WidgetRef`, sehingga data layer bergantung pada Flutter.
Future<int> _syncNotes(WidgetRef ref) async {
  final synced = await syncNotes(
    ref.read(noteRepositoryProvider),
    forceOffline: ref.read(forceOfflineProvider),
  );
  ref.invalidate(notesProvider);
  ref.invalidate(dirtyCountProvider);
  return synced;
}

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final dirtyCount = ref.watch(dirtyCountProvider);
    final forceOffline = ref.watch(forceOfflineProvider);
    final query = ref.watch(noteSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        actions: [
          IconButton(
            onPressed: () => context.push('/ai'),
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Tanya catatan (AI)',
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan',
          ),
          IconButton(
            onPressed: () => _addNote(context, ref),
            icon: const Icon(Icons.add),
            tooltip: 'Add note',
          ),
          dirtyCount.when(
            data: (count) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: Text('Dirty: $count')),
            ),
            error: (_, _) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Force offline'),
            subtitle: Text(forceOffline ? 'Sync disabled' : 'Sync enabled'),
            value: forceOffline,
            onChanged: (value) =>
                ref.read(forceOfflineProvider.notifier).set(value),
          ),
          dirtyCount.when(
            data: (count) =>
                _SyncStatus(forceOffline: forceOffline, dirtyCount: count),
            error: (_, _) => const SizedBox.shrink(),
            loading: () => const LinearProgressIndicator(),
          ),
          NotesSearchField(
            value: query,
            onChanged: (value) =>
                ref.read(noteSearchQueryProvider.notifier).set(value),
          ),
          Expanded(
            child: notes.when(
              data: (items) => _NotesList(
                items: searchNotes(items, query),
                totalCount: items.length,
                query: query,
              ),
              error: (error, _) => Center(child: Text('Error: $error')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final count = await _syncNotes(ref);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                forceOffline
                    ? 'Offline mode: sync skipped'
                    : 'Synced $count note(s)',
              ),
            ),
          );
        },
        icon: const Icon(Icons.sync),
        label: Text(forceOffline ? 'Offline' : 'Sync now'),
      ),
    );
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final draft = await AddNoteDialog.show(context);
    if (draft == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(noteRepositoryProvider)
          .addNote(title: draft.title, body: draft.body);
    } catch (error) {
      // Sebelumnya exception SQLite naik tanpa jejak di UI, sehingga pengguna
      // mengira catatan tersimpan padahal gagal.
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menyimpan catatan: $error')),
      );
      return;
    }
    ref.invalidate(notesProvider);
    ref.invalidate(dirtyCountProvider);
  }
}

class _SyncStatus extends StatelessWidget {
  const _SyncStatus({required this.forceOffline, required this.dirtyCount});

  final bool forceOffline;
  final int dirtyCount;

  @override
  Widget build(BuildContext context) {
    final isSynced = dirtyCount == 0;
    final color = forceOffline ? Colors.orange : Colors.teal;
    final title = forceOffline ? 'FORCE OFFLINE' : 'ONLINE MODE';
    final detail = forceOffline
        ? 'Local cache aktif - sync ditahan'
        : isSynced
        ? 'Semua catatan sudah tersinkron'
        : '$dirtyCount catatan menunggu sync';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(forceOffline ? Icons.wifi_off : Icons.cloud_done, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              Text(detail),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotesList extends ConsumerWidget {
  const _NotesList({
    required this.items,
    required this.totalCount,
    required this.query,
  });

  final List<Note> items;
  final int totalCount;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      // Dua keadaan kosong yang berbeda penyebab dan berbeda tindakan:
      // belum punya catatan sama sekali, versus filter tidak menemukan apa pun.
      if (totalCount == 0) {
        return const Center(child: Text('Belum ada catatan'));
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'Tidak ada catatan yang cocok dengan "${query.trim()}"',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () =>
                    ref.read(noteSearchQueryProvider.notifier).clear(),
                icon: const Icon(Icons.clear),
                label: const Text('Hapus filter'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final note = items[index];
        return NoteTile(
          note: note,
          onDelete: note.id == null
              ? null
              : () async {
                  await ref.read(noteRepositoryProvider).deleteNote(note.id!);
                  ref.invalidate(notesProvider);
                  ref.invalidate(dirtyCountProvider);
                },
        );
      },
    );
  }
}
