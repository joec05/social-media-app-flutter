import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/global_files.dart';

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
                Flexible(
                  child: Row(
                    children: [
                      Container(
                        width: getScreenWidth() * 0.1, height: getScreenWidth() * 0.1,
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
                      SizedBox(
                        width: getScreenWidth() * 0.02
                      ),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          StringEllipsis.convertToEllipsis(userData.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: defaultTextFontSize * 0.9, fontWeight: FontWeight.bold)
                                        )
                                      ),
                                      userData.verified && !userData.suspended && !userData.deleted ?
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: iconsBesideNameProfileMargin
                                            ),
                                            Icon(Icons.verified_rounded, size: verifiedIconProfileWidgetSize),
                                          ]
                                        )
                                      : Container(),
                                      userData.private && !userData.suspended && !userData.deleted ?
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: iconsBesideNameProfileMargin
                                            ),
                                            Icon(FontAwesomeIcons.lock, size: lockIconProfileWidgetSize),
                                          ],
                                        )
                                      : Container(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('@${userData.username}', style: TextStyle(fontSize: defaultTextFontSize * 0.8, color: Colors.lightBlue)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            ),
          ]
        )
      )
    );
  }
}