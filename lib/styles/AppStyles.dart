import 'dart:io';
import 'package:flutter/material.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/class/MediaDataClass.dart';
import 'package:social_media_app/custom/CustomImageViewer.dart';
import 'package:video_player/video_player.dart';
import '../class/WebsiteCardClass.dart';
import '../custom/CustomWebsiteCardWidget.dart';

double defaultTextFontSize = 16;

double defaultLoginAlternativeTextFontSize = 12;

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

double regularTextFieldContentVerticalPadding = getScreenHeight() * 0.01;

double bioTextFieldContentVerticalPadding = getScreenHeight() * 0.01;

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

InputDecoration generateProfileTextFieldDecoration(content){
  OutlineInputBorder textFieldBorder = const OutlineInputBorder(
    borderSide: BorderSide(width: 2, color: Colors.white),
  );

  OutlineInputBorder focusedTextFieldBorder = const OutlineInputBorder(
    borderSide: BorderSide(width: 2, color: Colors.brown),
  );
  return InputDecoration(
    counterText: "",
    contentPadding: EdgeInsets.symmetric(vertical: regularTextFieldContentVerticalPadding, horizontal: regularTextFieldContentHorizontalPadding),
    focusedBorder: focusedTextFieldBorder,
    enabledBorder: textFieldBorder,
    disabledBorder: textFieldBorder,
    hintText: 'Enter $content'
  );
}

InputDecoration generateSearchTextFieldDecoration(content){
  OutlineInputBorder textFieldBorder = const OutlineInputBorder(
    borderSide: BorderSide(width: 1, color: Colors.white),
  );

  OutlineInputBorder focusedTextFieldBorder = const OutlineInputBorder(
    borderSide: BorderSide(width: 1, color: Colors.brown),
  );
  return InputDecoration(
    counterText: "",
    contentPadding: EdgeInsets.symmetric(vertical: regularTextFieldContentVerticalPadding, horizontal: regularTextFieldContentHorizontalPadding),
    focusedBorder: focusedTextFieldBorder,
    enabledBorder: textFieldBorder,
    disabledBorder: textFieldBorder,
    hintText: 'Enter $content'
  );
}

InputDecoration generateBioTextFieldDecoration(){
  OutlineInputBorder textFieldBorder = const OutlineInputBorder(
    borderSide: BorderSide(width: 2, color: Colors.white),
  );

  OutlineInputBorder focusedTextFieldBorder = const OutlineInputBorder(
    borderSide: BorderSide(width: 2, color: Colors.brown),
  );
  return InputDecoration(
    counterText: "",
    contentPadding: EdgeInsets.symmetric(vertical: bioTextFieldContentVerticalPadding, horizontal: regularTextFieldContentHorizontalPadding),
    focusedBorder: focusedTextFieldBorder,
    enabledBorder: textFieldBorder,
    disabledBorder: textFieldBorder,
    hintText: 'Say anything about yourself'
  );
}

Widget loadingSignWidget(){
  return Container(
    width: getScreenWidth(), height: getScreenHeight(),
    color: Colors.white.withOpacity(0.5),
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


InputDecoration generatePostTextFieldDecoration(content){
  OutlineInputBorder textFieldBorder = const OutlineInputBorder(
    borderSide: BorderSide(width: 2, color: Colors.white),
  );

  OutlineInputBorder focusedTextFieldBorder = const OutlineInputBorder(
    borderSide: BorderSide(width: 2, color: Colors.brown),
  );
  return InputDecoration(
    counterText: "",
    contentPadding: EdgeInsets.symmetric(vertical: regularTextFieldContentVerticalPadding, horizontal: regularTextFieldContentHorizontalPadding),
    focusedBorder: focusedTextFieldBorder,
    enabledBorder: textFieldBorder,
    disabledBorder: textFieldBorder,
    hintText: 'Enter $content'
  );
}

double writePostIconSize = 35;

Widget loadingPageWidget(){
  return Center(
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding, vertical: defaultVerticalPadding),
      child: const CircularProgressIndicator()
    )
  );
}

double defaultAppBarTitleSpacing = getScreenWidth()* 0.02;

double verifiedIconProfileWidgetSize = 16;

double lockIconProfileWidgetSize = 16;

double muteIconProfileWidgetSize = 16;

double moreIconProfileWidgetSize = 20;

double iconsBesideNameProfileMargin = getScreenWidth() * 0.0125;

double mediaComponentMargin = 0.005 * getScreenHeight();

Widget mediaDataPostComponentWidget(MediaDatasClass mediaData, BuildContext context){
  if(mediaData.mediaType == MediaType.image){
    return InkWell(
      onTap: (){
        Future.delayed(Duration(milliseconds: navigatorDelayTime), () { 
          Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context) => CustomImageViewer(mediaSource: MediaSourceType.network, imageUrl: mediaData.url)));
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: mediaComponentMargin),
        constraints: const BoxConstraints(
          maxHeight: 200,
          maxWidth: double.infinity
        ),
        child: Image.network(mediaData.url)
      ),
    );
  }else if(mediaData.mediaType == MediaType.video){
    return Container(
      width: mediaData.mediaSize!.width,
      height: mediaData.mediaSize!.height,
      margin: EdgeInsets.symmetric(vertical: mediaComponentMargin),
      child: VideoPlayer(mediaData.playerController!)
    );
  }else if(mediaData.mediaType == MediaType.websiteCard){
    return Container(
      margin: EdgeInsets.symmetric(vertical: mediaComponentMargin),
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
        Future.delayed(Duration(milliseconds: navigatorDelayTime), () { 
          Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context) => CustomImageViewer(mediaSource: MediaSourceType.network, imageUrl: mediaData.url)));
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: mediaComponentMargin),
        constraints: const BoxConstraints(
          maxHeight: 200,
          maxWidth: 200
        ),
        child: Image.network(mediaData.url)
      ),
    );
  }else if(mediaData.mediaType == MediaType.video){
    return Container(
      width: mediaData.mediaSize!.width,
      height: mediaData.mediaSize!.height,
      margin: EdgeInsets.symmetric(vertical: mediaComponentMargin),
      child: VideoPlayer(mediaData.playerController!)
    );
  }else if(mediaData.mediaType == MediaType.websiteCard){
    return Container(
      margin: EdgeInsets.symmetric(vertical: mediaComponentMargin),
      child: CustomWebsiteCardComponent(
        websiteCardData: mediaData.websiteCardData!, websiteCardState: WebsiteCardState.uploaded
      ),
    );
  }
  return Container();
}

Widget mediaDataDraftPostComponentWidget(MediaDatasClass mediaData){
  if(mediaData.mediaType == MediaType.image){
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 200,
        maxWidth: double.infinity
      ),
      child: Image.file(File(mediaData.url))
    );
  }else if(mediaData.mediaType == MediaType.video){
    return SizedBox(
      width: mediaData.mediaSize!.width,
      height: mediaData.mediaSize!.height,
      child: VideoPlayer(mediaData.playerController!)
    );
  }else if(mediaData.mediaType == MediaType.websiteCard){
    return CustomWebsiteCardComponent(
      websiteCardData: mediaData.websiteCardData!, websiteCardState: WebsiteCardState.draft
    );
  }
  return Container();
}

Widget mediaDataDraftMessageComponentWidget(MediaDatasClass mediaData){
  if(mediaData.mediaType == MediaType.image){
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 200,
        maxWidth: double.infinity
      ),
      child: Image.file(File(mediaData.url))
    );
  }else if(mediaData.mediaType == MediaType.video){
    return SizedBox(
      width: mediaData.mediaSize!.width,
      height: mediaData.mediaSize!.height,
      child: VideoPlayer(mediaData.playerController!)
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
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => onTap(),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: getScreenHeight() * 0.008, horizontal: getScreenWidth() * 0.03),
        child: child,
      )
    )
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