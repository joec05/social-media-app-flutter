import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

Widget snackbarContentTemplate(IconData? iconData, String text) => Row(
  mainAxisAlignment: MainAxisAlignment.start,
  children: [
    iconData != null ? Icon(iconData, size: 17) : Container(),
    SizedBox(
      width: iconData != null ? getScreenWidth() * 0.035 : 0
    ),
    Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, textAlign: TextAlign.left, style: const TextStyle(
            fontWeight: FontWeight.bold
          ))
        ],
      ),
    )
  ],
);