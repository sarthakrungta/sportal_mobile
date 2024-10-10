import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // To get the temporary directory
import 'package:share_plus/share_plus.dart';

class ImageBottomSheet extends StatelessWidget {
  final Uint8List imageBytes;
  final VoidCallback onRedesign;

  const ImageBottomSheet({
    Key? key,
    required this.imageBytes,
    required this.onRedesign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        // Set dynamic height based on screen size, reducing the chance of overflow
        height: MediaQuery.of(context).size.height * 0.7, // 70% of screen height
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24.0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Wrapping the image in a Flexible widget to avoid overflow
            Flexible(
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain, // Ensures the image fits within the bounds
              ),
            ),
            const SizedBox(height: 25,),
            ElevatedButton(
              onPressed: () async {
                await _shareImage(imageBytes); // Call the method to share the image
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 10),
                backgroundColor: const Color.fromRGBO(60, 17, 185, 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: const Text(
                'Share',
                style: TextStyle(
                    fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 5),
            TextButton(
              onPressed: onRedesign,
              child: const Text(
                'Re-design',
                style: TextStyle(
                  color: Color.fromRGBO(107, 78, 255, 1), // Specific color
                  fontSize: 16, // Adjust font size if needed
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _shareImage(Uint8List imageBytes) async {
    try {
      // Get the temporary directory
      final tempDir = await getTemporaryDirectory();

      // Create the file path
      final filePath = '${tempDir.path}/shared_image.png';

      // Write the image bytes to a file
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Share the image file
      await Share.shareXFiles([XFile(filePath)],
          text: 'Check out this gameday image!');
    } catch (e) {
      print("Error sharing image: $e");
    }
  }
}
