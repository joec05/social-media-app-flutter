class WebsiteCardClass{
  final String websiteUrl;
  final String title;
  final String imageUrl;
  final String domain;

  WebsiteCardClass(this.websiteUrl, this.title, this.imageUrl, this.domain);
}

enum WebsiteCardState{
  draft, uploaded
}