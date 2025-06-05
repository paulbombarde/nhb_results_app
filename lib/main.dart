import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:jovial_svg/jovial_svg.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:html_to_image/html_to_image.dart';

import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

import 'src/menu.dart';
import 'src/web_view_stack.dart';
import 'src/navigation_controls.dart';


void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      //home: const CenteredImage(),
      //home: const WebViewApp(),
      home: const SvgImage(),
    );
  }
}

class CenteredImage extends StatelessWidget {
  const CenteredImage({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('My Home Page'),
        ),
        body: Center(
          child: Builder(
            builder: (context) {
              return Column(
                children: [
                  const Text('Hello, World!'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      print('Click!');
                    },
                    child: const Text('A button'),
                  ),
                ],
              );
            },
          ),
        ),
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

  static const _dummyContent = '''
  <html>
  <head>
  <title>
  Example of Paragraph tag
  </title>
  </head>
  <body>
  <p> <!-- It is a Paragraph tag for creating the paragraph -->
  <b> HTML </b> stands for <i> <u> Hyper Text Markup Language. </u> </i> It is used to create a web pages and applications. This language
  is easily understandable by the user and also be modifiable. It is actually a Markup language, hence it provides a flexible way for designing the
  web pages along with the text.
  <img src="https://picsum.photos/200/300" />
  <br />
  </body>
  </html>
  ''';

  Future<void> convertToImage() async {
    final image = await HtmlToImage.tryConvertToImage(
      content: _dummyContent,
    );
    setState(() {
      img = image;
    });
  }

  Future<void> convertToImageFromAsset() async {
    final image = await HtmlToImage.convertToImageFromAsset(
      asset: 'assets/www/results_h1.svg',
      width: 1080
    );
    setState(() {
      img = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    if(img == null){
      convertToImageFromAsset();
      //convertToImage();
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('HTML to Image Converter'),
          actions: [ImageControls(img_state: this)]
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
  const ImageControls({required this.img_state, super.key});

  final _SvgImageState img_state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.replay),
          onPressed: () {
            img_state.convertToImageFromAsset();
          },
        ),
      ],
    );
  }
}

class WebViewApp extends StatefulWidget {
  const WebViewApp({super.key});

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
    ..loadFlutterAsset('assets/www/results_h1.svg');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter WebView'),
        actions: [
          NavigationControls(controller: controller),
          Menu(controller: controller),
        ],
      ),
      body: WebViewStack(controller: controller),
    );
  }
}
