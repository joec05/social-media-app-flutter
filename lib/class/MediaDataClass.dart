import 'package:flutter/material.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:video_player/video_player.dart';
import 'WebsiteCardClass.dart';

class MediaDatasClass{
  final MediaType mediaType;
  String url;
  VideoPlayerController? playerController;
  String storagePath;
  MediaSourceType mediaSourceType;
  WebsiteCardClass? websiteCardData;
  Size? mediaSize;

  MediaDatasClass(
    this.mediaType, this.url, this.playerController, this.storagePath, this.mediaSourceType,
    this.websiteCardData, this.mediaSize
  );

  Map<String, dynamic> toMap(){
    return {
      'mediaType': mediaType.name,
      'url': url,
      'storagePath': storagePath
    };
  }
}