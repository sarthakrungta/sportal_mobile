import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // To get the temporary directory
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:html' as html;


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
    // Convert imageBytes to a Blob and create a URL for it
    final blob = html.Blob([imageBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Use Web Share API if available
    if (html.window.navigator.share != null) {
      await html.window.navigator.share({
        'title': 'Shared Image',
        'text': 'Check out this image!',
        'url': url,
      });
    } else {
      // If Web Share API is not supported, fallback to download
      _downloadImage(imageBytes);
    }

    // Revoke the object URL after sharing
    html.Url.revokeObjectUrl(url);
  } catch (e) {
    print("Error sharing image: $e");
    _downloadImage(imageBytes); // Fallback to download
  }
}

void _downloadImage(Uint8List imageBytes) {
  try {
    // Convert imageBytes to a Blob and create a URL for it
    final blob = html.Blob([imageBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Create an anchor element and trigger a download
    final anchor = html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = 'shared_image.png'
      ..click();

    // Revoke the object URL after download
    html.Url.revokeObjectUrl(url);
  } catch (e) {
    print("Error downloading image: $e");
  }
}


}
