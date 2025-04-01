import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class TextExtractPage extends StatefulWidget {
  final String imagePath;
  const TextExtractPage({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<TextExtractPage> createState() => _TextExtractPageState();
}

class _TextExtractPageState extends State<TextExtractPage> with SingleTickerProviderStateMixin {
  bool _isExtracting = true;
  bool _isUploading = false;
  List<Map<String, dynamic>> _detectedPlates = [];
  String? _uploadResult;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _performTextExtraction();
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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _performTextExtraction() async {
    try {
      final inputImage = InputImage.fromFilePath(widget.imagePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final RegExp platePattern = RegExp(r'[A-Z]{2}\s?\d{1,2}\s?[A-Z]{1,3}\s?\d{4}');
      final Iterable<Match> matches = platePattern.allMatches(recognizedText.text);

      List<Map<String, dynamic>> plates = [];
      for (final match in matches) {
        final plate = match.group(0);
        if (plate != null && plate.isNotEmpty) {
          if (!plates.any((element) => element['plate'] == plate)) {
            plates.add({'plate': plate, 'isSelected': true});
          }
        }
      }
      if (plates.isEmpty) {
        plates.add({'plate': "No valid number plate found", 'isSelected': false});
      }

      setState(() {
        _detectedPlates = plates;
        _isExtracting = false;
      });
      debugPrint("Extracted plates: ${_detectedPlates.map((e) => e['plate']).toList()}");
    } catch (e) {
      setState(() {
        _detectedPlates = [
          {'plate': "Error extracting text: $e", 'isSelected': false}
        ];
        _isExtracting = false;
      });
      debugPrint("Error during text extraction: $e");
    }
  }

  Future<String> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return "Location permission denied";
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return "Location permission permanently denied";
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return "${position.latitude}, ${position.longitude}";
    } catch (e) {
      debugPrint("Error getting location: $e");
      return "Error getting location: $e";
    }
  }

  Future<void> _sendDataToServer() async {
    final selectedPlates = _detectedPlates.where((item) => item['isSelected'] == true).toList();
    if (selectedPlates.isEmpty ||
        (selectedPlates.length == 1 && selectedPlates.first['plate'] == "No valid number plate found")) {
      setState(() {
        _uploadResult = "No valid number plate selected for upload.";
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadResult = null;
    });

    String location = await _getCurrentLocation();
    String dateCaptured = DateTime.now().toIso8601String();
    Uri apiUrl = Uri.parse("http://192.168.13.152:4000/api/v1/numberplate/upload");

    StringBuffer uploadResults = StringBuffer();

    for (final plateData in selectedPlates) {
      String regNumber = plateData['plate'];
      try {
        var request = http.MultipartRequest("POST", apiUrl);
        request.fields["regNumber"] = regNumber;
        request.fields["location"] = location;
        request.fields["date"] = dateCaptured;
        request.files.add(await http.MultipartFile.fromPath("numberplate", widget.imagePath));

        var response = await request.send();
        if (response.statusCode == 200) {
          uploadResults.writeln("Plate $regNumber: Data sent successfully!");
          debugPrint("Plate $regNumber sent to server successfully.");
        } else {
          String responseMsg = await response.stream.bytesToString();
          uploadResults.writeln("Plate $regNumber: Failed: $responseMsg");
          debugPrint("Plate $regNumber server error: $responseMsg");
        }
      } catch (e) {
        uploadResults.writeln("Plate $regNumber: Error sending data: $e");
        debugPrint("Plate $regNumber error during server upload: $e");
      }
    }

    setState(() {
      _uploadResult = uploadResults.toString();
      _isUploading = false;
    });
  }

  Widget _buildPlateList(Size screenSize, bool isTablet) {
    return FutureBuilder<String>(
      future: _getCurrentLocation(),
      builder: (context, snapshot) {
        String location = snapshot.data ?? "Fetching location...";
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _detectedPlates.length,
          itemBuilder: (context, index) {
            final plateData = _detectedPlates[index];
            return Card(
              margin: EdgeInsets.symmetric(
                vertical: screenSize.height * 0.01,
                horizontal: screenSize.width * 0.02,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              color: Colors.white.withOpacity(0.9),
              child: CheckboxListTile(
                title: Text(
                  "Number Plate: ${plateData['plate']}",
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Location: $location",
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      "Date: ${DateTime.now().toLocal().toString().split('.')[0]}",
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                value: plateData['isSelected'],
                onChanged: (bool? value) {
                  setState(() {
                    _detectedPlates[index]['isSelected'] = value;
                  });
                },
                activeColor: Colors.orangeAccent,
                checkColor: Colors.white,
              ),
            );
          },
        );
      },
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
            child: _isExtracting
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.05,
                  vertical: screenSize.height * 0.01,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.05,
                        vertical: screenSize.height * 0.01,
                      ),
                      child: _buildCustomAppBar(screenSize, isTablet),
                    ),
                    SizedBox(height: screenSize.height * 0.03),
                    FadeTransition(
                      opacity: _fadeAnimation,
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
                          child: Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.cover,
                            width: screenSize.width * 0.9,
                            height: screenSize.height * 0.35,
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
                    SizedBox(height: screenSize.height * 0.03),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildPlateList(screenSize, isTablet),
                    ),
                    SizedBox(height: screenSize.height * 0.03),
                    if (_uploadResult != null)
                      Padding(
                        padding: EdgeInsets.all(screenSize.width * 0.02),
                        child: Text(
                          _uploadResult!,
                          style: TextStyle(
                            color: _uploadResult!.contains("success")
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: isTablet ? 18 : 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.05,
                        vertical: screenSize.height * 0.02,
                      ),
                      child: _isUploading
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
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(Size screenSize, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: screenSize.height * 0.02,
        horizontal: screenSize.width * 0.05,
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
            Icons.text_fields,
            color: Colors.white,
            size: 30,
          ),
          SizedBox(width: screenSize.width * 0.02),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Extracted Number Plates',
                style: TextStyle(
                  fontSize: isTablet ? 24 : screenSize.width < 400 ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
        onPressed: _sendDataToServer,
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
          'Upload to Server',
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