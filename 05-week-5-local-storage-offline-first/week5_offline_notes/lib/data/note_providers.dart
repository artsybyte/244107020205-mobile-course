import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local/note.dart';
import 'repositories/note_repository.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

/// Query pencarian judul catatan.
///
/// Disimpan di provider (bukan `setState` di halaman) supaya empty state bisa
/// mengosongkan filter tanpa memegang `TextEditingController` halaman.
class NoteSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;

  void clear() => state = '';
}

final noteSearchQueryProvider =
    NotifierProvider<NoteSearchQueryNotifier, String>(
      NoteSearchQueryNotifier.new,
    );

// Error database lokal tidak akan pulih sendiri, jadi retry otomatis Riverpod
// (backoff eksponensial) dimatikan agar ErrorView langsung tampil alih-alih
// spinner berputar puluhan detik.
Duration? _noRetry(int retryCount, Object error) => null;

final notesProvider = FutureProvider<List<Note>>(
  (ref) => ref.watch(noteRepositoryProvider).fetchNotes(),
  retry: _noRetry,
);

final noteDetailProvider = FutureProvider.family<Note?, int>(
  (ref, id) => ref.watch(noteRepositoryProvider).fetchNote(id),
  retry: _noRetry,
);

final dirtyCountProvider = FutureProvider<int>(
  (ref) => ref.watch(noteRepositoryProvider).countDirty(),
  retry: _noRetry,
);
