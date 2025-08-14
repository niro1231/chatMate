import 'package:chatme/database/UserRepository.dart';
import 'package:chatme/screen/name.dart';
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
import 'screen/change_email.dart';
import 'screen/wallpaper.dart';
import 'screen/help.dart';
import 'screen/plus.dart';
import 'screen/Accdele.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final repo = Repository();
  final loggedInEmail = await repo.getLoggedInEmail();
  runApp(ChatQRApp(initialRoute: loggedInEmail == null ? '/' : '/home'));
}

class ChatQRApp extends StatelessWidget {
  final String initialRoute;
  const ChatQRApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatQR',
      theme: ThemeData(primarySwatch: Colors.indigo),
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/': (_) => Dashboard(),
        '/otp-verification': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args == null || args is! Map<String, dynamic>){
            // handle missing or wrong arguments, e.g. show error screen or provide default values
            return OTPVerificationScreen(email: '');
          }
          return OTPVerificationScreen(
            email: (args as Map<String, dynamic>)['email'],
          );
        },
        '/home': (_) => HomeScreen(),
        '/name': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args == null || args is! Map<String, dynamic>){
            // handle missing or wrong arguments, e.g. show error screen or provide default values
            return NameScreen(email: '');
          }
          return NameScreen(
            email: (args as Map<String, dynamic>)['email'],
          );
        },
        '/profile': (_) => ProfileScreen(),
        '/qr-system': (_) => QRSystemScreen(),
        '/qr-generate': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args == null || args is! Map<String, dynamic> || !args.containsKey('name')) {
            // Return a screen with an error or default values if arguments are missing
            return QRGenerateScreen(email: '', name: 'Guest');
          }
          return QRGenerateScreen(
            email: (args as Map<String, dynamic>)['email'],
            name: (args as Map<String, dynamic>)['name'], // Pass the name
          );
        },
        '/qr-scan': (_) => QRScanScreen(),
        '/settings': (_) => SettingsScreen(),

        '/change-email': (_) => ChangeEmailScreen(),
        '/wallpaper': (_) => ChatWallpaperScreen(),
        '/help': (_) => HelpScreen(),
        '/plus': (_) => ContactsScreen(),
        '/accdele': (_) => DeleteAccountScreen(),
        '/contact-profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args == null || args is! Map<String, dynamic>) {
            // handle error or provide default empty map
            return ContactProfileScreen(contact: {});
          }
          return ContactProfileScreen(contact: args as Map<String, dynamic>);
        },
      },
    );
  }
}
