import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/global_files.dart';

class HandlerControllerClass {

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
        content: snackbarContentTemplate(FontAwesomeIcons.x, text)
      )
    );
  }

  void displayDialog(
    BuildContext context, 
    String title,
    String description,
    List<DialogAction> dialogActions
  ){
    showDialog(
      context: context,
      builder: (context){
        return AlertDialog(
          title: Text(title),
          backgroundColor: Colors.blueGrey,
          shape: shape,
          content: Container(
            padding: padding,
            margin: margin,
            child: dialogContentTemplate(description, dialogActions)
          ),
        );
      }
    );
  }
}

final handler = HandlerControllerClass();