import 'package:camera/camera.dart';
import 'package:face_detection_first/camera_view.dart';
import 'package:face_detection_first/util/face_detector_painter.dart';
import 'package:flutter/material.dart';
// import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorPage extends StatefulWidget {
  const FaceDetectorPage({super.key});

  @override
  State<FaceDetectorPage> createState() => _FaceDetectorPageState();
}

class _FaceDetectorPageState extends State<FaceDetectorPage> {
  /// create face detector object
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );

  // final FaceDetector _faceDetector = GoogleVision.instance.faceDetector(
  //   const FaceDetectorOptions(
  //     mode: FaceDetectorMode.accurate,
  //     enableLandmarks: true,
  //   ),
  // );

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
      onImage: (inputImage) {
        processImage(inputImage);
      },
      initialDirection: CameraLensDirection.front,
    );
  }

  // google ml vision
  // Future<void> processImage(final GoogleVisionImage inputImage) async {
  //   if (!_canProcess) return;
  //   if (_isBusy) return;

  //   _isBusy = true;
  //   setState(() {
  //     _text = '';
  //   });

  //   final faces = await _faceDetector.processImage(inputImage);

  //   if (inputImage.inputImageData?.size != null &&
  //       inputImage.inputImageData?.imageRotation != null) {
  //     final painter = FaceDetectorPainter(
  //       faces: faces,
  //       absoluteImageSize: inputImage.inputImageData!.size,
  //       rotation: inputImage.inputImageData!.imageRotation,
  //     );
  //     _customPaint = CustomPaint(painter: painter);
  //   } else {
  //     String text = 'faces found: ${faces.length}\n\n';
  //     for (final face in faces) {
  //       text += 'face: ${face.boundingBox}\n\n';
  //     }
  //     _text = text;
  //     _customPaint = null;
  //   }

  //   _isBusy = false;
  //   if (mounted) {
  //     setState(() {});
  //   }
  // }

  // google_ml_kit
  Future<void> processImage(final InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;

    _isBusy = true;
    setState(() {
      _text = '';
    });

    final faces = await _faceDetector.processImage(inputImage);

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
