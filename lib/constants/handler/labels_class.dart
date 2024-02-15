/// Stores fixed text to display in an error snackbar, depending on the type of the error
class ErrorLabels {
  final title = 'Error!!!';

  final unknown = 'An unknown error occured';

  final api = 'An API error occured';

  final firebase = 'A Firebase error occured';

  final appwrite = 'An AppWrite error occured';

  final sqflite = 'A database error occured';

  final websiteCard = 'An error occured while generating the website card';
}

final tErr = ErrorLabels();