import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:html_to_image/html_to_image.dart';
import 'package:image/image.dart' as im;
import 'package:xml/xml.dart';
import 'match.dart';

class SvgImageGenerator {
  /// Main method to generate image data from SVG template and match data
  static Future<Uint8List?> generateImageData(String templateAssetPath, List<Match> matches, {int size = 1080}) async {
    final image = await convertSvg(templateAssetPath, matches, size);
    return cropImage(image!);
  }

  /// Converts SVG template with match data to image
  static Future<Uint8List?> convertSvg(String templateAssetPath, List<Match> matches, int size) async {
    // Load SVG content from assets into memory
    final svgContent = await rootBundle.loadString(templateAssetPath);
    return convertSvgFromString(svgContent, matches, size);
  }

  static Future<Uint8List?> convertSvgFromString(
      String svgStringTemplate, List<Match> matches, int size) async {
    // Parse SVG as XML and replace text elements and sponsor images
    final modifiedSvgContent = await _processTemplate(svgStringTemplate, matches);

    // Wrap SVG content in HTML with proper font references
    final htmlContent = _htmlWrapper(modifiedSvgContent);

    return HtmlToImage.tryConvertToImage(content: htmlContent, width: size);
  }

  /// Process the SVG template by replacing text elements and sponsor images
  static Future<String> _processTemplate(String svgContent, List<Match> matches) async {
    try {
      final document = XmlDocument.parse(svgContent);

      // First replace text elements
      replaceXmlTextElements(document, matches);
      
      // Then replace sponsor images
      await _replaceSponsorImages(document);
      return document.toXmlString();
    } catch (e) {
      debugPrint('Error processing SVG template: $e');
      return svgContent;
    }
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
  static void replaceXmlTextElements(XmlDocument document, List<Match> matches) {
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
          if (tspanElement == null) {
            throw "Missing tspan in Text element to replace";
          }
          _updateColor(tspanElement, replacementColor);

          int splitIndex = -1;
          if (replacementText.length > 22) { // Magic!
            // Find the split place: we search for the first 'split like' characater.
            // If non is found, we leave the string intact. The user will have to edit
            // the string and add one split character where it makes more sense.
            int mid = (replacementText.length / 2).ceil();
            splitIndex = replacementText.indexOf(RegExp(r'[ /\\-]'), mid);
          }

          if( splitIndex < 0) {
            tspanElement.innerText = replacementText;
          }
          else {
            final int offsetY = 80; // Yeah, magic number!
            final initialY = double.parse(tspanElement.getAttribute('y')!);

            tspanElement.innerText = replacementText.substring(0, splitIndex);
            tspanElement.setAttribute('y', (initialY - offsetY).toString());

            // If the split point is a space, remove it, else the new span
            // looks weirdly indented.
            String secondLine = replacementText.substring(splitIndex);
            while (secondLine.startsWith(' ')){
              secondLine = secondLine.substring(1);
            }

            // Create a new tspan element for the second half of the text
            final builder = XmlBuilder();
            builder.element('tspan', nest: () {
              builder.attribute('x', tspanElement.getAttribute('x')!);
              builder.attribute('y', (initialY + offsetY).toString());
              builder.attribute('sodipodi:role', 'line');
              builder.attribute('style', tspanElement.getAttribute('style'));
              builder.text(secondLine);
            });
            
            // Add the new tspan to the text element
            final newTspan = builder.buildFragment().firstChild!.copy();
            textElement.children.add(newTspan);
          }
        }
      }
  }

  static void _updateColor(XmlElement elem, String? color) {
    if (color != null) {
      // Update the text color
      String style = _updateStyleColor(elem.getAttribute("style"), color);
      elem.setAttribute("style", style);
    }
  }

  static String _updateStyleColor(String? style, String color) {
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

  /// Lists all sponsor images available in the assets/sponsors folder
  static Future<List<String>> _getSponsorImages() async {
    try {
      // Get the asset manifest
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // Filter for sponsor images
      final sponsorImages = manifestMap.keys
          .where((String key) => key.startsWith('assets/sponsors/') && 
                               (key.endsWith('.png') || key.endsWith('.jpg')))
          .toList();
      
      return sponsorImages;
    } catch (e) {
      debugPrint('Error loading sponsor images: $e');
      return [];
    }
  }
  
  /// Converts an image asset to base64 string
  static Future<String?> _imageAssetToBase64(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('Error converting image to base64: $e');
      return null;
    }
  }

  /// Replaces sponsor images in the SVG with random images from assets/sponsors
  static Future<void> _replaceSponsorImages(XmlDocument document) async {
    try {
      // Get list of available sponsor images
      final sponsorImages = await _getSponsorImages();
      if (sponsorImages.isEmpty) {
        debugPrint('No sponsor images found');
        return;
      }
      
      // Find all image elements with inkscape:label attributes for sponsors
      final imageElements = document.findAllElements('image')
          .where((element) => 
              element.getAttribute('inkscape:label') == 'sponsor1' || 
              element.getAttribute('inkscape:label') == 'sponsor2');
      
      final random = Random();
      
      for (final imageElement in imageElements) {
        // Select a random sponsor image
        if (sponsorImages.isEmpty) break;
        final randomIndex = random.nextInt(sponsorImages.length);
        final selectedImage = sponsorImages[randomIndex];
        
        // Read data
        final ByteData data = await rootBundle.load(selectedImage);
        final Uint8List bytes = data.buffer.asUint8List();

        // Convert image to base64
        final base64Image = base64Encode(bytes);
        
        // Update the xlink:href attribute with the new base64 image
        final String mimeType = selectedImage.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
        imageElement.setAttribute('xlink:href', 'data:$mimeType;base64,$base64Image');

        // Get image height and width, apply the correct ratio and keep the image in place.
        final image = im.decodeImage(bytes);
        final initial_h = image!.height;

        final svg_width = double.parse(imageElement.getAttribute('height')!) * image.width / image.height;
        final svg_dx = 0.5 * (double.parse(imageElement.getAttribute('width')!) - svg_width);
        final svg_x = double.parse(imageElement.getAttribute('x')!) + svg_dx;

        imageElement.setAttribute('x', svg_x.toString());
        imageElement.setAttribute('width', svg_width.toString());
        
        // Remove the selected image from the list to avoid duplicates
        sponsorImages.removeAt(randomIndex);
      }
    } catch (e) {
      debugPrint('Error replacing sponsor images: $e');
    }
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