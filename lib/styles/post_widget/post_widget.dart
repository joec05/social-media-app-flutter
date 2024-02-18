import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

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
