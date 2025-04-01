import 'package:flutter/material.dart';
import 'package:live_num_plate_detect_2/pages/open_camera.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller for fade and scale effects
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward(); // Start the animation
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size for responsiveness
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600; // Detect if the device is a tablet

    return Scaffold(
      // Ensure the body takes the full screen height
      body: SizedBox(
        height: screenSize.height, // Set the height to the full screen height
        width: screenSize.width,  // Set the width to the full screen width
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E3A8A), // Deep blue
                Color(0xFF3B82F6), // Lighter blue
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.05, // 5% of screen width
                  vertical: screenSize.height * 0.02, // 2% of screen height
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Custom AppBar-like header
                    _buildCustomAppBar(screenSize, isTablet),
                    SizedBox(height: screenSize.height * 0.05), // Responsive spacing

                    // Title with animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Live Number Plate Detection',
                        style: TextStyle(
                          fontSize: isTablet ? 40 : 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // White text for contrast
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.03), // Responsive spacing

                    // Subtitle for additional context
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Scan and detect number plates in real-time!',
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70, // Slightly muted white
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.05), // Responsive spacing

                    // Image with animation and creative styling
                    ScaleTransition(
                      scale: _scaleAnimation,
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
                          child: Image(
                            image: const AssetImage('assets/images/home_page_pic.jpeg'),
                            width: screenSize.width * 0.85, // 85% of screen width
                            height: screenSize.height * 0.35, // 35% of screen height
                            fit: BoxFit.cover, // Ensure the image scales properly
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.05), // Responsive spacing

                    // Animated button with gradient and hover effect
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildCustomButton(screenSize, isTablet),
                    ),
                    // Add extra space at the bottom to ensure content is scrollable if needed
                    SizedBox(height: screenSize.height * 0.05),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Custom AppBar-like header
  Widget _buildCustomAppBar(Size screenSize, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: screenSize.height * 0.02,
        horizontal: screenSize.width * 0.05,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1), // Semi-transparent white
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
            Icons.directions_car,
            color: Colors.white,
            size: 30,
          ),
          SizedBox(width: screenSize.width * 0.02),
          Text(
            'Number Plate Detector',
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

  // Custom button with gradient and hover effect
  Widget _buildCustomButton(Size screenSize, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFA726), // Orange
            Color(0xFFFF5722), // Deep Orange
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScanPlatePage()),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: screenSize.width * 0.15, // 15% of screen width
            vertical: screenSize.height * 0.025, // 2.5% of screen height
          ),
          backgroundColor: Colors.transparent, // Transparent to show gradient
          shadowColor: Colors.transparent, // Avoid default shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          'Start Scanning Now',
          style: TextStyle(
            fontSize: isTablet ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: Colors.white, // White text for contrast
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}