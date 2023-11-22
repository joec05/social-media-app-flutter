import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';
import '../Searched.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import '../class/HashtagClass.dart';
import '../extenstions/StringEllipsis.dart';

var dio = Dio();

class CustomHashtagDataWidget extends StatefulWidget{
  final HashtagClass hashtagData;
  
  const CustomHashtagDataWidget({super.key, required this.hashtagData});

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
                    Text(StringEllipsis.convertToEllipsis('#${hashtagData.hashtag}'), style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold),),
                    Text('${displayShortenedCount(hashtagData.hashtagCount)} posts', style: const TextStyle(fontSize: 14),)
                  ]
                ),
              ],
            )
          )
        )
      )
    );
  }
}