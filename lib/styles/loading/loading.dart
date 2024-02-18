import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

Widget loadingSignWidget(){
  return Container(
    width: getScreenWidth(), height: getScreenHeight(),
    color: Colors.transparent,
    child: const Center(
      child: CircularProgressIndicator()
    )
  );
}

Widget loadingPageWidget(){
  return Container(
    color: Colors.transparent,
    child: Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding, vertical: defaultVerticalPadding),
        child: const CircularProgressIndicator()
      )
    ),
  );
}
