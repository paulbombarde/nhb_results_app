import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'svg_image_generator.dart';
import 'services/handball_service.dart';
import 'transformers/handball_transformer.dart';
import 'screens/loading_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run the app with ProviderScope
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NHB Results App',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        fontFamily: 'Barlow Condensed',
      ),
      home: const LoadingScreen(),
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
  bool isLoading = false;
  String errorMessage = '';
  final HandballService _handballService = HandballService();

  @override
  Widget build(BuildContext context) {
    if (img == null && !isLoading && errorMessage.isEmpty) {
      refreshImage();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('NHB Match Results'),
        actions: [ImageControls(imgState: this)],
      ),
      body: Center(
        child: isLoading
          ? const CircularProgressIndicator()
          : errorMessage.isNotEmpty
            ? Text('Error: $errorMessage', style: const TextStyle(color: Colors.red))
            : img == null
              ? const Text("Generating image...")
              : Image.memory(img!),
      ),
    );
  }

  Future<void> refreshImage() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Get real handball games from the API
      final games = await _handballService.getCompletedGames();
      
      if (games.isEmpty) {
        setState(() {
          errorMessage = 'No completed games found';
          isLoading = false;
        });
        return;
      }
      
      // Take up to 4 most recent games
      final recentGames = games.take(4).toList();
      
      // Transform HandballGame objects to Match objects
      final matches = HandballTransformer.fromHandballGames(recentGames);
      
      // Generate the image using the transformed matches
      final image = await SvgImageGenerator.generateImageData(
        'assets/www/results_${matches.length}.svg',
        matches
      );
      
      setState(() {
        img = image;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error generating image: $e');
      setState(() {
        img = null;
        isLoading = false;
        errorMessage = e.toString();
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
  void dispose() {
    _handballService.dispose();
    super.dispose();
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

