# 📖 KiniHadir - Buku Panduan Pengguna (User Manual)

Selamat datang di **KiniHadir**, sistem informasi absensi cerdas berbasis biometrik wajah dan lokasi (GPS). Panduan ini ditujukan bagi dua kelompok pengguna utama: **Karyawan** dan **Administrator (HRD)**.

---

## 👨‍💼 BAGIAN 1: PANDUAN KARYAWAN

Bagian ini membahas cara Karyawan menggunakan aplikasi untuk melakukan presensi (*Clock-In* & *Clock-Out*) setiap harinya.

### 1.1. Akses Masuk (Login)
1. Buka aplikasi **KiniHadir** di *smartphone* Anda.
2. Anda memiliki dua pilihan login:
   - **Login via NIK**: Masukkan Nomor Induk Karyawan Anda (8-16 digit) dan *Password*.
   - **Login via Email**: Ketuk tab "Email", masukkan email kantor dan *Password*.
3. Jika Anda lupa kata sandi, ketuk tombol **"Lupa Password?"**. Masukkan email Anda, lalu cek kotak masuk (Inbox/Spam) email Anda untuk me-reset kata sandi.
4. Centang **"Ingat Saya"** (*Remember Me*) agar Anda tidak perlu *login* berulang kali setiap membuka aplikasi.
5. Ketuk **Login**.

### 1.2. Melakukan Absensi Harian
> ⚠️ **Pastikan GPS Aktif!** Aplikasi akan menolak akses absensi jika layanan Lokasi/GPS di HP Anda dalam keadaan mati.

1. Di halaman **Beranda (Dashboard)**, ketuk ikon jam berwarna hijau **Clock In** (untuk masuk kerja) atau warna biru **Clock Out** (untuk pulang kerja).
2. Anda akan diarahkan ke layar **Kamera Verifikasi Wajah**:
   - Posisikan wajah Anda tepat di dalam bingkai (kotak) di layar.
   - Kotak akan berwarna **Merah** jika wajah Anda belum terdeteksi, terlalu jauh, atau miring.
   - Kotak akan berubah menjadi **Hijau** jika wajah sudah sejajar.
3. Ketuk tombol bulat besar (Shutter) di bagian bawah untuk mengambil foto.
4. Di halaman Konfirmasi, sistem akan otomatis menghitung jarak Anda ke titik pusat kantor (Maksimal radius 500 meter).
5. Anda dapat menambahkan catatan (opsional), misal: "Izin telat macet di jalan".
6. Ketuk **Kirim Absen**. Tunggu hingga muncul notifikasi keberhasilan di layar Anda.

### 1.3. Mengecek Riwayat Kehadiran & Notifikasi
- **Riwayat**: Ketuk ikon kalender di menu navigasi bawah. Anda bisa melihat status kehadiran Anda. Anda juga dapat menggunakan filter tanggal (ikon kalender kecil di atas) untuk mencari riwayat spesifik.
- **Notifikasi**: Ketuk ikon lonceng di pojok kanan atas Beranda. Semua pengumuman dari kampus/kantor dan riwayat log kehadiran Anda tersimpan di sini.

---

## 👑 BAGIAN 2: PANDUAN ADMINISTRATOR (HRD)

Bagian ini khusus untuk HRD atau pihak manajemen yang memiliki hak akses `Admin`.

### 2.1. Memantau Statistik Karyawan (Dashboard)
Setelah Admin login, sistem akan otomatis masuk ke **Panel Admin**:
1. **Ringkasan Hari Ini**: Di bagian atas, Admin dapat melihat berapa banyak karyawan yang sudah absen secara *real-time*.
2. **Grafik KPI (Key Performance Indicator)**: 
   - **Tren Kehadiran (Bar Chart)**: Menampilkan jumlah karyawan yang masuk dari hari Senin - Minggu secara dinamis.
   - **Distribusi Status (Pie Chart)**: Menampilkan persentase jumlah karyawan yang *Hadir*, *Telat*, *Izin*, atau *Alpha* hari ini.

### 2.2. Mengelola Data Karyawan
1. Pindah ke tab **Daftar Karyawan** (menu bawah). Di sini Admin bisa melihat daftar lengkap seluruh karyawan terdaftar.
2. **Tambah Karyawan**: 
   - Ketuk tombol mengambang (`+`) berwarna emas di sudut kanan bawah.
   - Isi NIK (harus unik), Nama Lengkap, Email, dan Password sementara.
   - Karyawan baru bisa langsung *login* menggunakan NIK dan password tersebut.

### 2.3. Melihat Detail Log Karyawan & Export ke CSV
Admin dapat melacak kedisiplinan masing-masing individu secara detail:
1. Di layar Daftar Karyawan, ketuk nama salah satu karyawan.
2. Anda akan masuk ke halaman profil karyawan tersebut.
3. Ketuk tombol **Log Absensi**.
4. Semua riwayat jam masuk, titik GPS, dan foto wajah karyawan bersangkutan akan muncul di sini.
5. **Cetak Laporan**: Ketuk ikon **Unduh (⬇️)** di sudut kanan atas layar untuk men-*download* log dalam format `.csv` (bisa dibuka via Microsoft Excel). Aplikasi akan memunculkan menu untuk membagikan *file* tersebut ke WhatsApp atau menyimpannya di folder *Downloads* HP Anda.

---

## 🛠️ BAGIAN 3: TROUBLESHOOTING (PEMECAHAN MASALAH)

- **"Kenapa tombol foto tidak bisa ditekan?"**
  Pastikan wajah Anda tepat berada di kotak hijau. Fitur *Face Detection (ML Kit)* bekerja mencegah pengambilan absen tanpa wajah fisik.
- **"Jarak saya dengan kantor merah / di luar area!"**
  Terkadang GPS di dalam gedung beton meleset. Coba berjalan ke arah jendela / luar ruangan, lalu ketuk tombol **Refresh Koordinat** (Penyegaran) di halaman validasi.
- **"Tidak bisa login dengan NIK"**
  Hubungi Admin. Kemungkinan akun Anda didaftarkan tanpa mengisikan kolom NIK oleh Admin, atau Anda salah mengetikkan angka NIK.

---
*Untuk mengubah dokumen Markdown ini menjadi PDF, Anda dapat menggunakan fitur ekstensi "Markdown PDF" pada Visual Studio Code, atau menggunakan Online Markdown to PDF Converter.*
