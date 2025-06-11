import 'dart:async';
import 'dart:io';
import 'dart:math';
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

  final List<Match> dummyMatches = [
    Match(
      date: "Samedi 10 Septembre",
      place: "Stadium A",
      level: "Premier League",
      team1: "Team Alpha",
      team2: "Team Beta",
      score1: "10",
      score2: "20",
    ),
    Match(
      date: "Samedi 10 Septembre",
      place: "Arena Central",
      level: "Championship",
      team1: "Lions FC",
      team2: "Eagles United",
      score1: "25",
      score2: "18",
    ),
    Match(
      date: "Samedi 10 Septembre",
      place: "Sports Complex B",
      level: "Division 1",
      team1: "Thunder Bolts",
      team2: "Storm Riders",
      score1: "32",
      score2: "28",
    ),
    Match(
      date: "Dimanche 11 Septembre",
      place: "Metropolitan Stadium",
      level: "Premier League",
      team1: "Fire Dragons",
      team2: "Ice Wolves",
      score1: "15",
      score2: "22",
    ),
    Match(
      date: "Dimanche 11 Septembre",
      place: "Victory Arena",
      level: "Championship",
      team1: "Golden Hawks",
      team2: "Silver Sharks",
      score1: "41",
      score2: "35",
    ),
    Match(
      date: "Dimanche 11 Septembre",
      place: "Elite Sports Center",
      level: "Division 1",
      team1: "Crimson Tigers",
      team2: "Azure Panthers",
      score1: "29",
      score2: "31",
    ),
  ];

  @override
  State<SvgImage> createState() => SvgImageState();
}

class SvgImageState extends State<SvgImage> {
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

  Future<Uint8List?> convertSvg(String template, List<Match> matches) async {
      // Load SVG content from assets into memory
      final svgContent =
          await rootBundle.loadString(template);

      // Parse SVG as XML and replace text elements based on inkscape:label attributes
      final modifiedSvgContent = _replaceSvgTextElements(svgContent, matches);

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
        width: decodedImage.width,
        height: decodedImage.width
      );
      
      return im.encodePng(croppedImg);
  }

  /// Replaces text elements in SVG based on their inkscape:label attributes
  String _replaceSvgTextElements(String svgContent, List<Match> matches) {
    try {
      final document = XmlDocument.parse(svgContent);
      
      // Find all text elements with inkscape:label attributes
      final textElements = document.findAllElements('text')
          .where((element) => element.getAttribute('inkscape:label') != null);
      
      for (final textElement in textElements) {
        final label = textElement.getAttribute('inkscape:label');
        String? replacementText;
        
        // Handle date field using the first match
        if (label == 'date' && matches.isNotEmpty) {
          replacementText = matches[0].date;
        } else if (label != null && label.startsWith('match')) {
          // Parse match number from label (e.g., 'match1-team1' -> matchNumber = 1)
          final parts = label.split('-');
          if (parts.length == 2) {
            final matchPrefix = parts[0]; // e.g., 'match1'
            final fieldName = parts[1];   // e.g., 'team1'
            
            // Extract match number from prefix (e.g., 'match1' -> 1)
            final matchNumberStr = matchPrefix.replaceFirst('match', '');
            final matchNumber = int.tryParse(matchNumberStr);
            
            if (matchNumber != null && matchNumber >= 1 && matchNumber <= matches.length) {
              final match = matches[matchNumber - 1]; // Convert to 0-based index
              
              // Map field names to match properties
              switch (fieldName) {
                case 'team1':
                  replacementText = match.team1;
                  break;
                case 'team2':
                  replacementText = match.team2;
                  break;
                case 'score1':
                  replacementText = match.score1;
                  break;
                case 'score2':
                  replacementText = match.score2;
                  break;
              }
            }
          }
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

  Future<Uint8List?> generateImageData(String template, List<Match> matches) async {
      final image = await convertSvg(template, matches);
      return cropImage(image!);
  }

  /// Selects a random subset of matches (up to 4 matches) from the available dummy matches
  List<Match> _getRandomMatches(int numMatches) {
    final random = Random();
    final availableMatches = List<Match>.from(widget.dummyMatches);
    
    // Shuffle the list and take the first numMatches
    availableMatches.shuffle(random);
    return availableMatches.take(numMatches).toList();
  }

  Future<void> refreshImage() async {
    try {
      final randomMatches = _getRandomMatches(4);
      final image = await generateImageData('assets/www/results_4.svg', randomMatches);
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

  final SvgImageState imgState;

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
