import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

TextStyle textFieldPageTitleTextStyle = const TextStyle(fontSize: 22.5, fontWeight: FontWeight.bold);

double regularTextFieldContentHorizontalPadding = getScreenWidth() * 0.02;

Widget textFieldWithDescription(Widget textField, String description, String toolTipMessage){
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(description, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
          SizedBox(
            width: getScreenWidth() * 0.0075,
          ),
          toolTipMessage.isNotEmpty ? 
            Tooltip(
              message: toolTipMessage,
              child: const Icon(Icons.info, size: 17.5)
            )
          : Container(),
        ]
      ),
      SizedBox(
        height: getScreenHeight() * 0.005
      ),
      textField,
    ]
  );
}

double titleToContentMargin = getScreenHeight() * 0.0225;

double textFieldToButtonMargin = getScreenHeight() * 0.03;

InputDecoration generatePostTextFieldDecoration(content, prefixIcon){
  return InputDecoration(
    counterText: "",
    contentPadding: EdgeInsets.symmetric(vertical: getScreenHeight() * 0.0225, horizontal: getScreenWidth() * 0.02),
    filled: true,
    border: InputBorder.none,
    hintText: 'Enter $content',
    prefixIcon: Icon(prefixIcon, size: 15),
    prefixIconColor: Colors.blueGrey,
  );
}

InputDecoration generateBioTextFieldDecoration(content, prefixIcon){
  return InputDecoration(
    counterText: "",
    contentPadding: EdgeInsets.symmetric(vertical: getScreenHeight() * 0.0225, horizontal: getScreenWidth() * 0.02),
    filled: true,
    border: InputBorder.none,
    hintText: 'Talk about yourself',
    prefixIcon: Icon(prefixIcon, size: 20),
    prefixIconColor: Colors.blueGrey,
  );
}

InputDecoration generateProfileTextFieldDecoration(content, prefixIcon){
  return InputDecoration(
    counterText: "",
    contentPadding: EdgeInsets.symmetric(vertical: getScreenHeight() * 0.0225, horizontal: getScreenWidth() * 0.02),
    filled: true,
    border: InputBorder.none,
    hintText: 'Enter $content',
    prefixIcon: Icon(prefixIcon, size: 20),
    prefixIconColor: Colors.blueGrey,
  );
}

InputDecoration generateSearchTextFieldDecoration(content, suffixIcon, onPressedIcon){
  return InputDecoration(
    counterText: "",
    contentPadding: EdgeInsets.symmetric(vertical: getScreenHeight() * 0.0225, horizontal: getScreenWidth() * 0.02),
    filled: true,
    border: InputBorder.none,
    hintText: 'Enter $content',
    suffixIcon: TextButton(
      onPressed: onPressedIcon,
      child: Icon(suffixIcon, size: 25)
    ),
    suffixIconColor: Colors.blueGrey,
  );
}

InputDecoration generateMessageTextFieldDecoration(content){
  return InputDecoration(
    counterText: "",
    contentPadding: EdgeInsets.only(top: getScreenHeight() * 0.0225, bottom: getScreenHeight() * 0.0225, left: getScreenWidth() * 0.02),
    filled: true,
    border: InputBorder.none,
    hintText: 'Enter $content',
    suffixIcon: Container(
      width: 1
    )
  );
}

