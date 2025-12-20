import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../api/api.dart';
import '../models/report.dart';

class DetectionController extends ChangeNotifier {
  final AcneApi _acneApi = AcneApi();

  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  int _cameraIndex = 0;

  CameraController? get cameraController => _cameraController;

  bool get isCameraReady =>
      _cameraController != null &&
      _cameraController!.value.isInitialized;

  bool get isFrontCamera {
    if (_cameras == null || _cameras!.isEmpty) return false;
    return _cameras![_cameraIndex].lensDirection ==
        CameraLensDirection.front;
  }

  Future<void> initCamera() async {
    if (isCameraReady) return;

    _cameras ??= await availableCameras();

    _cameraController = CameraController(
      _cameras![_cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    notifyListeners();
  }

  Widget cameraPreview() {
    if (!isCameraReady) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(_cameraController!);
  }

  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    _cameraIndex = (_cameraIndex + 1) % _cameras!.length;
    await _cameraController?.dispose();
    _cameraController = null;
    await initCamera();
  }

  File? selectedImage;
  Report? report;
  bool isLoading = false;
  Size? originalImageSize;

  Future<void> takePicture() async {
    if (!isCameraReady) return;

    final image = await _cameraController!.takePicture();
    selectedImage = File(image.path);
    notifyListeners();
  }

  Future<void> processImage() async {
    if (selectedImage == null) return;

    isLoading = true;
    notifyListeners();

    report = await _acneApi.detectAcne(selectedImage!);

    final decodedImage = await decodeImageFromList(
      await selectedImage!.readAsBytes(),
    );

    originalImageSize = Size(
      decodedImage.width.toDouble(),
      decodedImage.height.toDouble(),
    );

    isLoading = false;
    notifyListeners();
  }

  void reset() {
    selectedImage = null;
    report = null;
    originalImageSize = null;
    isLoading = false;
    notifyListeners();
  }

  void disposeCameraSync() {
    _cameraController?.dispose();
    _cameraController = null;
  }

  @override
  void dispose() {
    disposeCameraSync();
    super.dispose();
  }
}
