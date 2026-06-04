# 🚀 Presentasi: KiniHadir

*Slide referensi untuk keperluan demonstrasi atau pitching proyek.*

---

## Slide 1: Judul
**KiniHadir - Solusi Kehadiran Terintegrasi & Pintar**
*Tagline: "Membawa transparansi, disiplin, dan efisiensi ke dalam genggaman HRD dan Karyawan."*

---

## Slide 2: Latar Belakang Masalah
- **Validasi Kehadiran yang Lemah**: Titip absen sering terjadi pada sistem konvensional.
- **Kesulitan Rekap Data**: HRD harus merekap manual dari mesin *fingerprint* di berbagai lokasi.
- **Komunikasi Absensi Sulit**: Karyawan susah melacak rekap absen mereka sendiri atau memberi keterangan izin/sakit secara terintegrasi.

---

## Slide 3: Solusi Kami (KiniHadir)
1. **Verifikasi Geolocation**: Memastikan absensi (Clock In/Out) hanya bisa dilakukan di lokasi yang sah (radius 100m dari titik kantor).
2. **Face Detection (ML Kit)**: Tidak bisa memalsukan kehadiran karena aplikasi mendeteksi wajah secara *real-time* sebelum mengizinkan absensi.
3. **Cloud-Based (Firebase)**: Data tersinkronisasi seketika. Jika karyawan absen di lapangan, detik itu juga muncul di *dashboard* HRD.

---

## Slide 4: Fitur Utama (Karyawan)
- **One-Tap Clock In/Out** 🕒
- **Deteksi Wajah Real-Time** 🧑
- **Validasi Jarak Otomatis** 📍
- **Riwayat Lengkap & Notifikasi** 📊

---

## Slide 5: Fitur Utama (Admin / HRD)
- **Live Dashboard & KPI** 📈: Persentase kehadiran hari ini, jumlah telat, dan grafik tren 7 hari terakhir.
- **Manajemen Karyawan** 👥: Registrasi langsung melalui aplikasi tanpa perlu membuka konsol database.
- **Export Laporan (CSV)** 📥: Unduh data log absensi ke Excel/CSV langsung dari HP dan bagikan via WhatsApp/Email hanya dengan 1 kali klik.

---

## Slide 6: Tech Stack (Di Balik Layar)
- **Frontend**: Flutter (Dart) — mendukung performa tinggi, animasi mulus 60fps (menggunakan *Lottie*).
- **Backend & Auth**: Firebase Auth & Firestore.
- **Arsitektur**: Clean Architecture & Provider — kode sangat modular, mudah dirawat, dan siap diskalakan untuk ratusan karyawan.
- **Hardware Integration**: Camera API & Google ML Kit.

---

## Slide 7: Penutup / Demo Waktu
*"Mari kita lihat langsung bagaimana KiniHadir bekerja dalam demo interaktif!"*
**(Buka Aplikasi & Tunjukkan Alur Clock-In serta Tampilan Dashboard Admin)**
