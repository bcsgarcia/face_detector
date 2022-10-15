import 'package:camera/camera.dart';
import 'package:face_detection_first/camera_view.dart';
import 'package:face_detection_first/util/face_detector_painter.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:google_ml_kit/google_ml_kit.dart' as mlkit;

class FaceDetectorPage extends StatefulWidget {
  const FaceDetectorPage({super.key});

  @override
  State<FaceDetectorPage> createState() => _FaceDetectorPageState();
}

class _FaceDetectorPageState extends State<FaceDetectorPage> {
  /// create face detector object
  final FaceDetector _faceDetector = GoogleVision.instance.faceDetector(
    const FaceDetectorOptions(
      mode: FaceDetectorMode.accurate,
      // enableLandmarks: true,
      enableTracking: true,
      enableContours: true,
    ),
  );

  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      title: 'Face Detector',
      customPaint: _customPaint,
      text: _text,
      onImage: (googleVisionImage, inputImage) {
        processImage(googleVisionImage, inputImage);
      },
      initialDirection: CameraLensDirection.front,
    );
  }

  // google ml vision
  Future<void> processImage(
    final GoogleVisionImage googleVisionImage,
    final mlkit.InputImage inputImage,
  ) async {
    if (!_canProcess) return;
    if (_isBusy) return;

    _isBusy = true;
    setState(() {
      _text = '';
    });

    final faces = await _faceDetector.processImage(googleVisionImage);

    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = FaceDetectorPainter(
        faces: faces,
        absoluteImageSize: inputImage.inputImageData!.size,
        rotation: inputImage.inputImageData!.imageRotation,
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      String text = 'faces found: ${faces.length}\n\n';
      for (final face in faces) {
        text += 'face: ${face.boundingBox}\n\n';
        // final boundingBox = face.boundingBox;

        final double? rotY =
            face.headEulerAngleY; // Head is rotated to the right rotY degrees
        final double? rotZ =
            face.headEulerAngleZ; // Head is tilted sideways rotZ degrees

        // If landmark detection was enabled with FaceDetectorOptions (mouth, ears,
        // eyes, cheeks, and nose available):
        final FaceLandmark? leftEar =
            face.getLandmark(FaceLandmarkType.leftEar);
        if (leftEar != null) {
          // final Point<double> leftEarPos = leftEar.position;
        }

        // If classification was enabled with FaceDetectorOptions:
        if (face.smilingProbability != null) {
          final double? smileProb = face.smilingProbability;
        }

        // If face tracking was enabled with FaceDetectorOptions:
        if (face.trackingId != null) {
          final int id = face.trackingId!;
          text += 'face ID: $id\n\n';
        }
      }
      _text = text;
      _customPaint = null;
    }

    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
