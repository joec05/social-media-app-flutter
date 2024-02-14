import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/global_files.dart';

class HandlerController {
  Color getHandlerColor(SnackbarType type) {
    if(type == SnackbarType.error){
      return Colors.redAccent;
    }else if(type == SnackbarType.successful){
      return Colors.lightGreen;
    }else if(type == SnackbarType.regular){
      return Colors.teal;
    }else if(type == SnackbarType.warning){
      return Colors.yellow;
    }
    return Colors.red;
  }

  IconData? getIconData(SnackbarType type) {
    if(type == SnackbarType.error){
      return FontAwesomeIcons.x;
    }else if(type == SnackbarType.successful){
      return FontAwesomeIcons.check;
    }else if(type == SnackbarType.regular){
      return null;
    }else if(type == SnackbarType.warning){
      return FontAwesomeIcons.triangleExclamation;
    }
    return null;
  }

  void displaySnackbar(
    BuildContext context, 
    SnackbarType type,
    String text
  ){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: getHandlerColor(type),
        duration: duration,
        behavior: behavior,
        padding: padding,
        margin: margin,
        shape: shape,
        content: snackbarContentTemplate(getIconData(type), text)
      )
    );
  }
}

final handler = HandlerController();