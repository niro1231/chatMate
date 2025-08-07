import 'package:flutter/material.dart';
import 'screen/dashboard.dart';
import 'screen/otp_verification_screen.dart';
import 'screen/home_screen.dart';
import 'screen/qr_system_screen.dart';
import 'screen/qr_generate_screen.dart';
import 'screen/qr_scan_screen.dart';
import 'screen/profile.dart';
import 'screen/setting.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'screen/contact_profile_screen.dart';
import 'screen/change_number.dart';
import 'screen/wallpaper.dart';
import 'screen/help.dart';
import 'screen/plus.dart';
import 'screen/Accdele.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ChatQRApp());
}

class ChatQRApp extends StatelessWidget {
  const ChatQRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatQR',
      theme: ThemeData(primarySwatch: Colors.indigo),
      debugShowCheckedModeBanner: false,
      initialRoute: FirebaseAuth.instance.currentUser == null ? '/' : '/home',
      routes: {
        '/': (_) => Dashboard(),
        '/otp-verification': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return OTPVerificationScreen(
            email: args['email'],
          );
        },
        '/home': (_) => HomeScreen(),
        '/profile': (_) => ProfileScreen(),
        '/qr-system': (_) => QRSystemScreen(),
        '/qr-generate': (_) => QRGenerateScreen(),
        '/qr-scan': (_) => QRScanScreen(),
        '/settings': (_) => SettingsScreen(),
        
        '/change-number': (_) => ChangeNumberScreen(),
        '/wallpaper': (_) => ChatWallpaperScreen(),
        '/help': (_) => HelpScreen(),
        '/plus': (_) => ContactsScreen(),
        '/accdele': (_) => DeleteAccountScreen(),
        '/contact-profile': (context) {
          final contact =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ContactProfileScreen(contact: contact);
        },
      },
    );
  }
}
