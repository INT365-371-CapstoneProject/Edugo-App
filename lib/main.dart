import 'package:edugo/features/scholarship/screens/provider_management.dart';
import 'package:edugo/features/profile/screens/profile.dart';
import 'package:edugo/pages/intro.dart';
import 'package:edugo/pages/splash_screen.dart';
import 'package:edugo/pages/subject_manage.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(SplashScreenApp());
}

class SplashScreenApp extends StatelessWidget {
  const SplashScreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SplashScreen(),
    );
  }
}

// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: ImagePickerExample(),
//     );
//   }
// }

// class ImagePickerExample extends StatefulWidget {
//   @override
//   _ImagePickerExampleState createState() => _ImagePickerExampleState();
// }

// class _ImagePickerExampleState extends State<ImagePickerExample> {
//   Uint8List? _imageData;

//   final ImagePicker _picker = ImagePicker();

//   Future<void> _pickImage() async {
//     final XFile? pickedFile =
//         await _picker.pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       final Uint8List imageBytes = await pickedFile.readAsBytes();
//       setState(() {
//         _imageData = imageBytes;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Image Picker Example'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             _imageData == null
//                 ? const Text('No image selected.')
//                 : Image.memory(
//                     _imageData!,
//                     width: 300,
//                     height: 300,
//                     fit: BoxFit.cover,
//                   ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _pickImage,
//               child: const Text('Pick Image from Gallery'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
