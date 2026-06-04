<div align="center">
  <img src="assets/icons/app_icon.png" width="120" alt="KiniHadir Logo"/>
  <h1>KiniHadir</h1>
  <p><b>Sistem Informasi Absensi Cerdas & Aman Berbasis Biometrik Wajah dan GPS</b></p>
</div>

---

**KiniHadir** adalah aplikasi manajemen kehadiran (*Attendance Management*) modern yang dirancang untuk mempermudah HRD dan Karyawan dalam mengelola waktu kerja. Dibangun dengan standar industri menggunakan **Flutter** dan **Firebase** (Backend-as-a-Service), dilengkapi dengan fitur pendeteksi wajah *Real-Time* menggunakan *Machine Learning* dan keamanan pembatasan lokasi (*Geofencing*).

## ✨ Fitur Utama

### 👨‍💼 Panel Karyawan
* **Login Fleksibel**: Mendukung login menggunakan Email atau NIK Karyawan. Terintegrasi dengan fitur Lupa Password.
* **Smart Clock In & Clock Out**: Merekam kehadiran dengan akurasi tinggi.
* **Geofencing GPS**: Mencegah absensi palsu. Karyawan hanya dapat melakukan absen jika berada dalam radius (500 meter) dari kantor. Menggunakan formula *Haversine* untuk akurasi jarak.
* **ML Face Alignment**: Mewajibkan foto *selfie*, menggunakan **Google ML Kit** untuk memastikan orientasi wajah manusia nyata (mencegah absen layar hitam).
* **Riwayat & Filter Absensi**: Melacak riwayat kehadiran secara detail dengan dukungan Filter Tanggal.
* **Notifikasi Pintar (FCM)**: *Daily reminders* (pagi dan sore) serta konfirmasi sukses absen. Tersimpan dalam In-App Notification.

### 👑 Panel Admin (HRD)
* **Real-time KPI Dashboard**: Memantau statistik kehadiran harian, tren mingguan, dan keterlambatan menggunakan grafik interaktif.
* **Manajemen Karyawan Terpusat**: Registrasi akun karyawan baru langsung dari aplikasi dengan standar enkripsi Firebase.
* **Pemantauan Absensi Global**: Menampilkan daftar absen seluruh anggota tim lengkap dengan foto, jarak, dan catatan telat.
* **Export Laporan (CSV)**: HRD dapat mengekspor rekap bulanan ke dalam format *Spreadsheet* (.csv) yang bisa dibagikan langsung via WhatsApp/Email.

---

## 🛠️ Arsitektur & Teknologi

Aplikasi ini mengadopsi pola desain **Clean Architecture** (berbasis *Domain-Driven Design*) yang menjamin *codebase* agar tetap modular, *testable*, dan *scalable*. Terbagi menjadi 4 lapisan utama: `Core`, `Domain`, `Data`, dan `Presentation`.

* **Framework**: Flutter SDK (Dart)
* **Backend**: Firebase Authentication, Cloud Firestore, Cloud Storage, Cloud Messaging
* **State Management**: Provider (Reaktif & Ringan)
* **Routing**: GoRouter (Mendukung URL & Role Guard)
* **Pemetaan & Lokasi**: Geolocator (Akurasi Tinggi)
* **Computer Vision**: Camera + Google ML Kit Face Detection
* **Visualisasi Data**: FL Chart (Grafik) & Lottie (Animasi)
* **Keamanan**: Firebase Security Rules

---

## 📦 Panduan Instalasi (Untuk Developer)

### Persyaratan
* Flutter SDK versi terbaru (>= 3.9)
* Proyek Firebase dengan fitur Auth, Firestore, Storage, dan FCM yang sudah diaktifkan.

### Langkah-langkah
1. **Kloning Repositori**:
   ```bash
   git clone https://github.com/username/apbtugas.git
   cd apbtugas
   ```

2. **Setup Konfigurasi Firebase**:
   * Unduh file `google-services.json` (Android) dari Konsol Firebase.
   * Masukkan ke dalam *path*: `android/app/google-services.json`.

3. **Install Dependensi & Jalankan**:
   ```bash
   flutter pub get
   flutter run
   ```

---

## 🔒 Konfigurasi Keamanan Firebase (Firestore Rules)

Pastikan konfigurasi *rules* Firestore Anda sudah diperbarui seperti berikut untuk mendukung fitur Login NIK:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ─── USERS ───
    match /users/{userId} {
      allow read: if true; // Diperlukan untuk NIK Lookup
      allow write: if request.auth != null;
    }

    // ─── ATTENDANCE ───
    match /attendance/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /attendance/{document=**} {
      allow read, write: if request.auth != null; // Admin Access
    }

    // ─── NOTIFICATIONS ───
    match /notifications/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

<div align="center">
  <p><i>Dibuat sebagai Proyek Akhir Mata Kuliah Aplikasi Perangkat Bergerak (APB)</i></p>
</div>
