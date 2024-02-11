class HashtagClass{
  final String hashtag;
  final int hashtagCount;

  HashtagClass(
    this.hashtag, this.hashtagCount
  );

  factory HashtagClass.getFakeData(){
    return HashtagClass('', 0);
  }
}