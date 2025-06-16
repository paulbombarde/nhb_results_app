import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../models/handball_models.dart';
import '../providers/handball_providers.dart';

class ImageGenerationScreen extends ConsumerWidget {
  final List<HandballGame> selectedGames;
  
  const ImageGenerationScreen({
    super.key,
    required this.selectedGames,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageAsync = ref.watch(imageGenerationProvider(selectedGames));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated Image'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: imageAsync.when(
        data: (imageData) {
          if (imageData == null) {
            return const Center(
              child: Text('Failed to generate image'),
            );
          }
          
          return ImageDisplay(
            imageData: imageData,
            onShare: () => _shareImage(context, imageData),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating image...'),
            ],
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(imageGenerationProvider(selectedGames));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _shareImage(BuildContext context, Uint8List imageData) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/handball_results.png');
      
      // Write image data to file
      await file.writeAsBytes(imageData);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Handball match results',
      );
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class ImageDisplay extends StatelessWidget {
  final Uint8List imageData;
  final VoidCallback onShare;
  
  const ImageDisplay({
    super.key,
    required this.imageData,
    required this.onShare,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.0,
            child: Image.memory(imageData),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share),
            label: const Text('Share Image'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}