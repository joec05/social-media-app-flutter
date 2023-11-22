class UserDataClass{
  final String userID;
  String name;
  String username;
  String profilePicLink;
  final String dateJoined;
  String birthDate;
  String bio;
  bool mutedByCurrentID;
  bool blockedByCurrentID;
  bool blocksCurrentID;
  bool private;
  bool requestedByCurrentID;
  bool requestsToCurrentID;
  bool verified;
  bool suspended;
  bool deleted;

  UserDataClass(
    this.userID, this.name, this.username, this.profilePicLink, this.dateJoined, this.birthDate, this.bio,
    this.mutedByCurrentID, this.blockedByCurrentID, this.blocksCurrentID, this.private, this.requestedByCurrentID,
    this.requestsToCurrentID, this.verified, this.suspended, this.deleted
  );

  factory UserDataClass.fromMap(Map map){
    return UserDataClass(
      map['user_id'],
      map['name'],
      map['username'], 
      map['profile_picture_link'], 
      map['date_joined'], 
      map['birth_date'], 
      map['bio'], 
      map['muted_by_current_id'],
      map['blocked_by_current_id'],
      map['blocks_current_id'],
      map['private'],
      map['requested_by_current_id'],
      map['requests_to_current_id'],
      map['verified'],
      map['suspended'],
      map['deleted']
    );
  }

  Map<String, dynamic> toMap(){
    return {
      'user_id': userID,
      'name': name,
      'username': username,
      'profile_picture_link': profilePicLink,
      'date_joined': dateJoined,
      'birth_date': birthDate,
      'bio': bio,
      'muted_by_current_id': mutedByCurrentID,
      'blocked_by_current_id': blockedByCurrentID,
      'blocks_current_id': blocksCurrentID,
      'private': private,
      'requested_by_current_id': requestedByCurrentID,
      'requests_to_current_id': requestsToCurrentID,
      'verified': verified,
      'suspended': suspended,
      'deleted': deleted
    };
  }

  bool isNotEqual(UserDataClass userDataClass){
    return
      userID != userDataClass.userID || name != userDataClass.name || username != userDataClass.username ||
      profilePicLink != userDataClass.profilePicLink || dateJoined != userDataClass.dateJoined ||
      birthDate != userDataClass.birthDate || bio != userDataClass.bio || mutedByCurrentID != userDataClass.mutedByCurrentID ||
      blockedByCurrentID != userDataClass.blockedByCurrentID || blocksCurrentID != userDataClass.blocksCurrentID ||
      private != userDataClass.private || requestedByCurrentID != userDataClass.requestedByCurrentID ||
      requestsToCurrentID != userDataClass.requestsToCurrentID || verified != userDataClass.verified ||
      suspended != userDataClass.suspended || deleted != userDataClass.deleted
    ;
  }
}