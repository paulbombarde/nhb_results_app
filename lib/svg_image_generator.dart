import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:html_to_image/html_to_image.dart';
import 'package:image/image.dart' as im;
import 'package:xml/xml.dart';
import 'match.dart';

class SvgImageGenerator {
  /// Main method to generate image data from SVG template and match data
  static Future<Uint8List?> generateImageData(String template, List<Match> matches, {int size = 1080}) async {
    final image = await convertSvg(template, matches, size);
    return cropImage(image!);
  }

  /// Converts SVG template with match data to image
  static Future<Uint8List?> convertSvg(String template, List<Match> matches, int size) async {
    // Load SVG content from assets into memory
    final svgContent = await rootBundle.loadString(template);
    return convertSvgFromString(svgContent, matches, size);
  }

  static Future<Uint8List?> convertSvgFromString(
      String svgStringTemplate, List<Match> matches, int size) async {
    // Parse SVG as XML and replace text elements based on inkscape:label attributes
    final modifiedSvgContent =
        replaceSvgTextElements(svgStringTemplate, matches);

    // Wrap SVG content in HTML with proper font references
    final htmlContent = _htmlWrapper(modifiedSvgContent);

    return HtmlToImage.tryConvertToImage(content: htmlContent, width: size);
  }

  /// Crops the generated image to remove white banner at the bottom
  static Uint8List cropImage(Uint8List initialImage) {
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
  static String replaceSvgTextElements(String svgContent, List<Match> matches) {
    try {
      final document = XmlDocument.parse(svgContent);
      
      // Find all text elements with inkscape:label attributes
      final textElements = document.findAllElements('text')
          .where((element) => element.getAttribute('inkscape:label') != null);
      
      for (final textElement in textElements) {
        final label = textElement.getAttribute('inkscape:label');
        String? replacementText;
        String? replacementColor;
        
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
                  replacementText = match.fullTeam1();
                  replacementColor = match.colorTeam1();
                  break;
                case 'team2':
                  replacementText = match.fullTeam2();
                  replacementColor = match.colorTeam2();
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
            _updateColor(tspanElement, replacementColor);
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

  static void _updateColor(XmlElement elem, String? color) {
    if (color != null) {
      // Update the text color
      String style = _updateStyleColor(elem.getAttribute("style"), color);
      elem.setAttribute("style", style);
    }
  }

  static String _updateStyleColor(style, color) {
    if (style == null) {
      return "fill:$color";
    }

    if (!style.contains("fill:")) {
      return "$style;fill:$color";
    }

    List<String> elements = style.split(";");
    List<String> updatedElements = [];
    for (String element in elements) {
      updatedElements.add(element.startsWith("fill") ? "fill:$color" : element);
    }

    return updatedElements.join(";");
  }

  /// Creates an HTML wrapper with proper font references for SVG content
  static String _htmlWrapper(String svgContent) {
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
}