import 'package:face_detection_first/util/coordinates_painter.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:google_ml_kit/google_ml_kit.dart' as mlkit;

class FaceDetectorPainter extends CustomPainter {
  final List<Face> faces;
  final Size absoluteImageSize;
  final mlkit.InputImageRotation rotation;

  FaceDetectorPainter({
    required this.faces,
    required this.absoluteImageSize,
    required this.rotation,
  });

  @override
  void paint(final Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.blue;

    for (final face in faces) {
      canvas.drawRect(
        Rect.fromLTRB(
          translateX(
            face.boundingBox.left,
            rotation,
            size,
            absoluteImageSize,
          ),
          translateY(
            face.boundingBox.top,
            rotation,
            size,
            absoluteImageSize,
          ),
          translateX(
            face.boundingBox.right,
            rotation,
            size,
            absoluteImageSize,
          ),
          translateY(
            face.boundingBox.bottom,
            rotation,
            size,
            absoluteImageSize,
          ),
        ),
        paint,
      );

      /// draw the blue circle for detected points of the face
      void paintContour(final FaceContourType type) {
        final faceContour = face.getContour(type);
        // contours[type];
        if (faceContour?.positionsList != null) {
          for (final point in faceContour!.positionsList) {
            canvas.drawCircle(
              Offset(
                  translateX(
                      point.dx.toDouble(), rotation, size, absoluteImageSize),
                  translateY(
                      point.dy.toDouble(), rotation, size, absoluteImageSize)),
              1.0,
              paint,
            );
          }
        }
      }

      // paintContour(FaceContourType.face);
      // paintContour(FaceContourType.leftEyebrowTop);
      // paintContour(FaceContourType.leftEyebrowBottom);
      // paintContour(FaceContourType.rightEyebrowTop);
      // paintContour(FaceContourType.rightEyebrowBottom);
      // paintContour(FaceContourType.leftEye);
      // paintContour(FaceContourType.rightEye);
      // paintContour(FaceContourType.upperLipTop);
      // paintContour(FaceContourType.upperLipBottom);
      // paintContour(FaceContourType.lowerLipTop);
      // paintContour(FaceContourType.lowerLipBottom);
      // paintContour(FaceContourType.noseBridge);
      // paintContour(FaceContourType.noseBottom);
      paintContour(FaceContourType.allPoints);
      // paintContour(FaceContourType.rightCheek);
    }
  }

  @override
  bool shouldRepaint(final FaceDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.faces != faces;
  }
}
