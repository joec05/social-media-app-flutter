// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/styles/AppStyles.dart';

class CustomButton extends StatefulWidget {
  final double width;
  final double height;
  final Color buttonColor;
  final String buttonText;
  final VoidCallback? onTapped;
  final bool setBorderRadius;

  const CustomButton({super.key, 
    required this.width, required this.height, required this.buttonColor, required this.buttonText,
    required this.onTapped, required this.setBorderRadius
  });

  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override void dispose(){
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width, height: widget.height,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.onTapped == null ? Colors.white.withOpacity(0.5) : widget.buttonColor,
          borderRadius: widget.setBorderRadius ? const BorderRadius.all(Radius.circular(5)) : BorderRadius.zero
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashFactory: InkRipple.splashFactory,
            onTap: (){
              Future.delayed(Duration(milliseconds: navigatorDelayTime), (){}).then((value) => widget.onTapped!());
            },
            child: Center(
              child: Text(widget.buttonText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: defaultTextFontSize))
            )
          ),
        ),
      )
    );
  }

}