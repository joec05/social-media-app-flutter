import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

Widget mediaDataPostComponentWidget(MediaDatasClass mediaData, BuildContext context){
  if(mediaData.mediaType == MediaType.image){
    return InkWell(
      onTap: (){
        runDelay((){ 
          Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context) => CustomImageViewer(mediaSource: MediaSourceType.network, imageUrl: mediaData.url)));
        }, navigatorDelayTime);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: mediaComponentMargin),
        constraints: BoxConstraints(
          maxHeight: min(mediaData.mediaSize!.height, getScreenHeight() * 0.75),
          maxWidth: min(mediaData.mediaSize!.width, getScreenWidth())
        ),
        child: Image.network(mediaData.url)
      ),
    );
  }else if(mediaData.mediaType == MediaType.video){
    return Container(
      margin: EdgeInsets.only(bottom: mediaComponentMargin),
      constraints: BoxConstraints(
        maxHeight: min(mediaData.mediaSize!.height, getScreenHeight() * 0.75),
        maxWidth: min(mediaData.mediaSize!.width, getScreenWidth())
      ),
      child: CustomVideoPlayer(
        key: UniqueKey(),
        playerController: mediaData.playerController!,
        skipDuration: 10000, //how many milliseconds you want to skip
        rewindDuration: 10000, //how many milliseconds you want to rewind
        videoSourceType: VideoSourceType.network, //the source of the video: assets, file, network,
        durationEndDisplay: DurationEndDisplay.totalDuration, //whether to display in total duration or remaining duration
        displayMenu: false, //whether to display menu
        thumbColor: Colors.red, //color of the slider's thumb
        activeTrackColor: Colors.pink, //color of active tracks
        inactiveTrackColor: Colors.green, //color of inactive tracks
        overlayBackgroundColor: Colors.grey.withOpacity(0.5), //color of the overlay's background
        pressablesBackgroundColor: Colors.teal, //background color of the pressable icons such as play, pause, replay, and menu
        overlayDisplayDuration: 2500, //how long to display the overlay before it disappears, in ms,
        defaultAlignment: Alignment.centerLeft
      )
    );
  }else if(mediaData.mediaType == MediaType.websiteCard){
    return Container(
      margin: EdgeInsets.only(bottom: mediaComponentMargin),
      child: CustomWebsiteCardComponent(
        websiteCardData: mediaData.websiteCardData!, websiteCardState: WebsiteCardState.uploaded
      ),
    );
  }
  return Container();
}

Widget mediaDataMessageComponentWidget(MediaDatasClass mediaData, BuildContext context){
  if(mediaData.mediaType == MediaType.image){
    return InkWell(
      onTap: (){
        runDelay((){ 
          Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context) => CustomImageViewer(mediaSource: MediaSourceType.network, imageUrl: mediaData.url)));
        }, navigatorDelayTime);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: mediaComponentMargin),
        constraints: BoxConstraints(
          maxHeight: min(mediaData.mediaSize!.height, getScreenHeight() * 0.75),
          maxWidth: min(mediaData.mediaSize!.width, getScreenWidth() * 0.7)
        ),
        child: Image.network(mediaData.url)
      ),
    );
  }else if(mediaData.mediaType == MediaType.video){
    return Container(
      margin: EdgeInsets.only(bottom: mediaComponentMargin),
      constraints: BoxConstraints(
        maxHeight: min(mediaData.mediaSize!.height, getScreenHeight() * 0.75),
        maxWidth: min(mediaData.mediaSize!.width, getScreenWidth() * 0.7)
      ),
      child: CustomVideoPlayer(
        key: UniqueKey(),
        playerController: mediaData.playerController!,
        skipDuration: 10000, //how many milliseconds you want to skip
        rewindDuration: 10000, //how many milliseconds you want to rewind
        videoSourceType: VideoSourceType.network, //the source of the video: assets, file, network,
        durationEndDisplay: DurationEndDisplay.totalDuration, //whether to display in total duration or remaining duration
        displayMenu: false, //whether to display menu
        thumbColor: Colors.red, //color of the slider's thumb
        activeTrackColor: Colors.pink, //color of active tracks
        inactiveTrackColor: Colors.green, //color of inactive tracks
        overlayBackgroundColor: Colors.grey.withOpacity(0.5), //color of the overlay's background
        pressablesBackgroundColor: Colors.teal, //background color of the pressable icons such as play, pause, replay, and menu
        overlayDisplayDuration: 2500, //how long to display the overlay before it disappears, in ms,
        defaultAlignment: Alignment.centerLeft
      )
    );
  }else if(mediaData.mediaType == MediaType.websiteCard){
    return Container(
      margin: EdgeInsets.only(bottom: mediaComponentMargin),
      child: CustomWebsiteCardComponent(
        websiteCardData: mediaData.websiteCardData!, websiteCardState: WebsiteCardState.uploaded
      ),
    );
  }
  return Container();
}

Widget mediaDataDraftPostComponentWidget(MediaDatasClass mediaData, Size? scaledDimension){
  if(mediaData.mediaType == MediaType.image){
    return Container(
      constraints: BoxConstraints(
        maxHeight: min(scaledDimension!.height, getScreenHeight() * 0.75),
        maxWidth: min(scaledDimension.width, getScreenWidth())
      ),
      child: Image.file(File(mediaData.url))
    );
  }else if(mediaData.mediaType == MediaType.video){
    return Container(
      constraints: BoxConstraints(
        maxHeight: min(scaledDimension!.height, getScreenHeight() * 0.75),
        maxWidth: min(scaledDimension.width, getScreenWidth())
      ),
      child: CustomVideoPlayer(
        key: UniqueKey(),
        playerController: mediaData.playerController!,
        skipDuration: 10000, //how many milliseconds you want to skip
        rewindDuration: 10000, //how many milliseconds you want to rewind
        videoSourceType: VideoSourceType.network, //the source of the video: assets, file, network,
        durationEndDisplay: DurationEndDisplay.totalDuration, //whether to display in total duration or remaining duration
        displayMenu: false, //whether to display menu
        thumbColor: Colors.red, //color of the slider's thumb
        activeTrackColor: Colors.pink, //color of active tracks
        inactiveTrackColor: Colors.green, //color of inactive tracks
        overlayBackgroundColor: Colors.grey.withOpacity(0.5), //color of the overlay's background
        pressablesBackgroundColor: Colors.teal, //background color of the pressable icons such as play, pause, replay, and menu
        overlayDisplayDuration: 2500, //how long to display the overlay before it disappears, in ms,
        defaultAlignment: Alignment.center
      )
    );
  }else if(mediaData.mediaType == MediaType.websiteCard){
    return CustomWebsiteCardComponent(
      websiteCardData: mediaData.websiteCardData!, websiteCardState: WebsiteCardState.draft
    );
  }
  return Container();
}

Widget mediaDataDraftMessageComponentWidget(MediaDatasClass mediaData, Size? scaledDimension){
  if(mediaData.mediaType == MediaType.image){
    return Container(
      constraints: BoxConstraints(
        maxHeight: min(scaledDimension!.height, getScreenHeight() * 0.35),
        maxWidth: min(scaledDimension.width, getScreenWidth())
      ),
      child: Image.file(File(mediaData.url))
    );
  }else if(mediaData.mediaType == MediaType.video){
    return Container(
      constraints: BoxConstraints(
        maxHeight: min(scaledDimension!.height, getScreenHeight() * 0.35),
        maxWidth: min(scaledDimension.width, getScreenWidth())
      ),
      child: CustomVideoPlayer(
        key: UniqueKey(),
        playerController: mediaData.playerController!,
        skipDuration: 10000, //how many milliseconds you want to skip
        rewindDuration: 10000, //how many milliseconds you want to rewind
        videoSourceType: VideoSourceType.network, //the source of the video: assets, file, network,
        durationEndDisplay: DurationEndDisplay.totalDuration, //whether to display in total duration or remaining duration
        displayMenu: false, //whether to display menu
        thumbColor: Colors.red, //color of the slider's thumb
        activeTrackColor: Colors.pink, //color of active tracks
        inactiveTrackColor: Colors.green, //color of inactive tracks
        overlayBackgroundColor: Colors.grey.withOpacity(0.5), //color of the overlay's background
        pressablesBackgroundColor: Colors.teal, //background color of the pressable icons such as play, pause, replay, and menu
        overlayDisplayDuration: 2500, //how long to display the overlay before it disappears, in ms,
        defaultAlignment: Alignment.center
      )
    );
  }else if(mediaData.mediaType == MediaType.websiteCard){
    return CustomWebsiteCardComponent(
      websiteCardData: mediaData.websiteCardData!, websiteCardState: WebsiteCardState.draft
    );
  }
  return Container();
}

