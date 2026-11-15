# Review Checklist — Mid Project Review (Minggu 8)

Dokumen ini berisi dua hal:

1. **Tabel sebelum/sesudah pesan commit** — penulisan ulang pesan commit lama menjadi format Conventional Commits.
2. **Checklist kesiapan paruh semester** — bukti bahwa fondasi project layak dilanjutkan ke paruh kedua.

Project yang direview: `05-week-5-local-storage-offline-first/week5_offline_notes`
(fitur offline-first: SQLite + `dirty flag` + antrean sync sederhana).

---

## 1. Tabel Sebelum / Sesudah Pesan Commit

Setiap baris menjelaskan **apa** yang diubah, **di mana** (scope), dan **buktinya**.

| No | Hash | Pesan Lama (Sebelum) | Format Konvensional (Sesudah) | Alasan & Bukti |
|:--:|:-----|:---------------------|:------------------------------|:---------------|
| 1 | `6e29d3f` | `feat: perubahan kecil + test` | `fix(notes): sesuaikan label status sinkronisasi pada note_detail_page + test` | **Apa**: teks label berubah dari `'Sudah tersinkron'` menjadi `'tersinkron'`.<br>**Di mana**: `lib/pages/note_detail_page.dart`, scope `(notes)`.<br>**Bukti**: `git show 6e29d3f` → 1 file, 1 baris (`1 insertion, 1 deletion`). Frasa "perubahan kecil" tidak memberi informasi apa pun bagi reviewer. |
| 2 | `87ca43d` | `list laporan final` | `docs(readme): tambah tautan laporan minggu 7 pada daftar laporan` | **Apa**: menambah satu baris tautan laporan di `README.md`.<br>**Di mana**: `README.md` root, scope `(readme)`.<br>**Bukti**: `git show 87ca43d` → `README.md | 3 ++-`; pesan lama tidak menyebut berkas maupun jenis perubahan. |
| 3 | `61d1083` | `Praktikum 3: Presentation, DI, dan verifikasi` | `refactor(notes): pindahkan fitur notes ke presentation/domain/data + test` | **Apa**: pemindahan kode `notes` ke struktur feature-first beserta wiring provider.<br>**Di mana**: `lib/features/notes/**` pada `07-week-7-clean-architecture/campus_notify`.<br>**Bukti**: `git show --stat 61d1083` menampilkan berkas baru di `features/notes/{domain,data,presentation}`; pesan lama berorientasi nomor praktikum, bukan isi perubahan. |

### Mengapa format ini dipilih

| Aspek | Pesan lama | Pesan konvensional |
|:------|:-----------|:-------------------|
| Tipe | sering salah/ambigu (`feat` untuk perbaikan teks) | `feat`/`fix`/`refactor`/`test`/`docs`/`chore` eksplisit |
| Scope | tidak ada | `(notes)`, `(readme)`, `(ci)` → reviewer tahu modul terdampak |
| Deskripsi | "perubahan kecil", "final fix" | imperatif, menyebut objek perubahan |
| Bukti | tidak ada | penanda `+ test` bila disertai pengujian |

> Catatan: pesan commit lama **tidak ditulis ulang di history** (history sudah ter-push dan dipakai bersama). Perbaikan dilakukan dengan **squash merge** saat PR masuk ke `develop`, sehingga yang terlihat di `develop` adalah judul PR yang sudah konvensional.

---

## 2. Checklist Kesiapan Paruh Semester

| # | Kriteria | Status | Bukti |
|:-:|:---------|:------:|:------|
| 1 | Struktur feature-first terbukti (tiga grep sterilitas) | ✅ | Lihat bagian 3 |
| 2 | `flutter analyze` bersih | ✅ | `No issues found!` (week5 & week7) |
| 3 | `dart format` rapi | ✅ week5 / ⚠️ week7 | week5: `Formatted 27 files (0 changed)`; week7 masih 15 file (issue lanjutan) |
| 4 | `flutter test` hijau | ✅ | week5: 23 test lulus; week7: 14 test lulus |
| 5 | PR kecil (< 300 baris) + commit jelas | ✅ | PR #2: 8 berkas, +308 / −51 baris, 5 commit bertipe |
| 6 | README + screenshot + cara menjalankan | ✅ | `08-week-8-mid-project-review/README.md` |
| 7 | Semua komentar review ditindaklanjuti | ✅ | `docs/pr-issue.md` |
| 8 | Issue tertutup otomatis oleh PR | ✅ | `Closes #<nomor-issue>` pada body PR |
| 9 | CI menolak PR kotor | ✅ | `.github/workflows/ci.yml` |
| 10 | Saran AI diverifikasi sebelum diterapkan | ✅ | `docs/ai-review-vs-keputusan.md` |

**Definisi selesai (dari codelab):** aplikasi berjalan identik dengan akhir Minggu 7, tiga
pemeriksaan mesin hijau, minimal 1 PR kecil sudah di-merge via review, dan README memuat
status paruh semester + peta issue/PR.

---

## 3. Bukti Tiga Grep Sterilitas

Dijalankan di `07-week-7-clean-architecture/campus_notify` (project hasil refactor Minggu 7):

```bash
# 1. Domain bebas framework
git grep -nE "import.*(flutter|dio|sqflite|firebase)" -- lib/features/*/domain/
# → tidak ada keluaran (0 temuan)

# 2. Entity bebas mapping
git grep -nE "(toJson|fromJson|toMap|fromMap)" -- lib/features/*/domain/entities/
# → tidak ada keluaran (0 temuan)

# 3. Widget bebas instansiasi repository
git grep -nE "Repository\(" -- lib/features/*/presentation/pages/
# → tidak ada keluaran (0 temuan)
```

Ketiga perintah di atas menghasilkan **exit code 1** (grep tidak menemukan pola), yang berarti
**lolos**.

### Penyimpangan yang diketahui pada `week5_offline_notes`

`week5_offline_notes` belum memakai struktur feature-first — kodenya dikelompokkan per tipe
(`lib/data`, `lib/pages`, `lib/widgets`). Ini **disengaja**: project tersebut adalah bahan
review, dan refactor feature-first sudah dikerjakan pada Minggu 7 (`campus_notify`). Temuan
yang tidak dimigrasikan dicatat sebagai issue lanjutan di `docs/pr-issue.md`, bukan
disembunyikan.
