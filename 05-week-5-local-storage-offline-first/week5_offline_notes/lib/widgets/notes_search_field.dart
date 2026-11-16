import 'package:flutter/material.dart';

/// Kolom pencarian judul catatan.
///
/// Widget ini hanya mengurus tampilan dan `TextEditingController`; aturan
/// filter tinggal di `lib/core/note_search.dart`. Nilai [value] dikontrol dari
/// luar supaya tombol "hapus filter" pada empty state bisa mengosongkan kolom
/// ini tanpa memegang controller-nya.
class NotesSearchField extends StatefulWidget {
  const NotesSearchField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<NotesSearchField> createState() => _NotesSearchFieldState();
}

class _NotesSearchFieldState extends State<NotesSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant NotesSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari judul catatan',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: widget.value.isEmpty
              ? null
              : IconButton(
                  onPressed: _clear,
                  icon: const Icon(Icons.clear),
                  tooltip: 'Hapus pencarian',
                ),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}
