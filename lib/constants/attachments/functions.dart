import 'dart:ui';
import 'package:social_media_app/global_files.dart';
import 'package:html/dom.dart' as html;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

Size getSizeScale(width, height){
  double targetWidth = getScreenWidth();
  double targetHeight = getScreenHeight();
  
  double scaleWidth = targetWidth / width;
  double scaleHeight = targetHeight / height;

  double scale = scaleWidth < scaleHeight ? scaleWidth : scaleHeight;

  double resizedWidth = width * scale;
  double resizedHeight = height * scale;

  return Size(resizedWidth, resizedHeight);
}

Future<WebsiteCardClass> fetchLinkPreview(String url) async {
  String title = '';
  String imageUrl = defaultWebsiteCardImageLink;
  String domain = '';

  Uri uri = Uri.parse(url);
  domain = uri.host.replaceFirst('www.', '');

  try {
    final response = await http.get(Uri.parse(url));
    final htmlContent = response.body;
    
    html.Document document = parser.parse(htmlContent);
    
    html.Element? titleMetaTag = document.querySelector('meta[property="og:title"]');
    html.Element? imageMetaTag = document.querySelector('meta[property="og:image"]');
    
    title = titleMetaTag?.attributes['content'] ?? '';
    imageUrl = imageMetaTag?.attributes['content'] ?? '';


  } on Exception catch (e) {
    
  }
  return WebsiteCardClass(url, title, imageUrl, domain);
}

