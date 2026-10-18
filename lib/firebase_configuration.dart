import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.g.dart' as generated;

class FirebaseConfiguration {
  static bool get isConfigured =>
      generated.DefaultFirebaseOptions.currentPlatform.apiKey != 'configure-me';

  static FirebaseOptions get currentPlatform =>
      generated.DefaultFirebaseOptions.currentPlatform;
}
