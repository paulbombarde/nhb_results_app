import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'match.dart';
import 'svg_image_generator.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: SvgImage(),
    );
  }
}

class SvgImage extends StatefulWidget {
  const SvgImage({super.key});


  @override
  State<SvgImage> createState() => SvgImageState();
}

class SvgImageState extends State<SvgImage> {
  Uint8List? img;

  @override
  Widget build(BuildContext context) {
    if (img == null) {
      refreshImage();
    }

    return Scaffold(
        appBar: AppBar(
            title: const Text('HTML to Image Converter'),
            actions: [ImageControls(imgState: this)]),
        body: img == null ? Text("wait") : Image.memory(img!));
  }

  Future<void> refreshImage() async {
    try {
      final randomMatches = getRandomMatches(4);
      final image = await SvgImageGenerator.generateImageData('assets/www/results_4.svg', randomMatches);
      setState(() {
        img = image;
      });
    } catch (e) {
      debugPrint('Error loading SVG from asset: $e');
      setState(() {
        img = null;
      });
    }
  }

  // Method to share the current image
  Future<void> shareImage() async {
    if (img == null) {
      // No image to share
      return;
    }

    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/nhb_result_image.png');

      // Write image data to file
      await file.writeAsBytes(img!);

      // Share the file
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: 'NHB Match Result',
      ));
    } catch (e) {
      debugPrint('Error sharing image: $e');
    }
  }
}

class ImageControls extends StatelessWidget {
  const ImageControls({required this.imgState, super.key});

  final SvgImageState imgState;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.replay),
          onPressed: () {
            imgState.refreshImage();
          },
        ),
        // Only show share button on mobile platforms
        if (_isMobilePlatform)
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              if (imgState.img != null) {
                imgState.shareImage();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No image to share')),
                );
              }
            },
          ),
      ],
    );
  }

  // Check if the current platform is mobile (iOS or Android)
  bool get _isMobilePlatform {
    return !kIsWeb &&
        (defaultTargetPlatform == foundation.TargetPlatform.iOS ||
            defaultTargetPlatform == foundation.TargetPlatform.android);
  }
}
