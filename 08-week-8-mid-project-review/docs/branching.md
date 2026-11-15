# Branching Model

Satu branch, satu tujuan. Aturan ini dipakai sejak Minggu 8 untuk seluruh repository.

```
main      ──●────────────────────●─────────────  (rilis, dilindungi, tanpa commit langsung)
              \                  /
develop    ────●──●──●──●──●────●──────────────  (integrasi mingguan, target default PR)
                \    \     \  /
feature/*        ●────●     ●─                    (kerja harian, < 3 hari)
fix/*                  ●──●                       (perbaikan cepat + test)
```

| Branch | Peran | Aturan |
|:-------|:------|:-------|
| `main` | Selalu bisa dirilis, dilindungi | Tidak ada commit langsung; hanya lewat merge dari `develop` saat rilis |
| `develop` | Integrasi fitur mingguan | Target default semua Pull Request |
| `feature/*` | Kerja harian satu fitur | Pendek (< 3 hari), dibuat dari `develop` |
| `fix/*` | Perbaikan cepat + test | Sertakan langkah reproduksi di issue |
| `docs/*` | Perubahan dokumentasi saja | Tidak menyentuh kode produksi |
| `chore/*` | Tooling, CI, dependency | Tidak mengubah perilaku aplikasi |

## Alur kerja yang dipakai

```
issue #N → branch fix/N-nama-singkat
  → commit kecil (add -p) → PR "Closes #N"
  → review → squash merge → branch dihapus → issue tertutup
```

## Aturan operasional

1. `main` tidak disentuh langsung. Jika `develop` belum ada, buat sekali dari `main`, push,
   lalu jadikan target default PR.
2. Branch kerja selalu dibuat dari `develop` yang sudah di-`pull`.
3. Sinkronkan dengan `develop` setiap hari (`git pull --rebase origin develop`) agar branch
   tidak berumur panjang dan konflik tidak menumpuk.
4. Hapus branch setelah merge supaya daftar branch tetap pendek.
5. `git add -p` dipakai agar satu commit hanya memuat satu perubahan logis.

## Commit yang baik vs buruk

```
baik: feat(notes): validasi judul kosong pada dialog tambah catatan + test
baik: fix(notes): hentikan retry otomatis provider agar error lokal cepat tampil
baik: test(notes): perbaiki test provider error yang timeout + kasus countDirty
jelek: fix bug
jelek: update
jelek: final fix beneran
```

Format: `tipe(scope): deskripsi imperatif singkat`, dengan tipe
`feat`, `fix`, `refactor`, `test`, `docs`, `chore`.

## Branch aktif pada minggu 8

| Branch | Tujuan | PR |
|:-------|:-------|:---|
| `fix/notes-green-suite` | Fix test timeout, retry provider, `dart format`, test integrasi SQLite | PR #1 |
| `feat/notes-validation` | Validasi judul, SnackBar error, refactor orkestrasi sync | PR #2 |
| `chore/ci` | Workflow CI analyze + format + test | PR #3 |
| `docs/week8-mid-review` | Artefak review minggu 8 | PR #4 |
