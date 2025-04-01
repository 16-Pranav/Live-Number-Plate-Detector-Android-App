import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:live_num_plate_detect_2/pages/text_extract.dart';

class ScanPlatePage extends StatefulWidget {
  const ScanPlatePage({Key? key}) : super(key: key);

  @override
  State<ScanPlatePage> createState() => _ScanPlatePageState();
}

class _ScanPlatePageState extends State<ScanPlatePage> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
  String? _capturedImagePath;
  bool _isProcessing = false;
  String? _errorMsg;
  bool _isFlashOn = false;
  double _zoomLevel = 1.0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.back);
      _controller = CameraController(backCamera, ResolutionPreset.high, enableAudio: false);
      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
      debugPrint("Camera initialized successfully.");
    } catch (e) {
      setState(() {
        _errorMsg = "Error initializing camera: $e";
      });
      debugPrint(_errorMsg);
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_isCameraInitialized) return;
    try {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      await _controller!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    } catch (e) {
      setState(() {
        _errorMsg = "Error toggling flash: $e";
      });
      debugPrint(_errorMsg);
    }
  }

  Future<void> _setZoom(double zoom) async {
    if (_controller == null || !_isCameraInitialized) return;
    try {
      setState(() {
        _zoomLevel = zoom.clamp(1.0, 2.0);
      });
      await _controller!.setZoomLevel(_zoomLevel);
    } catch (e) {
      setState(() {
        _errorMsg = "Error setting zoom: $e";
      });
      debugPrint(_errorMsg);
    }
  }

  Future<void> _capturePhoto() async {
    if (!_isCameraInitialized || _controller == null) {
      setState(() {
        _errorMsg = "Camera not ready.";
      });
      return;
    }
    setState(() {
      _isProcessing = true;
      _errorMsg = null;
    });
    try {
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImagePath = image.path;
      });
      debugPrint("Image captured: ${image.path}");
    } catch (e) {
      setState(() {
        _errorMsg = "Error capturing image: $e";
      });
      debugPrint(_errorMsg);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _proceedToDetection() {
    if (_capturedImagePath == null) {
      setState(() {
        _errorMsg = "No image captured.";
      });
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TextExtractPage(imagePath: _capturedImagePath!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      body: SizedBox(
        height: screenSize.height,
        width: screenSize.width,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E3A8A),
                Color(0xFF3B82F6),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Custom AppBar-like header with adjusted padding
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.05, // Same horizontal padding as HomePage
                    vertical: screenSize.height * 0.01, // Small vertical padding for top/bottom
                  ),
                  child: _buildCustomAppBar(screenSize, isTablet),
                ),
                SizedBox(height: screenSize.height * 0.01),

                // Camera preview or captured image
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.05),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _capturedImagePath == null
                            ? (_isCameraInitialized
                            ? CameraPreview(_controller!)
                            : const Center(child: CircularProgressIndicator(color: Colors.white)))
                            : Image.file(
                          File(_capturedImagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text(
                                "Error displaying image.",
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenSize.height * 0.03),

                // Flash and Zoom controls
                if (_capturedImagePath == null && _isCameraInitialized) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.05),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _toggleFlash,
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                            size: isTablet ? 30 : 24,
                          ),
                          tooltip: _isFlashOn ? "Turn Flash Off" : "Turn Flash On",
                        ),
                        Row(
                          children: [
                            Text(
                              "${_zoomLevel.toStringAsFixed(1)}x",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 18 : 14,
                              ),
                            ),
                            SizedBox(width: screenSize.width * 0.02),
                            Slider(
                              value: _zoomLevel,
                              min: 1.0,
                              max: 2.0,
                              onChanged: (value) => _setZoom(value),
                              activeColor: Colors.orangeAccent,
                              inactiveColor: Colors.white24,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                ],

                // Error message
                if (_errorMsg != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Action button
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.05,
                    vertical: screenSize.height * 0.02,
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildCustomButton(screenSize, isTablet),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom AppBar-like header with adjusted padding
  Widget _buildCustomAppBar(Size screenSize, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: screenSize.height * 0.02, // Same vertical padding as HomePage
        horizontal: screenSize.width * 0.05, // Same horizontal padding as HomePage
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 30,
          ),
          SizedBox(width: screenSize.width * 0.02),
          Text(
            'Scan Number Plate',
            style: TextStyle(
              fontSize: isTablet ? 28 : 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // Custom button with gradient
  Widget _buildCustomButton(Size screenSize, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFA726),
            Color(0xFFFF5722),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _capturedImagePath == null ? _capturePhoto : _proceedToDetection,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: screenSize.width * 0.15,
            vertical: screenSize.height * 0.025,
          ),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          _capturedImagePath == null ? "Capture Plate" : "Proceed to Detect",
          style: TextStyle(
            fontSize: isTablet ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}