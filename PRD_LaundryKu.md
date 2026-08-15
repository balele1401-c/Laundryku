# PRD — LaundryKu
**Aplikasi Manajemen Laundry Kiloan untuk UMKM**

Versi: 1.0
Tanggal: 15 Agustus 2026
Author: Iqbal

---

## 1. Latar Belakang & Masalah

Sebagian besar usaha laundry kiloan skala kecil di Indonesia masih mengelola operasional secara manual: nota kertas, buku catatan, dan pemberitahuan pelanggan lewat WhatsApp manual satu per satu. Masalah yang sering muncul:

- Nota hilang/rusak → sengketa berat cucian dan harga
- Owner lupa menghubungi pelanggan saat cucian selesai
- Tidak ada rekap omzet harian/bulanan yang rapi
- Sulit melacak riwayat pelanggan (cucian yang belum diambil, pelanggan langganan)

**LaundryKu** adalah aplikasi mobile POS sederhana untuk usaha laundry kiloan, membantu owner mencatat transaksi, melacak status cucian, dan mengirim notifikasi otomatis ke pelanggan.

---

## 2. Tujuan Produk

1. Menggantikan pencatatan manual dengan sistem digital yang cepat dipakai kasir/owner
2. Mengurangi kesalahan pencatatan berat & harga
3. Meningkatkan kepuasan pelanggan lewat notifikasi otomatis
4. Memberi owner visibilitas omzet & performa usaha secara real-time

---

## 3. Target Pengguna

| Role | Deskripsi |
|---|---|
| **Owner/Admin** | Pemilik usaha laundry, akses penuh: kelola harga, laporan, semua transaksi |
| **Kasir/Karyawan** | Input transaksi harian, update status cucian, tidak bisa lihat laporan keuangan lengkap |
| **Pelanggan** (opsional, fase 2) | Terima notifikasi status via WA, tidak perlu install app |

MVP fokus ke **Owner & Kasir** sebagai pengguna aplikasi. Pelanggan hanya menerima notifikasi WA, tanpa perlu app terpisah.

---

## 4. Fitur Utama (MVP)

### 4.1 Autentikasi
- Login email/password (Firebase Auth)
- Role-based access: Owner vs Kasir

### 4.2 Input Transaksi Cucian
- Pilih/tambah pelanggan (nama, no. HP)
- Jenis layanan: kiloan (reguler/express) atau satuan (item tertentu)
- Input berat (kg) atau jumlah item
- Tambahan layanan: parfum, setrika saja, dll
- Auto-hitung total harga berdasarkan tarif yang di-set owner
- Generate nomor nota otomatis

### 4.3 Tracking Status Cucian
Status flow:
`Diterima → Proses Cuci → Proses Setrika/Lipat → Siap Diambil → Selesai/Diambil`

- Kasir update status per transaksi
- List transaksi bisa difilter per status
- Highlight cucian yang sudah "Siap Diambil" lebih dari X hari (reminder visual untuk owner)

### 4.4 Notifikasi WhatsApp Otomatis
- Kirim WA otomatis ke pelanggan saat status berubah jadi "Siap Diambil"
- Menggunakan API pihak ketiga (Fonnte / sejenis) — bukan WhatsApp Business API resmi (lebih murah & simpel untuk skala kecil)
- Template pesan bisa diedit owner

### 4.5 Riwayat & Data Pelanggan
- Daftar pelanggan dengan riwayat transaksi
- Total belanja per pelanggan (opsional: identifikasi pelanggan loyal)
- Pencarian pelanggan by nama/no. HP

### 4.6 Manajemen Harga & Layanan
- Owner bisa set/edit tarif per kg, per item, layanan tambahan
- Multiple paket layanan (reguler 3 hari, express 1 hari, dll)

### 4.7 Laporan
- Omzet harian, mingguan, bulanan
- Jumlah transaksi & cucian yang belum diambil
- Export sederhana (opsional: PDF/print nota)

---

## 5. Fitur Fase 2 (Bukan MVP)

- Pembayaran online / DP via Midtrans
- Aplikasi terpisah untuk pelanggan (cek status sendiri)
- Multi-cabang untuk laundry dengan lebih dari 1 outlet
- Program loyalty/member (misal cuci ke-10 gratis)
- Cetak struk thermal printer

---

## 6. Tech Stack

| Layer | Teknologi |
|---|---|
| Frontend | Flutter |
| State Management | Provider |
| Backend/DB | Firebase (Firestore) |
| Auth | Firebase Authentication |
| Notifikasi WA | Fonnte API (atau alternatif sejenis) |
| Upload gambar (opsional, bukti cucian) | Cloudinary |
| Hosting/Build | Android APK (fase awal), iOS menyusul jika perlu |

---

## 7. Struktur Data (Firestore — garis besar)

**Collection: `users`**
- uid, nama, role (owner/kasir), laundryId

**Collection: `customers`**
- id, nama, noHp, totalTransaksi, createdAt

**Collection: `transactions`**
- id, customerId, nomorNota, jenisLayanan, berat/qty, hargaSatuan, totalHarga, status, tanggalMasuk, estimasiSelesai, createdBy, createdAt, updatedAt

**Collection: `services`**
- id, namaLayanan, tipe (kiloan/satuan), harga, estimasiHari

**Collection: `laundry_settings`** (per usaha, untuk multi-tenant di masa depan)
- namaUsaha, alamat, waTemplate, tarifDefault

---

## 8. Alur Pengguna Utama (User Flow)

1. Kasir login → dashboard
2. Kasir input transaksi baru → pilih/tambah pelanggan → pilih layanan → input berat → sistem hitung total → simpan
3. Nota otomatis ter-generate, status default "Diterima"
4. Kasir update status seiring progres cucian
5. Saat status "Siap Diambil" → sistem kirim WA otomatis ke pelanggan
6. Pelanggan datang ambil cucian → kasir update status "Selesai"
7. Owner buka laporan → lihat omzet & transaksi harian/bulanan

---

## 9. Kriteria Sukses MVP

- Bisa dipakai untuk mencatat transaksi end-to-end tanpa bug kritis
- Notifikasi WA terkirim otomatis dengan akurat
- Laporan omzet sesuai dengan total transaksi yang tercatat
- Berhasil dipakai riil oleh minimal 1 laundry (uji coba/demo) dalam waktu 2 minggu setelah selesai dev

---

## 10. Batasan & Asumsi

- MVP hanya untuk 1 outlet/cabang (belum multi-tenant penuh)
- Notifikasi WA bergantung pada kuota/API pihak ketiga (perlu API key aktif)
- Tidak menangani pembayaran online di MVP — transaksi dianggap cash/manual dicatat lunas atau belum
- Asumsi pengguna (kasir) minimal familiar dengan smartphone Android dasar

---

## 11. Rencana Development (Step Breakdown — untuk OpenCode)

Disarankan dipecah jadi step-step kecil seperti pola project sebelumnya:

1. Setup project Flutter + Firebase (Auth, Firestore)
2. Struktur folder & state management (Provider)
3. Auth: login & role-based routing (Owner/Kasir)
4. CRUD pelanggan
5. CRUD layanan & tarif (khusus Owner)
6. Form input transaksi + kalkulasi harga otomatis
7. List transaksi + filter by status
8. Update status transaksi (flow status)
9. Integrasi notifikasi WA (Fonnte) saat status "Siap Diambil"
10. Dashboard laporan (omzet harian/bulanan)
11. Riwayat & pencarian pelanggan
12. Polish UI/UX + testing end-to-end
13. Firestore security rules (role-based)
14. Build APK & uji coba ke laundry pertama

---

## 12. Peluang Monetisasi

- Jual putus ke 1 laundry: Rp 500rb–1,5jt
- Model langganan: Rp 50rb–150rb/bulan (termasuk maintenance & kuota notif WA)
- Setelah MVP jalan di 1 klien, replikasi ke laundry lain dengan effort kecil (rebrand nama usaha, sesuaikan tarif)
