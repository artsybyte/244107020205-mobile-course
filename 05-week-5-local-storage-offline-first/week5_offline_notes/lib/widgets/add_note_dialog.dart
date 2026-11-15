import 'package:flutter/material.dart';

import '../core/note_validator.dart';

/// Hasil dialog tambah catatan. `null` berarti pengguna membatalkan.
typedef NoteDraft = ({String title, String body});

/// Dialog tambah catatan dengan validasi judul di dalam form.
///
/// Validasi ditangani [TextFormField.validator] sehingga pesan error tampil
/// langsung di bawah field dan dialog tetap terbuka selama input belum valid.
class AddNoteDialog extends StatefulWidget {
  const AddNoteDialog({super.key});

  /// Menampilkan dialog dan mengembalikan [NoteDraft] bila disimpan.
  static Future<NoteDraft?> show(BuildContext context) {
    return showDialog<NoteDraft>(
      context: context,
      builder: (_) => const AddNoteDialog(),
    );
  }

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop<NoteDraft>(context, (
      title: normalizeNoteTitle(_titleController.text),
      body: _bodyController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New note'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              maxLength: maxNoteTitleLength,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: validateNoteTitle,
            ),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: 'Body'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
