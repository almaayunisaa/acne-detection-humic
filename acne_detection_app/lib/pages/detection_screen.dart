import 'dart:typed_data';
import 'dart:ui' as ui; 
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; 
import 'package:provider/provider.dart';

import '../controllers/detection_controller.dart';
import '../widgets/bounding_box.dart';
import 'report_screen.dart'; 

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<DetectionController>().initCamera();
    });
  }

  @override
  void dispose() {
    context.read<DetectionController>().disposeCameraSync();
    super.dispose();
  }

  Future<Uint8List?> _captureImageWithBoxes() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      
      RenderRepaintBoundary? boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); // Kualitas tinggi
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DetectionController>(
        builder: (context, controller, _) {
          return Stack(
            children: [
              RepaintBoundary(
                key: _boundaryKey,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: controller.selectedImage == null
                          ? controller.cameraPreview()
                          : Image.file(
                              controller.selectedImage!,
                              fit: BoxFit.contain,
                            ),
                    ),
                    if (controller.report != null && controller.report!.detections.isNotEmpty)
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return CustomPaint(
                              painter: BoundingBoxPainter(
                                detections: controller.report!.detections,
                                originalImageSize: Size(
                                  controller.report!.imageWidth,
                                  controller.report!.imageHeight,
                                ),
                                displayImageSize: Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                ),
                                isFrontCamera: controller.isFrontCamera,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              if (controller.isLoading)
                const Center(child: CircularProgressIndicator(color: Colors.white)),

              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: controller.isLoading ? null : () async {
                      await controller.takePicture();
                      await controller.processImage();

                      if (!context.mounted || controller.report == null) return;

                      final Uint8List? combinedBytes = await _captureImageWithBoxes();

                      if (combinedBytes != null) {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => ReportModal(
                            report: controller.report!,
                            imageBytes: combinedBytes, 
                          ),
                        );
                      }

                      controller.reset();
                      await controller.initCamera();
                    },
                    child: Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.grey, width: 4),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 40,
                right: 20,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 30),
                    onPressed: () => controller.switchCamera(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}