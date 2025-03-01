import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // To get the temporary directory
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:share_plus/share_plus.dart';

class ImageBottomSheet extends StatelessWidget {
  final Uint8List imageBytes;
  final VoidCallback onRedesign;
  final String imageName;

  const ImageBottomSheet({
    super.key,
    required this.imageBytes,
    required this.onRedesign,
    required this.imageName
  });

  @override
  Widget build(BuildContext context) {
    final RoundedLoadingButtonController _btnController =
        RoundedLoadingButtonController();
    return SafeArea(
      child: Container(
          // Set dynamic height based on screen size, reducing the chance of overflow
          height:
              MediaQuery.of(context).size.height * 0.6, // 70% of screen height
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
              // Wrapping the image in a Flexible widget with a subtle shadow
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(0.1), // Subtle shadow color
                        spreadRadius: 2, // Slight spread
                        blurRadius: 5, // Soft blur
                        offset: const Offset(0, 3), // Drop shadow (bottom only)
                      ),
                    ],
                  ),
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit
                        .contain, // Ensures the image fits within the bounds
                  ),
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              RoundedLoadingButton(
                controller: _btnController,
                color: const Color.fromRGBO(60, 17, 185, 1),
                onPressed: () async {
                  await _shareImage(imageBytes);
                  _btnController.stop();
                  Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Magic Created',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              backgroundColor: Color.fromRGBO(68,186,85, 1), // Custom purple color
              behavior: SnackBarBehavior
                  .floating, // Optional: to make it float above the bottom
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
            ),
          );
                },
                child:
                    const Text('Share', style: TextStyle(color: Colors.white)),
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
          )),
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
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      print("Error sharing image: $e");
    }
  }
}
