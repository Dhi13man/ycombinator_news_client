/// Exports appropriate [initialiseDb()] based on Operating System.
export 'unsupported.dart'
    if (dart.library.html) 'webDatabase.dart' // For Web
    if (dart.library.io) 'mobileDatabase.dart'; // For Mobile
