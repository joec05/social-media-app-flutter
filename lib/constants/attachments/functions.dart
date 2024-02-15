import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';
import 'package:html/dom.dart' as html;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

/// Returns the scaled size based on a media's size 
Size getSizeScale(double width, double height){
  double targetWidth = getScreenWidth();
  double targetHeight = getScreenHeight();
  
  double scaleWidth = targetWidth / width;
  double scaleHeight = targetHeight / height;

  double scale = scaleWidth < scaleHeight ? scaleWidth : scaleHeight;

  double resizedWidth = width * scale;
  double resizedHeight = height * scale;

  return Size(resizedWidth, resizedHeight);
}

/// Returns a WebsiteCardClass, which is a non-persistent class model used to display website card widgets
/// The function will parse the given url and query the title and image in the website's HTML code
/// Otherwise returns a snackbar error if the operation failed to finish
Future<WebsiteCardClass> fetchLinkPreview(BuildContext context, String url) async {
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
  } catch (_) {
    if(context.mounted) {
      handler.displaySnackbar(
        context, 
        SnackbarType.error, 
        tErr.websiteCard
      );
    }
  }
  return WebsiteCardClass(url, title, imageUrl, domain);
}

