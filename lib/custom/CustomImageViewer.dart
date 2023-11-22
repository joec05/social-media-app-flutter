import 'dart:io';
import 'package:flutter/material.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';

class CustomImageViewer extends StatelessWidget {
  final MediaSourceType mediaSource;
  final String imageUrl;

  const CustomImageViewer({Key? key, required this.mediaSource, required this.imageUrl}): super(key: key);

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: CustomImageViewerState(mediaSource: mediaSource, imageUrl: imageUrl)
    );
  }
}

class CustomImageViewerState extends StatefulWidget{
  final MediaSourceType mediaSource;
  final String imageUrl;

  const CustomImageViewerState({super.key, required this.mediaSource, required this.imageUrl});

  @override
  State<CustomImageViewerState> createState() => CustomImageViewerSection();
}

class CustomImageViewerSection extends State<CustomImageViewerState>{
  late MediaSourceType mediaSource;
  late String imageUrl;

  @override
  void initState(){
    super.initState();
    mediaSource = widget.mediaSource;
    imageUrl = widget.imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getScreenHeight(),
      child: InteractiveViewer(
        child: Center(
          child: mediaSource == MediaSourceType.file ?
            Image.file(
              File(imageUrl),
              width: getScreenWidth(),
              fit: BoxFit.cover,
            )
          : mediaSource == MediaSourceType.network ?
            Image.network(
              imageUrl,
              width: getScreenWidth(),
              fit: BoxFit.cover,
            )
          : Container()
        )
      )
    );
  }
}

