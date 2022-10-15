import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_vision/google_ml_vision.dart';

import 'main.dart';
import 'util/screen_mode.dart';

class CameraView extends StatefulWidget {
  final String title;
  final CustomPaint? customPaint;
  final String? text;
  final Function(
    GoogleVisionImage googleVisionImage,
    InputImage inputImage,
  ) onImage;
  final CameraLensDirection initialDirection;

  const CameraView({
    super.key,
    required this.title,
    required this.onImage,
    required this.initialDirection,
    this.customPaint,
    this.text,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  ScreenMode _mode = ScreenMode.live;
  CameraController? _controller;
  File? _image;
  String? _path;
  ImagePicker? _imagePicker;
  int _cameraIndex = 0;
  double zoomLevel = 1.0, minZoomLevel = 1.0, maxZoomLevel = 1.0;
  final bool _allowPicker = true;
  bool _changingCameraLens = false;

  @override
  void initState() {
    super.initState();

    _imagePicker = ImagePicker();

    if (cameras.any(
      (element) =>
          element.lensDirection == widget.initialDirection &&
          element.sensorOrientation == 90,
    )) {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere(
          (element) =>
              element.lensDirection == widget.initialDirection &&
              element.sensorOrientation == 90,
        ),
      );
    } else {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere(
          (element) => element.lensDirection == widget.initialDirection,
        ),
      );
    }

    _startLive();
  }

  Future _startLive() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _controller?.initialize().then(
      (value) {
        if (!mounted) {
          return;
        }

        _controller?.getMaxZoomLevel().then(
          (value) {
            maxZoomLevel = value;
          },
        );

        _controller?.getMinZoomLevel().then(
          (value) {
            minZoomLevel = value;
          },
        );

        _controller?.startImageStream(_processingCameraImage);
        setState(() {});
      },
    );
  }

  Future _processingCameraImage(final CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();

    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }

    final bytes = allBytes.done().buffer.asUint8List();
    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final camera = cameras[_cameraIndex];

    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.rotation0deg;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;

    final planeData = image.planes.map(
      (final Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      inputImageData: inputImageData,
    );

    /// vision

    final googleVisionPlaneData = image.planes.map(
      (final Plane plane) {
        return GoogleVisionImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final googleVisionImageMetadata = GoogleVisionImageMetadata(
      size: imageSize,
      rotation: ImageRotation.rotation0,
      rawFormat: image.format.raw,
      planeData: googleVisionPlaneData,
    );

    final googleVisionImage = GoogleVisionImage.fromBytes(
      bytes,
      googleVisionImageMetadata,
    );

    widget.onImage(googleVisionImage, inputImage);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            if (_allowPicker)
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: _switchScreenMode,
                  child: Icon(
                    _mode == ScreenMode.live
                        ? Icons.photo_library_rounded
                        : (Platform.isIOS
                            ? Icons.camera_alt_outlined
                            : Icons.camera),
                  ),
                ),
              ),
          ],
        ),
        body: _body(),
        floatingActionButton: _floatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      );

  Widget? _floatingActionButton() {
    if (_mode == ScreenMode.gallery) return null;

    if (cameras.length == 1) return null;

    return SizedBox(
      height: 70,
      width: 70,
      child: FloatingActionButton(
        onPressed: _switcherCamera,
        child: Icon(
          Platform.isIOS
              ? Icons.flip_camera_ios_outlined
              : Icons.flip_camera_android_outlined,
          size: 40,
        ),
      ),
    );
  }

  Future _switcherCamera() async {
    setState(() => _changingCameraLens = true);
    _cameraIndex = (_cameraIndex + 1) % cameras.length;

    await _stopLive();
    await _startLive();

    setState(() => _changingCameraLens = false);
  }

  Widget _body() {
    Widget body;
    if (_mode == ScreenMode.live) {
      body = _liveBody();
    } else {
      body = _galeryBody();
    }

    return body;
  }

  Widget _galeryBody() => ListView(
        shrinkWrap: true,
        children: [
          _image != null
              ? SizedBox(
                  height: 400,
                  width: 400,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(_image!),
                      if (widget.customPaint != null) widget.customPaint!,
                    ],
                  ),
                )
              : const Icon(
                  Icons.image,
                  size: 200,
                ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
            ),
            child: ElevatedButton(
              onPressed: () => _getImage(ImageSource.gallery),
              child: const Text('From Gallery'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
            ),
            child: ElevatedButton(
              onPressed: () => _getImage(ImageSource.camera),
              child: const Text('Take a Picture'),
            ),
          ),
          if (_image != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                  '${_path == null ? '' : 'image path $_path'}\n\n${widget.text ?? ''}'),
            )
        ],
      );

  Future _getImage(ImageSource source) async {
    setState(() {
      _image = null;
      _path = null;
    });

    final pickedFile = await _imagePicker?.pickImage(source: source);

    if (pickedFile != null) {
      _processPickedFile(pickedFile);
    }

    setState(() {});
  }

  Future _processPickedFile(XFile? pickedFile) async {
    final path = pickedFile?.path;

    if (path == null) {
      return;
    }

    setState(() {
      _image = File(path);
    });

    _path = path;
    final inputImage = InputImage.fromFilePath(path);

    final imageFile = File(path);
    final GoogleVisionImage visionImage = GoogleVisionImage.fromFile(imageFile);
    widget.onImage(visionImage, inputImage);
  }

  Widget _liveBody() {
    if (_controller?.value.isInitialized == false) {
      return Container();
    }

    final size = MediaQuery.of(context).size;
    // calculate scale depending on screen and camera ratios
    // this is actually size.aspectRatio / (1 / camera.aspectRatio)
    // because camera preview size is received as landscape
    // but we're calculating for portrait orientation
    var scale = size.aspectRatio * _controller!.value.aspectRatio;

    if (scale < 1) scale = 1 / scale;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Transform.scale(
            scale: scale,
            child: Center(
              child: _changingCameraLens
                  ? const Center(
                      child: Text('changing camera lens'),
                    )
                  : CameraPreview(_controller!),
            ),
          ),
          if (widget.customPaint != null) widget.customPaint!,
          Positioned(
            bottom: 100,
            left: 50,
            right: 50,
            child: Slider(
              value: zoomLevel,
              min: minZoomLevel,
              max: maxZoomLevel,
              onChanged: (final newSliderValue) {
                setState(() {
                  zoomLevel = newSliderValue;
                  _controller!.setZoomLevel(zoomLevel);
                });
              },
              divisions: (maxZoomLevel - 1).toInt() < 1
                  ? null
                  : (maxZoomLevel - 1).toInt(),
            ),
          )
        ],
      ),
    );
  }

  void _switchScreenMode() {
    _image = null;
    if (_mode == ScreenMode.live) {
      _mode = ScreenMode.gallery;
      _stopLive();
    } else {
      _mode = ScreenMode.live;
      _startLive();
    }

    setState(() {});
  }

  Future _stopLive() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }
}
