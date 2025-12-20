import os
import io
from flask import Flask, request, jsonify
from ultralytics import YOLO
from PIL import Image, ExifTags
from collections import defaultdict

app = Flask(__name__)

MODEL_FILENAME = r"hasil_detect_objek\acne_detection\content\acne_detection\yolov8_medical_optimal\weights\best.pt"
MODEL_SEVERITY_FILENAME = r"hasil_klasifikasi\yolov8_result\content\acne_classification\yolov8_cls_medical\weights\best.pt"

model = YOLO(MODEL_FILENAME)
model_severity = YOLO(MODEL_SEVERITY_FILENAME)

@app.route('/predict', methods=['POST'])
def predict():
    class_counts = defaultdict(int)
    
    if 'image' not in request.files:
        return jsonify({"status": "error", "error": "Tidak ada file gambar."}), 400

    image_file = request.files['image']

    try:
        image_bytes = image_file.read()
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

        try:
            exif = image._getexif()
            if exif:
                for k, v in ExifTags.TAGS.items():
                    if v == 'Orientation':
                        orientation = exif.get(k)
                        if orientation == 3:
                            image = image.rotate(180, expand=True)
                        elif orientation == 6:
                            image = image.rotate(270, expand=True)
                        elif orientation == 8:
                            image = image.rotate(90, expand=True)
        except:
            pass

    except Exception as e:
        return jsonify({"status": "error", "error": str(e)}), 400

    try:
        detection_results = model.predict(
            source=image,
            conf=0.25,
            save=False,
            verbose=False
        )

        predictions = []

        for result in detection_results:
            for box in result.boxes:
                x1, y1, x2, y2 = map(lambda x: round(float(x)), box.xyxy[0])
                confidence = round(float(box.conf[0]), 4)
                class_id = int(box.cls[0])
                class_name = model.names[class_id]

                predictions.append({
                    "box": [x1, y1, x2, y2],
                    "label": class_name,
                    "confidence": confidence
                })

                class_counts[class_name] += 1

        severity_result = model_severity.predict(
            source=image,
            save=False,
            verbose=False
        )[0]

        probs = severity_result.probs
        severity_index = int(probs.top1)
        severity_label = model_severity.names[severity_index]
        severity_confidence = round(float(probs.top1conf), 4)

        return jsonify({
            "status": "success",
            "image_size" : {
                "height" : image.height,
                "width" : image.width
            },
            "severity": {
                "label": severity_label,
                "confidence": severity_confidence
            },
            "detections": predictions,
            "counts_class": class_counts
        })

    except Exception as e:
        return jsonify({"status": "error", "error": str(e)}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
