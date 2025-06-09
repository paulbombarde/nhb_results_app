import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html_to_image/html_to_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';


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

class SvgImage extends StatefulWidget{
  const SvgImage({super.key});

  @override
  State<SvgImage> createState() => _SvgImageState();
}

class _SvgImageState extends State<SvgImage> {
  Uint8List? img;

  Future<void> convertToImageFromAsset() async {
    final image = await HtmlToImage.convertToImageFromAsset(
      asset: 'assets/www/results_h1.svg',
      width: 1080
    );
    setState(() {
      img = image;
    });
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
    if(img == null){
      convertToImageFromAsset();
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('HTML to Image Converter'),
          actions: [ImageControls(imgState: this)]
        ),
        body: 
            Center(
                child: 
        img == null ?
                  Text("wait")
            : Image.memory(img!)
              )
      );
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
            imgState.convertToImageFromAsset();
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

