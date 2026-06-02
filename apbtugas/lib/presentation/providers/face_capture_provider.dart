import 'dart:io';
import 'dart:ui' show Size;
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

// ═══════════════════════════════════════════════════════════
// Face Validation State
// ═══════════════════════════════════════════════════════════

enum FaceValidationStatus {
  idle,
  detecting,
  noFace,
  multipleFaces,
  blurry,
  tooDark,
  passed,
  capturing,
  uploading,
  success,
  failed,
}

enum LightingStatus { unknown, tooDark, adequate }

class FaceCaptureProvider extends ChangeNotifier {
  // ── Camera ──────────────────────────────────────────────────
  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;
  bool get isCameraReady =>
      _cameraController != null && _cameraController!.value.isInitialized;

  // ── Face Detection ───────────────────────────────────────────
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15,
    ),
  );

  // ── Validation State ─────────────────────────────────────────
  FaceValidationStatus _status = FaceValidationStatus.idle;
  FaceValidationStatus get status => _status;

  int _faceCount = 0;
  int get faceCount => _faceCount;

  double _sharpnessScore = 0.0;
  double get sharpnessScore => _sharpnessScore;

  LightingStatus _lightingStatus = LightingStatus.unknown;
  LightingStatus get lightingStatus => _lightingStatus;

  String _statusMessage = 'Siapkan kamera depan...';
  String get statusMessage => _statusMessage;

  bool get canCapture => _status == FaceValidationStatus.passed;

  // ── Capture Result ───────────────────────────────────────────
  String? _capturedImagePath;
  String? get capturedImagePath => _capturedImagePath;

  String? _selfieUrl;
  String? get selfieUrl => _selfieUrl;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isProcessingFrame = false;

  // ── Lifecycle ────────────────────────────────────────────────

  Future<void> initCamera(List<CameraDescription> cameras) async {
    // Find front camera
    CameraDescription? frontCamera;
    for (final cam in cameras) {
      if (cam.lensDirection == CameraLensDirection.front) {
        frontCamera = cam;
        break;
      }
    }
    if (frontCamera == null && cameras.isNotEmpty) {
      frontCamera = cameras.first;
    }
    if (frontCamera == null) {
      _setStatus(FaceValidationStatus.failed, 'Kamera tidak ditemukan');
      return;
    }

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      _setStatus(FaceValidationStatus.detecting, 'Arahkan wajah ke kamera...');
      _startImageStream();
      notifyListeners();
    } catch (e) {
      _setStatus(FaceValidationStatus.failed, 'Gagal inisialisasi kamera: $e');
    }
  }

  void _startImageStream() {
    _cameraController?.startImageStream((CameraImage image) async {
      if (_isProcessingFrame) return;
      if (_status == FaceValidationStatus.capturing ||
          _status == FaceValidationStatus.uploading ||
          _status == FaceValidationStatus.success) {
        return;
      }

      _isProcessingFrame = true;
      try {
        await _processFrame(image);
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  Future<void> _processFrame(CameraImage image) async {
    try {
      // ─── Lighting check via average pixel brightness ───────────
      final avgBrightness = _computeAverageBrightness(image);
      if (avgBrightness < 40) {
        _lightingStatus = LightingStatus.tooDark;
        _setStatus(FaceValidationStatus.tooDark, 'Pencahayaan terlalu gelap. Cari tempat lebih terang.');
        return;
      }
      _lightingStatus = LightingStatus.adequate;

      // ─── Blur / sharpness check (Laplacian variance approx) ───
      _sharpnessScore = _computeSharpness(image);
      if (_sharpnessScore < 8.0) {
        _setStatus(FaceValidationStatus.blurry, 'Gambar blur. Pastikan kamera tidak goyang.');
        return;
      }

      // ─── ML Kit face detection ─────────────────────────────────
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final faces = await _faceDetector.processImage(inputImage);
      _faceCount = faces.length;

      if (faces.isEmpty) {
        _setStatus(FaceValidationStatus.noFace, 'Tidak ada wajah terdeteksi. Posisikan wajah di frame.');
      } else if (faces.length > 1) {
        _setStatus(FaceValidationStatus.multipleFaces, 'Terdeteksi ${faces.length} wajah. Pastikan hanya 1 wajah.');
      } else {
        // All validations passed
        _setStatus(FaceValidationStatus.passed, '✓ Wajah terdeteksi. Siap capture!');
      }
    } catch (e) {
      // Silently ignore frame processing errors — next frame will retry
      debugPrint('Frame processing error: $e');
    }
  }

  // ─── Sharpness: simplified Laplacian variance on Y plane ────────
  double _computeSharpness(CameraImage image) {
    try {
      final yPlane = image.planes[0].bytes;
      final width = image.width;
      final height = image.height;

      double sum = 0;
      int count = 0;
      final stepX = (width ~/ 20).clamp(1, 99999);
      final stepY = (height ~/ 20).clamp(1, 99999);

      for (int y = 1; y < height - 1; y += stepY) {
        for (int x = 1; x < width - 1; x += stepX) {
          final idx = y * width + x;
          if (idx + width + 1 >= yPlane.length || idx - width - 1 < 0) continue;
          final laplacian = (4 * yPlane[idx]) -
              yPlane[idx - 1] -
              yPlane[idx + 1] -
              yPlane[idx - width] -
              yPlane[idx + width];
          sum += laplacian * laplacian;
          count++;
        }
      }
      return count > 0 ? sum / count : 0;
    } catch (_) {
      return 99.0; // Assume sharp if we can't compute
    }
  }

  // ─── Average brightness on Y plane ──────────────────────────────
  double _computeAverageBrightness(CameraImage image) {
    try {
      final yPlane = image.planes[0].bytes;
      if (yPlane.isEmpty) return 128.0;
      double sum = 0;
      final step = (yPlane.length ~/ 500).clamp(1, 99999);
      int count = 0;
      for (int i = 0; i < yPlane.length; i += step) {
        sum += yPlane[i];
        count++;
      }
      return count > 0 ? sum / count : 128.0;
    } catch (_) {
      return 128.0;
    }
  }

  // ─── Capture & Upload ────────────────────────────────────────────

  Future<String?> captureAndUpload() async {
    if (!canCapture || _cameraController == null) return null;

    _setStatus(FaceValidationStatus.capturing, 'Mengambil foto...');
    try {
      // Stop stream before taking picture
      await _cameraController!.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 200));

      final XFile photo = await _cameraController!.takePicture();
      _capturedImagePath = photo.path;

      _setStatus(FaceValidationStatus.uploading, 'Mengunggah foto...');

      // Upload to Firebase Storage
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final fileName =
          '${now.millisecondsSinceEpoch}_${now.hour}${now.minute}.jpg';
      final storagePath = 'attendance/$userId/$dateStr/$fileName';

      final ref = FirebaseStorage.instance.ref().child(storagePath);
      final uploadTask = ref.putFile(File(photo.path));
      final snapshot = await uploadTask;
      _selfieUrl = await snapshot.ref.getDownloadURL();

      _setStatus(FaceValidationStatus.success, 'Foto berhasil diambil!');
      return _selfieUrl;
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(FaceValidationStatus.failed, 'Gagal mengambil foto: $e');
      // Restart stream if capture failed
      _startImageStream();
      return null;
    }
  }

  void retryCapture() {
    _capturedImagePath = null;
    _selfieUrl = null;
    _errorMessage = null;
    _faceCount = 0;
    _sharpnessScore = 0;
    _lightingStatus = LightingStatus.unknown;
    _setStatus(FaceValidationStatus.detecting, 'Arahkan wajah ke kamera...');
    _startImageStream();
  }

  void _setStatus(FaceValidationStatus status, String message) {
    _status = status;
    _statusMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream().catchError((_) {});
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }
}
