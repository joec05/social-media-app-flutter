import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/tagging/hashtag_class.dart';
import 'package:social_media_app/constants/global_functions.dart';
import 'package:social_media_app/constants/global_variables.dart';
import 'package:social_media_app/extenstions/string_ellipsis.dart';
import 'package:social_media_app/screens/search/Searched.dart';
import 'package:social_media_app/styles/app_styles.dart';
import 'package:social_media_app/transition/navigation.dart';
var dio = Dio();

class CustomHashtagDataWidget extends StatefulWidget{
  final HashtagClass hashtagData;
  final bool skeletonMode;
  
  const CustomHashtagDataWidget({super.key, required this.hashtagData, required this.skeletonMode});

  @override
  State<CustomHashtagDataWidget> createState() =>_CustomHashtagDataWidgetState();
}

class _CustomHashtagDataWidgetState extends State<CustomHashtagDataWidget>{

  late HashtagClass hashtagData;

  @override initState(){
    super.initState();
    hashtagData = widget.hashtagData;
  }

  @override void dispose(){
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    if(!widget.skeletonMode){
      return Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
        color: Colors.transparent,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (){
              runDelay(() => Navigator.push(
                context,
                SliderRightToLeftRoute(
                  page: SearchedWidget(searchedText: '#${hashtagData.hashtag}')
                )
              ), navigatorDelayTime);
            },
            splashFactory: InkRipple.splashFactory,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(StringEllipsis.convertToEllipsis('#${hashtagData.hashtag}',), style: TextStyle(fontSize: defaultTextFontSize * 0.9, fontWeight: FontWeight.bold),),
                      SizedBox(height: getScreenHeight() * 0.005),
                      Text(hashtagData.hashtagCount == 1 ? '1 post' : '${displayShortenedCount(hashtagData.hashtagCount)} posts', style: TextStyle(fontSize: defaultTextFontSize * 0.8, color: Colors.lightBlue),)
                    ]
                  ),
                ],
              )
            )
          )
        )
      );
    }else{
      return Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
        color: Colors.transparent,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashFactory: InkRipple.splashFactory,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: SizedBox(
                      width: double.infinity,
                      height: getScreenHeight() * 0.0275
                    )
                  ),
                  SizedBox(height: getScreenHeight() * 0.005),
                  Card(
                    margin: EdgeInsets.zero,
                    child: SizedBox(
                      width: double.infinity,
                      height: getScreenHeight() * 0.025
                    )
                  ),
                ]
              )
            )
          )
        )
      );
    }
  }
}