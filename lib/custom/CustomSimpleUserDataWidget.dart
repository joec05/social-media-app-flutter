import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import '../class/UserDataClass.dart';
import '../extenstions/StringEllipsis.dart';

var dio = Dio();

class CustomSimpleUserDataWidget extends StatefulWidget{
  final UserDataClass userData;

  const CustomSimpleUserDataWidget({super.key, required this.userData});

  @override
  State<CustomSimpleUserDataWidget> createState() =>_CustomSimpleUserDataWidgetState();
}

class _CustomSimpleUserDataWidgetState extends State<CustomSimpleUserDataWidget>{

  late UserDataClass userData;

  @override initState(){
    super.initState();
    userData = widget.userData;
  }

  @override void dispose(){
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    if(userData.blockedByCurrentID || userData.blocksCurrentID || userData.suspended || userData.deleted){
      return Container();
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: (){
                      },
                      child: Container(
                        width: getScreenWidth() * 0.125, height: getScreenWidth() * 0.125,
                        decoration: BoxDecoration(
                          border: Border.all(width: 2, color: Colors.white),
                          borderRadius: BorderRadius.circular(100),
                          image: DecorationImage(
                            image: NetworkImage(
                              userData.profilePicLink
                            ), fit: BoxFit.fill
                          )
                        ),
                      ),
                    ),
                    SizedBox(
                      width: getScreenWidth() * 0.03
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(StringEllipsis.convertToEllipsis(userData.name), style: TextStyle(fontSize: defaultTextFontSize, fontWeight: FontWeight.bold)),
                        SizedBox(
                          height: getScreenHeight() * 0.0025
                        ),
                        Text('@${userData.username}', style: TextStyle(fontSize: defaultTextFontSize, color: Colors.lightBlue))
                      ],
                    ),
                  ],
                ),
              ]
            ),
          ]
        )
      )
    );
  }
}