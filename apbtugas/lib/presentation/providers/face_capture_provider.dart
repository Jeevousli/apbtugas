import 'dart:io';
import 'dart:convert';
import 'dart:ui' show Size;
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
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
  bool _isDisposed = false;

  // ── Rotation helper ──────────────────────────────────────────
  InputImageRotation _sensorRotation = InputImageRotation.rotation270deg;

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

    // Compute rotation from sensor orientation
    _sensorRotation = _rotationFromSensorDegrees(frontCamera.sensorOrientation);

    // Use bgra8888 on iOS, yuv420 on Android — MLKit needs NV21 (YUV) on Android
    final formatGroup = Platform.isIOS
        ? ImageFormatGroup.bgra8888
        : ImageFormatGroup.yuv420;

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: formatGroup,
    );

    try {
      await _cameraController!.initialize();
      if (_isDisposed) return;
      _setStatus(FaceValidationStatus.detecting, 'Arahkan wajah ke kamera...');
      _startImageStream();
      notifyListeners();
    } catch (e) {
      _setStatus(FaceValidationStatus.failed, 'Gagal inisialisasi kamera: $e');
    }
  }

  InputImageRotation _rotationFromSensorDegrees(int degrees) {
    switch (degrees) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      default: // 270
        return InputImageRotation.rotation270deg;
    }
  }

  void _startImageStream() {
    if (_isDisposed) return;
    _cameraController?.startImageStream((CameraImage image) async {
      if (_isDisposed) return;
      if (_isProcessingFrame) return;
      if (_status == FaceValidationStatus.capturing ||
          _status == FaceValidationStatus.uploading ||
          _status == FaceValidationStatus.success) {
        return;
      }

      _isProcessingFrame = true;
      try {
        await _processFrame(image);
      } catch (e) {
        debugPrint('Frame stream error: $e');
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
        _setStatus(FaceValidationStatus.tooDark,
            'Pencahayaan terlalu gelap. Cari tempat lebih terang.');
        return;
      }
      _lightingStatus = LightingStatus.adequate;

      // ─── Blur / sharpness check (Laplacian variance approx) ───
      _sharpnessScore = _computeSharpness(image);
      if (_sharpnessScore < 8.0) {
        _setStatus(FaceValidationStatus.blurry,
            'Gambar blur. Pastikan kamera tidak goyang.');
        return;
      }

      // ─── Build InputImage for MLKit ────────────────────────────
      InputImage inputImage;

      if (Platform.isAndroid) {
        // Android: yuv420 planes, MLKit accepts nv21 bytes from plane[0]
        // We concatenate all planes bytes (Y + U/V interleaved)
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();

        inputImage = InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: _sensorRotation,
            format: InputImageFormat.nv21,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      } else {
        // iOS: bgra8888 from plane[0]
        inputImage = InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.bgra8888,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      }

      // ─── ML Kit face detection ─────────────────────────────────
      final faces = await _faceDetector.processImage(inputImage);
      if (_isDisposed) return;
      _faceCount = faces.length;

      if (faces.isEmpty) {
        _setStatus(FaceValidationStatus.noFace,
            'Tidak ada wajah terdeteksi. Posisikan wajah di frame.');
      } else if (faces.length > 1) {
        _setStatus(FaceValidationStatus.multipleFaces,
            'Terdeteksi ${faces.length} wajah. Pastikan hanya 1 wajah.');
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
      await Future.delayed(const Duration(milliseconds: 300));

      final XFile photo = await _cameraController!.takePicture();
      _capturedImagePath = photo.path;

      final file = File(photo.path);
      if (!await file.exists() || await file.length() == 0) {
        throw Exception('File foto kosong atau tidak ditemukan di local device.');
      }

      _setStatus(FaceValidationStatus.uploading, 'Menyimpan foto...');

      // ── Convert to Base64 (Opsi 2: Tanpa Firebase Storage) ────────
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      
      // Kita tambahkan prefix data URL agar mudah diidentifikasi nanti
      _selfieUrl = 'data:image/jpeg;base64,$base64String';
      
      debugPrint('Berhasil memproses foto menjadi Base64 (panjang: ${_selfieUrl!.length})');

      if (_isDisposed) return _selfieUrl;
      _setStatus(FaceValidationStatus.success, 'Foto berhasil diambil!');
      return _selfieUrl;
    } catch (e) {
      debugPrint('Capture/Convert error: $e');
      _errorMessage = e.toString();

      if (_capturedImagePath != null) {
        _selfieUrl = null;
        _setStatus(FaceValidationStatus.failed, 'Gagal memproses foto:\n$e');
      } else {
        _setStatus(FaceValidationStatus.failed, 'Gagal mengambil foto: $e');
      }

      // Restart stream untuk coba lagi
      if (!_isDisposed) _startImageStream();
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
    if (_isDisposed) return;
    _status = status;
    _statusMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cameraController?.stopImageStream().catchError((_) {});
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }
}
