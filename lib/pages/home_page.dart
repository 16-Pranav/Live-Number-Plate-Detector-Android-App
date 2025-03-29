import 'package:flutter/material.dart';
import 'package:live_num_plate_detect/pages/open_camera.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Padding(
          padding: EdgeInsets.all(26.0), // Adds padding around the text
          child: Text('Home Page'),
        ),
        centerTitle: true,
      ) ,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Live Number Plate Detection System',
            style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40), // Add some space between the text and the image
          const Image(
            image: AssetImage('assets/images/home_page_pic.jpeg'),
            width: 1000,
            height: 500,
          ),
          const SizedBox(height: 40, width: 200,), // Add some space between the image and the button

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OpenCamera()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              backgroundColor: Colors.orangeAccent,// Adjust padding as needed
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            child: const Text('Click here to continue',
              style: TextStyle(color: Colors.black),),
          ),
        ],
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:number_plate_detector/pages/open_camera.dart';
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         title: const Padding(
//           padding: EdgeInsets.symmetric(vertical: 26.0),
//           child: Text(
//             'Number Plate Detection',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//           ),
//         ),
//         centerTitle: true,
//         elevation: 2,
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 20.0),
//               child: Text(
//                 'Live Number Plate Detection System',
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   height: 1.3,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             const SizedBox(height: 40),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20.0),
//               child: Image.asset(
//                 'assets/images/figma_design_landing_page.jpg',
//                 fit: BoxFit.contain,
//               ),
//             ),
//             const SizedBox(height: 40),
//             _buildStartButton(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStartButton() {
//     return ElevatedButton(
//       onPressed: () => _navigateToCameraScreen(),
//       style: ElevatedButton.styleFrom(
//         padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
//         backgroundColor: Colors.orangeAccent[700],
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         textStyle: const TextStyle(
//           fontSize: 20,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       child: const Text(
//         'Start Detection',
//         style: TextStyle(color: Colors.black87),
//       ),
//     );
//   }
//
//   void _navigateToCameraScreen() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => OpenCamera(),
//       ),
//     );
//   }
// }