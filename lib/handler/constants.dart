import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

Duration duration = const Duration(seconds: 3);

SnackBarBehavior behavior = SnackBarBehavior.floating;

EdgeInsets padding = const EdgeInsets.all(15);

EdgeInsets margin = const EdgeInsets.all(10);

ShapeBorder shape = RoundedRectangleBorder(
  side: const BorderSide(
    color: Colors.grey,
    width: 1.5
  ),
  borderRadius: BorderRadius.circular(12.5)
);

Widget snackbarContentTemplate(IconData iconData, String text) => Row(
  mainAxisAlignment: MainAxisAlignment.start,
  children: [
    Icon(iconData, size: 20),
    SizedBox(
      width: getScreenWidth() * 0.025
    ),
    Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, textAlign: TextAlign.center, style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold
          ))
        ],
      ),
    )
  ],
);

Widget dialogContentTemplate(String description, List<DialogAction> dialogActions) => Column(
  mainAxisSize: MainAxisSize.min,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text(description),
    SizedBox(
      height: getScreenHeight() * 0.025
    ),
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for(int i = 0; i < 2; i++)
        CustomButton(
          width: getScreenWidth() * 0.35, 
          height: getScreenHeight() * 0.065, 
          buttonColor: dialogActions[i].danger ? Colors.redAccent : Colors.teal, 
          buttonText: dialogActions[i].text, 
          onTapped: dialogActions[i].onPressed, 
          setBorderRadius: true
        )
      ],
    )
  ],
);