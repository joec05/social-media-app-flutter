import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';
import '../class/WebsiteCardClass.dart';
import 'CustomWebPageViewer.dart';

class CustomWebsiteCardComponent extends StatefulWidget {
  final WebsiteCardClass websiteCardData;
  final WebsiteCardState websiteCardState;

  const CustomWebsiteCardComponent({Key? key, required this.websiteCardData, required this.websiteCardState}): super(key: key);
  

  @override
  WebsiteCardBuilderState createState() => WebsiteCardBuilderState();
}

class WebsiteCardBuilderState extends State<CustomWebsiteCardComponent>{
  late WebsiteCardClass websiteCardData;
  late WebsiteCardState websiteCardState;
  
  @override
  void initState(){
    super.initState();
    websiteCardData = widget.websiteCardData;
    websiteCardState = widget.websiteCardState;
  }

  @override
  void dispose(){
    super.dispose();
  }

  Future<void> _launchInBrowser(String url) async {
    runDelay(() => Navigator.push(
      context,
      SliderRightToLeftRoute(
        page: CustomWebPageViewer(url: url),
      ),
    ), navigatorDelayTime);
  }

  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(width: 2, color: Colors.blueGrey)),
      child: InkWell(
        onTap: websiteCardState == WebsiteCardState.uploaded ? (){_launchInBrowser(websiteCardData.websiteUrl);} : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              width: getScreenWidth() * 0.25,
              height: getScreenWidth() * 0.25,
              child: Image.network(websiteCardData.imageUrl)
            ),
            Container(
              width: 0.5 * getScreenWidth(),
              height: 0.25 * getScreenWidth(),
              padding: EdgeInsets.symmetric(horizontal: 0.015 * getScreenWidth(), vertical: 0.01 * getScreenWidth()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(websiteCardData.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: defaultTextFontSize, fontWeight: FontWeight.w600), textAlign: TextAlign.start),
                  Text(websiteCardData.domain, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: defaultTextFontSize * 0.9), textAlign: TextAlign.start) 
                ]
              )
            )
          ]
        )
      )
    );
  }
}

