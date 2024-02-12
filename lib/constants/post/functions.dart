import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui' as ui;

Future<List<MediaDatasClass>> loadMediasDatas(
  BuildContext context,
  List<dynamic> mediasDatasFromServer
) async{
  List<MediaDatasClass> newMediasDatas = [];
  for(int i = 0; i < mediasDatasFromServer.length; i++){
    String mediaUrl = mediasDatasFromServer[i]['url'];
    if(mediasDatasFromServer[i]['mediaType'] == 'video'){
      VideoPlayerController playerController = VideoPlayerController.networkUrl(Uri.parse(mediasDatasFromServer[i]['url']));
      await playerController.initialize();
      Size scaledDimension = getSizeScale(playerController.value.size.width, playerController.value.size.height);
      newMediasDatas.add(MediaDatasClass(
        MediaType.video, mediaUrl, playerController, mediasDatasFromServer[i]['storagePath'],
        MediaSourceType.network, null, scaledDimension
      ));
    }else if(mediasDatasFromServer[i]['mediaType'] == 'image'){
      ui.Image imageDimension = await calculateImageNetworkDimension(mediaUrl);
      Size scaledDimension = getSizeScale(imageDimension.width.toDouble(), imageDimension.height.toDouble());
      newMediasDatas.add(MediaDatasClass(
        MediaType.image, mediaUrl, null, mediasDatasFromServer[i]['storagePath'], 
        MediaSourceType.network, null, scaledDimension
      ));
    }else if(mediasDatasFromServer[i]['mediaType'] == 'websiteCard'){
      WebsiteCardClass linkPreview = await fetchLinkPreview(context, mediaUrl);
      newMediasDatas.add(MediaDatasClass(
        MediaType.websiteCard, mediaUrl, null, mediasDatasFromServer[i]['storagePath'], 
        MediaSourceType.network, linkPreview, null
      ));
    }
  }
  return newMediasDatas;
}

Future<ui.Image> calculateImageFileDimension(url) async{
  final File imageFile = File(url);
  final Uint8List bytes = await imageFile.readAsBytes();
  final Completer<ui.Image> completer = Completer();
  ui.decodeImageFromList(bytes, completer.complete);
  final ui.Image image = await completer.future;
  return image;
}

Future<ui.Image> calculateImageNetworkDimension(url) async{
  Image image = Image.network(url);
  final Completer<ui.Image> completer = Completer<ui.Image>();
  image.image
  .resolve(const ImageConfiguration())
  .addListener(
    ImageStreamListener(
      (ImageInfo info, bool _) => completer.complete(info.image)
    )
  );
  final ui.Image finalImage = await completer.future;
  return finalImage;
}

String displayShortenedCount(int value){
  double dividedValue = 0;
  String lastLetter = '';
  if(value >= 1000000){
    dividedValue = value / 1000000;
    lastLetter = 'M';
  }else if(value >= 10000){
    dividedValue = value / 1000;
    lastLetter = 'K';
  }else{
    return value.toString();
  }
  String valueStr = dividedValue.toString();
  List<String> splitStr = valueStr.split('.');
  if(splitStr.length > 1){
    if(int.parse(splitStr[1][0]) > 0){
      splitStr[1] = splitStr[1][0];
      return '${splitStr.join('.')}$lastLetter';
    }else{
      return '${splitStr[0]}$lastLetter';
    }
  }else{
    return '${splitStr[0]}$lastLetter';
  }
}
