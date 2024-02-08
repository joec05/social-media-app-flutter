import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/attachment/website_card_class.dart';
import 'package:social_media_app/constants/global_functions.dart';
import 'package:social_media_app/constants/global_variables.dart';
import 'package:social_media_app/custom/web/custom_web_page_viewer.dart';
import 'package:social_media_app/styles/app_styles.dart';
import 'package:social_media_app/transition/navigation.dart';

class CustomWebsiteCardComponent extends StatefulWidget {
  final WebsiteCardClass websiteCardData;
  final WebsiteCardState websiteCardState;

  const CustomWebsiteCardComponent({super.key, required this.websiteCardData, required this.websiteCardState});
  

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

