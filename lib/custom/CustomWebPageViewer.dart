// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class CustomWebPageViewer extends StatefulWidget {
  final String url;

  const CustomWebPageViewer({super.key, required this.url});

  @override
  _CustomWebPageViewerState createState() => _CustomWebPageViewerState();
}

class _CustomWebPageViewerState extends State<CustomWebPageViewer> {
  final ValueNotifier<double> _progress = ValueNotifier(0);

  @override
  void initState(){
    super.initState();
  }

  @override
  void dispose(){
    super.dispose();
    _progress.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: Uri.parse(widget.url)),
            onWebViewCreated: (controller) {
            },
            onProgressChanged: (controller, progress) {
              if(mounted){
                _progress.value = progress / 100;
              }
            },
          ),
        ]
      )
    );
  }
}
