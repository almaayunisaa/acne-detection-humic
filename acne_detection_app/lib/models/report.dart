import 'detection_result.dart';

class Report {
  final String dominance;
  final Map<String, int> countPerClass;
  final List<DetectionResult> detections;

  final String severityLabel;
  final double severityConfidence;

  final double imageWidth;
  final double imageHeight;

  Report({
    required this.dominance,
    required this.countPerClass,
    required this.detections,
    required this.severityLabel,
    required this.severityConfidence,
    required this.imageHeight,
    required this.imageWidth,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    Map<String, int> counts = {};
    List<DetectionResult> detections = [];

    if (json['counts_class'] != null) {
      json['counts_class'].forEach((key, value) {
        counts[key.toString()] = (value as num).toInt();
      });
    }

    if (json['detections'] != null) {
      detections = (json['detections'] as List)
          .map((e) => DetectionResult.fromJson(e))
          .toList();
    }

    final int blackheadCount = counts['blackhead'] ?? 0;
    final int acneCount =
        (counts['papule'] ?? 0) +
        (counts['pustule'] ?? 0) +
        (counts['nodul'] ?? 0);

    String dominance;

    final bool hasDetection = !detections.isEmpty;

    if (!hasDetection) {
      dominance = "Tidak ada";
    } else if (blackheadCount > acneCount) {
      dominance = "Komedo";
    } else if (acneCount > blackheadCount) {
      dominance = "Jerawat";
    } else {
      dominance = "Seimbang";
    }

    print('nilai count = $acneCount dan $blackheadCount');

    final severityJson = json['severity'] ?? {};
    final sizeJson = json['image_size'] ?? {};

    final String severityLabel =
        hasDetection ? (severityJson['label'] ?? '') : 'None';

    final double severityConfidence =
        hasDetection ? (severityJson['confidence'] ?? 0).toDouble() : 0.0;

    return Report(
      dominance: dominance,
      countPerClass: counts,
      detections: detections,
      severityLabel: severityLabel,
      severityConfidence: severityConfidence,
      imageHeight: (sizeJson['height'] ?? 0).toDouble(),
      imageWidth: (sizeJson['width'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dominance': dominance,
      'counts_class': countPerClass,
      'detections': detections.map((e) => {
            'box': e.box,
            'label': e.label,
            'confidence': e.confidence,
          }).toList(),
      'severity': {
        'label': severityLabel,
        'confidence': severityConfidence,
      },
      'image_size': {
        'width': imageWidth,
        'height': imageHeight,
      }
    };
  }
}
