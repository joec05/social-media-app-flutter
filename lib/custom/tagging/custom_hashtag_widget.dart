import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

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
        color: Theme.of(context).cardColor,
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
        color: Theme.of(context).cardColor,
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