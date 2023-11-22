class UserSocialClass{
  int followersCount;
  int followingCount;
  bool followedByCurrentID;
  bool followsCurrentID;

  UserSocialClass(
    this.followersCount, this.followingCount, this.followedByCurrentID, this.followsCurrentID
  );

  factory UserSocialClass.fromMap(Map map){
    return UserSocialClass(
      map['followers_count'],
      map['following_count'],
      map['followed_by_current_id'],
      map['follows_current_id']
    );
  }

  bool isNotEqual(UserSocialClass userSocialsClass){
    return
      followersCount != userSocialsClass.followersCount || followingCount != userSocialsClass.followingCount || 
      followedByCurrentID != userSocialsClass.followedByCurrentID || followsCurrentID != userSocialsClass.followsCurrentID
    ;
  }
}