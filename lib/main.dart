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
import 'package:xml/xml.dart';
import 'match.dart';

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
  SvgImage({super.key});

  final Match dummyMatch = Match(
    time: "15:30",
    place: "Stadium A",
    level: "Premier League",
    team1: "Team Alpha",
    team2: "Team Beta",
    score1: "10",
    score2: "20",
  );

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
  <div class="svg-container" width=1080>
  $svgContent
  </div>
</body>
</html>''';
  }

  Future<Uint8List?> convertSvg(Match match) async {
      // Load SVG content from assets into memory
      final svgContent =
          await rootBundle.loadString('assets/www/results_h1.svg');

      // Parse SVG as XML and replace text elements based on inkscape:label attributes
      final modifiedSvgContent = _replaceSvgTextElements(svgContent, match);

      // Wrap SVG content in HTML with proper font references
      final htmlContent = _htmlWrapper(modifiedSvgContent);

      return HtmlToImage.tryConvertToImage(
          content: htmlContent, width: imgSize);
  }

  Uint8List cropImage(Uint8List initialImage) {
      final decodedImage = im.decodeImage(initialImage);

      // Crop the image to remove white banner at the bottom
      // Maintain original width but crop height to imgSize (1080px)
      final croppedImg = im.copyCrop(decodedImage!,
        x: 0,
        y: 0,
        width: decodedImage!.width,
        height: decodedImage!.width
      );
      
      return im.encodePng(croppedImg);
  }

  /// Replaces text elements in SVG based on their inkscape:label attributes
  String _replaceSvgTextElements(String svgContent, Match match) {
    try {
      final document = XmlDocument.parse(svgContent);
      
      // Find all text elements with inkscape:label attributes
      final textElements = document.findAllElements('text')
          .where((element) => element.getAttribute('inkscape:label') != null);
      
      for (final textElement in textElements) {
        final label = textElement.getAttribute('inkscape:label');
        String? replacementText;
        
        // Map inkscape:label values to match data
        switch (label) {
          case 'match1-team1':
            replacementText = match.team1;
            break;
          case 'match1-team2':
            replacementText = match.team2;
            break;
          case 'match1-score1':
            replacementText = match.score1;
            break;
          case 'match1-score2':
            replacementText = match.score2;
            break;
          case 'date':
            // Format the date/time from match data
            replacementText = '${match.time} - ${match.place}';
            break;
        }
        
        if (replacementText != null) {
          // Find the tspan element within the text element and replace its content
          final tspanElement = textElement.findElements('tspan').firstOrNull;
          if (tspanElement != null) {
            tspanElement.innerText = replacementText;
          }
        }
      }
      
      return document.toXmlString();
    } catch (e) {
      debugPrint('Error parsing/modifying SVG: $e');
      // Return original content if parsing fails
      return svgContent;
    }
  }

  Future<void> refreshImage() async {
    try {
      final image = await convertSvg(widget.dummyMatch);
      setState(() {
        img = cropImage(image!);
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
