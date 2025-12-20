import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/detection_result.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<DetectionResult> detections;
  final Size originalImageSize;
  final Size displayImageSize;
  final bool isFrontCamera;

  BoundingBoxPainter({
    required this.detections,
    required this.originalImageSize,
    required this.displayImageSize,
    required this.isFrontCamera,
  });

  static const Map<String, Color> classColors = {
    'blackhead': Colors.blue,
    'whitehead': Colors.green,
    'papule': Colors.orange,
    'pustule': Colors.purple,
    'nodul': Colors.cyan,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final imgW = originalImageSize.width;
    final imgH = originalImageSize.height;
    final viewW = displayImageSize.width;
    final viewH = displayImageSize.height;

    final scale = math.min(viewW / imgW, viewH / imgH);

    final scaledW = imgW * scale;
    final scaledH = imgH * scale;

    final dx = (viewW - scaledW) / 2;
    final dy = (viewH - scaledH) / 2;

    for (final det in detections) {
      final color = classColors[det.label] ?? Colors.yellow;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      double x1 = det.box[0].toDouble() * scale;
      double y1 = det.box[1].toDouble() * scale;
      double x2 = det.box[2].toDouble() * scale;
      double y2 = det.box[3].toDouble() * scale;

      if (isFrontCamera) {
        final tempX1 = x1;
        x1 = scaledW - x2;
        x2 = scaledW - tempX1;
      }

      final rect = Rect.fromLTRB(
        x1 + dx,
        y1 + dy,
        x2 + dx,
        y2 + dy,
      );

      canvas.drawRect(rect, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${det.label} ${(det.confidence * 100).toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontSize: 12,
            backgroundColor: Colors.black54,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(rect.left, rect.top - 14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections || 
           oldDelegate.displayImageSize != displayImageSize;
  }
}
