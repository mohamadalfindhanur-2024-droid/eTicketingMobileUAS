# LAPORAN TUGAS / UTS PEMROGRAMAN MOBILE
**Judul Proyek:** Pengembangan UI/UX Aplikasi E-Ticketing Helpdesk Berbasis Flutter  
**Penyusun:** Alfin  
**NIM:** [NIM Anda]  

---

## BAB 1 - PENDAHULUAN

**1.1 Latar Belakang**  
Dalam era digital, layanan pelanggan atau *helpdesk* membutuhkan sistem manajemen keluhan (E-Ticketing) yang cepat dan mudah diakses melalui perangkat *mobile*. Aplikasi ini dibangun untuk memfasilitasi pelaporan masalah pengguna dan pengelolaan keluhan oleh admin (tim helpdesk) dalam satu platform antarmuka yang terintegrasi.

**1.2 Tujuan**  
* Menerapkan konsep *User Interface* (UI) berbasis desain Material 3 pada aplikasi Flutter.
* Menerapkan sistem navigasi yang efisien menggunakan pustaka `go_router` dan `ShellRoute`.
* Mengimplementasikan manajemen *state* *(State Management)* sederhana untuk membedakan hak akses (Role-Based) antara "Admin" dan "User", serta fitur pengubahan tema *(Dark/Light Mode)*.

---

## BAB 2 - TEKNOLOGI & ARSITEKTUR APLIKASI

**2.1 Teknologi yang Digunakan**
* **Framework:** Flutter (Dart)
* **Desain Sistem:** Material 3 (MaterialApp)
* **Routing:** `go_router` (untuk *deep linking* dan *Bottom Navigation Bar* persisten).
* **State Management:** `ValueNotifier` dan `ValueListenableBuilder` (ringan, bawaan Flutter, tanpa pustaka eksternal).

**2.2 Struktur State Management**
* `themeNotifier`: Digunakan untuk menyimpan status tema aktif (Light/Dark Mode) yang terhubung langsung pada `MaterialApp`.
* `profileNotifier`: Digunakan untuk menyimpan sesi Data User yang sedang login (Nama, Email, Role).

---

## BAB 3 - STYLE GUIDE

Style Guide adalah panduan visual yang mendefinisikan standar desain yang digunakan secara konsisten di seluruh aplikasi E-Ticketing Helpdesk.

### 3.1 Palet Warna (Color Palette)
Warna-warna berikut digunakan secara konsisten di seluruh antarmuka aplikasi:

* **Primary Blue (#2563EB)**: Warna utama AppBar, Button, Icon aktif
* **Dark Navy (#1E3A5F)**: Teks heading, elemen dark emphasis
* **Slate Gray (#64748B)**: Teks sekunder, subtitle, placeholder
* **Success Green (#16A34A)**: Status Resolved, pesan sukses
* **Warning Orange (#D97706)**: Status In Progress, prioritas Medium
* **Danger Red (#DC2626)**: Status error, prioritas High, tombol hapus
* **Light Blue Bg (#DBEAFE)**: Background badge, highlight ringan
* **Light Gray Bg (#F1F5F9)**: Background card, tabel alternate row
* **White (#FFFFFF)**: Background utama light mode

*Catatan: Pada Dark Mode, background utama berubah menggunakan `ColorScheme.fromSeed` dengan brightness: `Brightness.dark` dari Flutter Material 3. Seluruh warna accent (primary, success, warning, danger) tetap konsisten.*

### 3.2 Tipografi (Typography)
Aplikasi menggunakan font sistem default Flutter yang di-fallback ke font Arial/Roboto. Berikut hierarki teks yang digunakan:

* **App Title/Splash**: 26 sp | Bold | #FFFFFF | (Splash Screen, halaman hero)
* **Page Title (AppBar)**: 18 sp | Medium | #FFFFFF | (AppBar title semua halaman)
* **Section Heading**: 20 sp | Bold | #1E3A5F | (Judul tiket, heading card)
* **Card Title**: 15 sp | SemiBold | #1E3A5F | (Judul di ListTile tiket)
* **Body Text**: 14 sp | Regular | #333333 | (Deskripsi, isi konten)
* **Caption/Meta**: 12 sp | Regular | #64748B | (Tanggal, ID tiket, subtitle)
* **Badge Label**: 11 sp | Bold | Sesuai status | (StatusBadge, PriorityBadge)
* **Button Label**: 16 sp | Medium | #FFFFFF | (ElevatedButton, FAB)
* **Input Label**: 14 sp | Regular | #333333 | (TextField labelText)

### 3.3 Komponen UI (UI Components)

**3.3.1 Button**
`ElevatedButton` digunakan sebagai tombol aksi utama. Spesifikasi:
* Background: #2563EB (Primary Blue)
* Text Color: #FFFFFF (White), ukuran 16 sp
* Border Radius: 8px
* Minimum Size: lebar penuh (double infinity) x 48px
* State loading: `CircularProgressIndicator` warna putih

**3.3.2 TextField / Input**
* Border: `OutlineInputBorder`, radius 8px
* Content Padding: horizontal 16px, vertical 14px
* Filled: true, fillColor abu-abu muda (#F8FAFC) pada light mode
* Prefix icon untuk konteks (email, lock, title, dll)
* Suffix icon toggle visibility untuk password field

**3.3.3 Card**
* Elevation: 2
* Border Radius: 12px
* Digunakan pada: tiket list item, stat card dashboard

**3.3.4 StatusBadge**
* **Open:** Warna biru utama (#2563EB), outline tebal, teks bold. (Menandakan tiket baru).
* **In Progress:** Warna badge oranye (#D97706). (Menandakan sedang diproses).
* **Resolved:** Warna hijau (#16A34A). (Menandakan keluhan selesai).
* **Closed:** Warna abu-abu / Slate Gray (#64748B). (Menandakan ditutup).

---

## BAB 4 - IMPLEMENTASI & FITUR UTAMA

**4.1 Halaman Login (`LoginScreen`)**  
Berfungsi sebagai pintu masuk autentikasi pengguna. Menggunakan validasi akun dinamis terhadap database in-memory:
* **Admin:** Login menggunakan `admin@example.com` (password: `admin123`).
* **Helpdesk:** Login menggunakan `helpdesk@example.com` (password: `helpdesk123`).
* **User:** Login menggunakan `user@example.com` (password: `user123`) atau akun hasil registrasi baru.
* Mendukung deteksi status akun aktif/nonaktif (akun yang dinonaktifkan Admin tidak dapat login).

**4.2 Halaman Registrasi (`RegisterScreen`) & Lupa Password (`ForgotPasswordScreen`)**  
* **Registrasi:** Memungkinkan pembuatan akun baru dengan mengisi Nama, Email, Password, Konfirmasi Password, serta pilihan Role (User/Helpdesk/Admin) untuk simulasi. Akun baru akan langsung disimpan ke database in-memory.
* **Lupa Password:** Alur pemulihan kata sandi dengan 3 langkah interaktif: verifikasi email terdaftar, penginputan kode OTP simulasi (`12345`), dan pembuatan password baru.

**4.3 Navigasi Utama (`MainScaffold`)**  
Aplikasi menggunakan *BottomNavigationBar* yang persisten berbasis `go_router`. Jika pengguna berpindah menu (Dashboard, Tiket, Notifikasi, Profil), navigasi bawah tidak akan hilang. FAB (*Floating Action Button*) diletakkan di tengah dengan ukuran responsif (hanya muncul untuk peran *User*).

**4.4 Tampilan Berdasarkan Peran (Role-Based UI)**  
Antarmuka beradaptasi secara dinamis mengecek `profileNotifier.value.role`:
* **Bagi Pengguna (User):** Dapat membuat tiket keluhan baru melalui FAB (+), melihat ringkasan statistik tiket pribadi di Dashboard, serta mengirim tanggapan/komentar pada tiket miliknya.
* **Bagi Helpdesk:** Dapat melihat tiket yang ditugaskan kepada dirinya, memproses status tiket (*In Progress*, *Resolved*, *Closed*), dan berdiskusi melalui tab komentar tiket.
* **Bagi Admin:** Dapat melihat seluruh tiket sistem, melakukan penugasan (*assign*) tiket ke petugas helpdesk tertentu, mengubah status tiket secara paksa, serta mengakses halaman Kelola Pengguna.

**4.5 Detail Tiket Interaktif (Komentar & Riwayat)**  
Halaman detail tiket terbagi menjadi tiga tab fungsional:
* **Tab Detail:** Menampilkan metadata lengkap tiket, lampiran gambar, serta kontrol aksi sesuai peran pengguna yang sedang aktif (seperti penugasan helpdesk untuk Admin, tombol "Tandai Selesai" untuk Helpdesk).
* **Tab Komentar:** Antarmuka obrolan (*chat-like*) responsif yang membedakan warna gelembung obrolan pengirim dengan pengguna lain secara real-time.
* **Tab Riwayat:** Menampilkan log jejak aktivitas tiket (waktu pembuatan, perubahan status, penugasan petugas, hingga komentar masuk) dalam bentuk visualisasi *timeline* vertikal.

**4.6 Halaman Kelola Pengguna (`UserManagementScreen`)**  
Fitur khusus Admin untuk mengelola seluruh akun pengguna di dalam sistem. Admin dapat melihat daftar nama/email, mengganti peran (*role*) pengguna secara langsung, serta mengaktifkan/menonaktifkan akun.

**4.7 Simulasi Lampiran Gambar & Notifikasi Terintegrasi**  
* **Simulasi Lampiran:** Di halaman buat tiket, pengguna dapat mensimulasikan pengambilan gambar dari kamera atau galeri dengan animasi loading singkat dan pratinjau nama berkas gambar.
* **Notifikasi:** Halaman notifikasi menampilkan pemberitahuan perubahan status tiket atau komentar baru. Mengetuk notifikasi akan otomatis menandai notifikasi telah dibaca dan langsung mengarahkan pengguna ke halaman detail tiket terkait.

**4.8 Manajemen Dark Mode & Light Mode**  
Aplikasi mendukung warna dinamis menggunakan `Brightness.dark` dan `Brightness.light`. Seluruh warna *background*, warna teks, dan warna *card* (kartu) akan menyesuaikan secara *real-time* ketika *switch theme* ditekan di menu Profil tanpa perlu me-*restart* aplikasi.

---

## BAB 5 - KESIMPULAN

Aplikasi E-Ticketing Helpdesk ini berhasil mengimplementasikan *User Interface* modern yang responsif dan fungsional. Melalui penggunaan navigasi modern (`go_router`) dan manajemen *state* reaktif (`ValueNotifier`), aplikasi mampu beradaptasi dengan status tema (Gelap/Terang), mengaplikasikan *Style Guide* dengan akurat, serta membedakan hak akses *login* antara User biasa dengan Admin Helpdesk secara efisien dalam satu *codebase*.
