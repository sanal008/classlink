import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart';
import 'common/theme.dart';
import 'email_config.dart';

// Fallback FirebaseOptions constructed from your google-services.json
const _fallbackFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyAEKWqLB2_e-QpXa1JQcizyYRp06U82ouE',
  appId: '1:851615034738:android:68315565b380bf4df781eb',
  messagingSenderId: '851615034738',
  projectId: 'claink-3ac31',
  databaseURL: 'https://claink-3ac31-default-rtdb.firebaseio.com',
  storageBucket: 'claink-3ac31.firebasestorage.app',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

  try {
    // Try default initialization which uses native resources (google-services.json)
    await Firebase.initializeApp();
  } catch (e) {
    // If default init fails (missing resources or malformed values.xml),
    // fall back to manual initialization using explicit FirebaseOptions.
    await Firebase.initializeApp(options: _fallbackFirebaseOptions);
  }

  // Initialize email service configuration
  EmailConfig.initialize();

  runApp(const SmartClassroomApp());
}

class SmartClassroomApp extends StatelessWidget {
  const SmartClassroomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClassLink+',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const SplashScreen(),
    );
  }
}