import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

double getScreenHeight(){
  return PlatformDispatcher.instance.views.first.physicalSize.height / PlatformDispatcher.instance.views.first.devicePixelRatio;
}

double getScreenWidth(){
  return PlatformDispatcher.instance.views.first.physicalSize.width / PlatformDispatcher.instance.views.first.devicePixelRatio;
}

double defaultTextFontSize = 16;

double defaultHorizontalPadding = getScreenWidth() * 0.045;

double defaultTextFieldVerticalMargin = getScreenHeight() * 0.015;

double defaultPickedImageVerticalMargin = getScreenHeight() * 0.015;

Size defaultTextFieldButtonSize = Size(
  getScreenWidth() - regularTextFieldContentHorizontalPadding * 2,
  getScreenHeight() * 0.07
);

double defaultVerticalPadding = getScreenHeight() * 0.02;

TextStyle textFieldPageTitleTextStyle = const TextStyle(fontSize: 22.5, fontWeight: FontWeight.bold);

double regularTextFieldContentHorizontalPadding = getScreenWidth() * 0.02;

Widget textFieldWithDescription(Widget textField, String description, String toolTipMessage){
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(description, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold)),
          SizedBox(
            width: getScreenWidth() * 0.0075,
          ),
          toolTipMessage.isNotEmpty ? 
            Tooltip(
              message: toolTipMessage,
              child: const Icon(Icons.info, size: 17.5)
            )
          : Container(),
        ]
      ),
      SizedBox(
        height: getScreenHeight() * 0.005
      ),
      textField,
    ]
  );
}

double titleToContentMargin = getScreenHeight() * 0.0225;

double textFieldToButtonMargin = getScreenHeight() * 0.03;

InputDecoration generatePostTextFieldDecoration(content, prefixIcon){
  return InputDecoration(
    counterText: "",
    contentPadding: EdgeInsets.symmetric(vertical: getScreenHeight() * 0.0225, horizontal: getScreenWidth() * 0.02),
    fillColor: const Color.fromARGB(255, 70, 64, 64),
    filled: true,
    border: InputBorder.none,
    hintText: 'Enter $content',
    prefixIcon: Icon(prefixIcon, size: 15),
    prefixIconColor: Colors.blueGrey,
  );
}

InputDecoration generateBioTextFieldDecoration(content, prefixIcon){
  return InputDecoration(
    counterText: "",
    contentPadding: EdgeInsets.symmetric(vertical: getScreenHeight() * 0.0225, horizontal: getScreenWidth() * 0.02),
    fillColor: const Color.fromARGB(255, 70, 64, 64),
    filled: true,
    border: InputBorder.none,
    hintText: 'Talk about yourself',
    prefixIcon: Icon(prefixIcon, size: 20),
    prefixIconColor: Colors.blueGrey,
  );
}

InputDecoration generateProfileTextFieldDecoration(content, prefixIcon){
  return InputDecoration(
    counterText: "",
    contentPadding: EdgeInsets.symmetric(vertical: getScreenHeight() * 0.0225, horizontal: getScreenWidth() * 0.02),
    fillColor: const Color.fromARGB(255, 70, 64, 64),
    filled: true,
    border: InputBorder.none,
    hintText: 'Enter $content',
    prefixIcon: Icon(prefixIcon, size: 20),
    prefixIconColor: Colors.blueGrey,
  );
}

InputDecoration generateSearchTextFieldDecoration(content, suffixIcon, onPressedIcon){
  return InputDecoration(
    counterText: "",
    contentPadding: EdgeInsets.symmetric(vertical: getScreenHeight() * 0.0225, horizontal: getScreenWidth() * 0.02),
    fillColor: const Color.fromARGB(255, 70, 64, 64),
    filled: true,
    border: InputBorder.none,
    hintText: 'Enter $content',
    suffixIcon: Container(
      color: Colors.grey, 
      child: TextButton(
        onPressed: onPressedIcon,
        child: Icon(suffixIcon, size: 25)
      ),
    ),
    suffixIconColor: Colors.blueGrey,
  );
}

InputDecoration generateMessageTextFieldDecoration(content){
  return InputDecoration(
    counterText: "",
    contentPadding: EdgeInsets.only(top: getScreenHeight() * 0.0225, bottom: getScreenHeight() * 0.0225, left: getScreenWidth() * 0.02),
    fillColor: const Color.fromARGB(255, 70, 64, 64),
    filled: true,
    border: InputBorder.none,
    hintText: 'Enter $content',
    suffixIcon: Container(
      width: 1
    )
  );
}

Widget loadingSignWidget(){
  return Container(
    width: getScreenWidth(), height: getScreenHeight(),
    color: Colors.transparent,
    child: const Center(
      child: CircularProgressIndicator()
    )
  );
}

Widget containerMargin(Widget child, EdgeInsets margin){
  return Container(
    margin: margin, child: child
  );
}

double writePostIconSize = 35;

Widget loadingPageWidget(){
  return Container(
    color: Colors.transparent,
    child: Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding, vertical: defaultVerticalPadding),
        child: const CircularProgressIndicator()
      )
    ),
  );
}

double defaultAppBarTitleSpacing = getScreenWidth()* 0.02;

double verifiedIconProfileWidgetSize = 13;

double lockIconProfileWidgetSize = 13;

double muteIconProfileWidgetSize = 13;

double moreIconProfileWidgetSize = 20;

double iconsBesideNameProfileMargin = getScreenWidth() * 0.0075;

double mediaComponentMargin = 0.01 * getScreenHeight();

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

BoxDecoration defaultFrontPageDecoration = const BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color.fromARGB(255, 111, 126, 211), Color.fromARGB(255, 18, 151, 138)
    ],
    stops: [
      0.35, 0.75
    ],
  ),
);

BoxDecoration defaultAppBarDecoration = const BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color.fromARGB(255, 111, 126, 211), Color.fromARGB(255, 18, 151, 138)
    ],
    stops: [
      0.35, 0.75
    ],
  ),
);

Widget generatePostActionWidget(Function onTap, Widget child){
  return Container(
    margin: EdgeInsets.only(right: getScreenWidth() * 0.05),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: getScreenHeight() * 0.01),
          child: child,
        )
      )
    ),
  );
}

Widget generatePostMoreOptionsWidget(Function onTap, Widget child){
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => onTap(),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: getScreenWidth() * 0.0005, horizontal: getScreenWidth() * 0.015),
        child: child,
      )
    )
  );
}

Widget defaultLeadingWidget(BuildContext context){
  return InkWell(
    splashFactory: InkRipple.splashFactory,
    onTap: () => context.mounted ? runDelay(() => Navigator.pop(context), 60) : (){},
    child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white)
  );
}

Widget shimmerSkeletonWidget(Widget child){
  return Shimmer.fromColors(
    baseColor: Colors.grey.withOpacity(0.5),
    highlightColor: const Color.fromARGB(179, 167, 155, 155),
    child: child
  );
}

bool shouldCallSkeleton(LoadingState loadingState) => loadingState == LoadingState.loading;