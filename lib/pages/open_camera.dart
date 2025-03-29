import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'dart:math';

class OpenCamera extends StatefulWidget {
  const OpenCamera({super.key});

  @override
  State<OpenCamera> createState() => _OpenCameraState();
}

class _OpenCameraState extends State<OpenCamera> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
  String _detectionResult = '';
  String? _capturedImagePath;
  Interpreter? _interpreter;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showErrorDialog('No cameras available');
        return;
      }

      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      _showErrorDialog('Error initializing camera: $e');
    }
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/best-fp16.tflite');

      // Suppose the model expects [1, 640, 640, 3].
      // You can get the shape dynamically:
      final inputShape = _interpreter!.getInputTensor(0).shape;
      // e.g. [1, 640, 640, 3]

      // Optionally, you can resize if needed:
      // _interpreter!.resizeInputTensor(0, [1, 640, 640, 3]);
      // _interpreter!.allocateTensors();

      _interpreter!.allocateTensors();
      print("Model loaded and tensors allocated successfully!");
    } catch (e) {
      _showErrorDialog('Failed to load or allocate model: $e');
    }
  }

  Future<void> _captureAndDetect() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      _showErrorDialog('Camera not initialized');
      return;
    }

    try {
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImagePath = image.path;
      });

      String detectedPlate = await _runModel(image.path);

      setState(() {
        _detectionResult = detectedPlate;
      });
    } catch (e) {
      _showErrorDialog('Error capturing image: $e');
    }
  }

  Future<String> _runModel(String imagePath) async {
    try {
      if (_interpreter == null) return "Model not initialized";

      // 1. Load and decode image
      final bytes = await File(imagePath).readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) return "Error decoding image";

      // 2. Get model input shape
      final inputShape = _interpreter!.getInputTensor(0).shape;
      // Example: [1, 640, 640, 3]
      final batchSize = inputShape[0];
      final modelHeight = inputShape[1];
      final modelWidth  = inputShape[2];
      final channels    = inputShape[3];

      // 3. Resize the image to the model’s expected size
      final resized = img.copyResize(
        original,
        width: modelWidth,
        height: modelHeight,
      );

      // 4. Build a 4D List: [batchSize, height, width, channels]
      final input = List.generate(
        batchSize,
            (_) => List.generate(
          modelHeight,
              (y) => List.generate(
            modelWidth,
                (x) {
              final pixel = resized.getPixel(x, y);
              return [
                img.getRed(pixel)   / 255.0,
                img.getGreen(pixel) / 255.0,
                img.getBlue(pixel)  / 255.0
              ];
            },
          ),
        ),
      );

      // 5. Prepare output array
      final output = List.generate(
        1,  // or inputShape[0]
            (_) => List.generate(25200, (_) => List.filled(6, 0.0)),
      );

      // 6. Run inference
      _interpreter!.run(input, output);

      // 7. Process model output
      return _processModelOutput(output);

    } catch (e) {
      return "Error running model: $e";
    }
  }


  String _processModelOutput(List<List<List<double>>> output) {
    const double confidenceThreshold = 0.3;
    for (var i = 0; i < output[0].length; i++) {
      if (output[0][i][4] > confidenceThreshold) {
        return "Plate detected with confidence: ${output[0][i][4]}";
      }
    }
    return "No plate detected";
  }

  Future<void> _sendDataToServer() async {
    if (_capturedImagePath == null || _detectionResult.isEmpty) {
      _showErrorDialog("No image or detection result found");
      return;
    }

    Uri apiUrl = Uri.parse("http://192.168.29.241:4000/api/v1/numberplate/upload");

    try {
      var request = http.MultipartRequest("POST", apiUrl);
      request.fields["regNumber"] = _detectionResult;
      request.fields["location"] = "${Random().nextDouble() * 10 + 12.0}, ${Random().nextDouble() * 10 + 77.0}";
      request.fields["date"] = DateTime.now().toIso8601String();

      request.files.add(await http.MultipartFile.fromPath("numberplate", _capturedImagePath!));

      var response = await request.send();

      if (response.statusCode == 200) {
        _showSuccessDialog("Data sent successfully!");
      } else {
        _showErrorDialog("Failed to send data: ${await response.stream.bytesToString()}");
      }
    } catch (e) {
      _showErrorDialog("Error sending data: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Number Plate Detector')),
      body: Column(
        children: [
          Expanded(
            child: _isCameraInitialized
                ? CameraPreview(_controller!)
                : const Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(_detectionResult, style: const TextStyle(fontSize: 16)),
                ElevatedButton(onPressed: _captureAndDetect, child: const Text("Detect Number Plate")),
                ElevatedButton(onPressed: _sendDataToServer, child: const Text("Send to Server")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on int {
  get r => null;

  get g => null;

  get b => null;
}
