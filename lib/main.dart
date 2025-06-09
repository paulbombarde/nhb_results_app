import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html_to_image/html_to_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as im;

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const SvgImage(),
    );
  }
}

class SvgImage extends StatefulWidget {
  const SvgImage({super.key});

  @override
  State<SvgImage> createState() => _SvgImageState();
}

class _SvgImageState extends State<SvgImage> {
  Uint8List? img;
  final int imgSize = 1080;

  /// Creates an HTML wrapper with proper font references for SVG content
  String _htmlWrapper(String svgContent) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    @font-face {
      font-family: 'Barlow Condensed';
      font-style: normal;
      font-weight: 100;
      src: url('assets/fonts/BarlowCondensed-Thin.ttf') format('truetype');
    }
    @font-face {
      font-family: 'Barlow Condensed';
      font-style: normal;
      font-weight: 200;
      src: url('assets/fonts/BarlowCondensed-ExtraLight.ttf') format('truetype');
    }
    @font-face {
      font-family: 'Barlow Condensed';
      font-style: normal;
      font-weight: 300;
      src: url('assets/fonts/BarlowCondensed-Light.ttf') format('truetype');
    }
    @font-face {
      font-family: 'Barlow Condensed';
      font-style: normal;
      font-weight: 400;
      src: url('assets/fonts/BarlowCondensed-Regular.ttf') format('truetype');
    }
    @font-face {
      font-family: 'Barlow Condensed';
      font-style: normal;
      font-weight: 500;
      src: url('assets/fonts/BarlowCondensed-Medium.ttf') format('truetype');
    }
    @font-face {
      font-family: 'Barlow Condensed';
      font-style: normal;
      font-weight: 600;
      src: url('assets/fonts/BarlowCondensed-SemiBold.ttf') format('truetype');
    }
    @font-face {
      font-family: 'Barlow Condensed';
      font-style: normal;
      font-weight: 700;
      src: url('assets/fonts/BarlowCondensed-Bold.ttf') format('truetype');
    }
    @font-face {
      font-family: 'Barlow Condensed';
      font-style: normal;
      font-weight: 800;
      src: url('assets/fonts/BarlowCondensed-ExtraBold.ttf') format('truetype');
    }
    @font-face {
      font-family: 'Barlow Condensed';
      font-style: normal;
      font-weight: 900;
      src: url('assets/fonts/BarlowCondensed-Black.ttf') format('truetype');
    }
    body {
      margin: 0;
      padding: 0;
      font-family: 'Barlow Condensed', sans-serif;
    }
  </style>
</head>
<body>
  <div class="svg-container">
  $svgContent
  </div>
</body>
</html>''';
  }

  Future<void> refreshImage() async {
    try {
      // Load SVG content from assets into memory
      final svgContent =
          await rootBundle.loadString('assets/www/results_h1.svg');

      // Wrap SVG content in HTML with proper font references
      final htmlContent = _htmlWrapper(svgContent);

      final image = await HtmlToImage.tryConvertToImage(
          content: htmlContent, width: imgSize);

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

      final rawImg = im.decodeImage(img!);
      final pngImg = im.encodePng(rawImg!);

      // Write image data to file
      await file.writeAsBytes(pngImg!);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'NHB Match Result',
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
    }
  }

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
}

class ImageControls extends StatelessWidget {
  const ImageControls({required this.imgState, super.key});

  final _SvgImageState imgState;

  // Check if the current platform is mobile (iOS or Android)
  bool get _isMobilePlatform {
    return !kIsWeb &&
        (defaultTargetPlatform == foundation.TargetPlatform.iOS ||
            defaultTargetPlatform == foundation.TargetPlatform.android);
  }

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
}
