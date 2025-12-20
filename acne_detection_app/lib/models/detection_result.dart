class DetectionResult {
  final List<int> box;
  final String label; 
  final double confidence;

  DetectionResult({
    required this.box,
    required this.label,
    required this.confidence,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      box: List<int>.from(json['box']),
      label: json['label'],
      confidence: json['confidence'].toDouble(),
    );
  }
}