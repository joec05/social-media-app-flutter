import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

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

Widget defaultLeadingWidget(BuildContext context){
  return InkWell(
    splashFactory: InkRipple.splashFactory,
    onTap: () => context.mounted ? runDelay(() => Navigator.pop(context), 60) : (){},
    child: const Icon(Icons.arrow_back_ios_new, size: 20)
  );
}