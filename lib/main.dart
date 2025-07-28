import 'package:flutter/material.dart';
import 'screen/dashboard.dart';
import 'screen/otp_verification_screen.dart';
import 'screen/home_screen.dart';
import 'screen/qr_system_screen.dart';
import 'screen/qr_generate_screen.dart';
import 'screen/qr_scan_screen.dart';
import 'screen/profile.dart';
import 'screen/setting.dart';
import 'screen/account.dart';
import 'screen/contact_profile_screen.dart';
import 'screen/change_number.dart';
import 'screen/wallpaper.dart';
import 'screen/help.dart';
void main() {
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
      initialRoute: '/',
      routes: {
        '/': (_) => Dashboard(),
        '/otp-verification': (context) {
          final phoneNumber =
              ModalRoute.of(context)!.settings.arguments as String;
          return OTPVerificationScreen(phoneNumber: phoneNumber);
        },
        '/home': (_) => HomeScreen(),
        '/profile': (_) => ProfileScreen(),
        '/qr-system': (_) => QRSystemScreen(),
        '/qr-generate': (_) => QRGenerateScreen(),
        '/qr-scan': (_) => QRScanScreen(),
        '/settings': (_) => SettingsScreen(),
        '/account': (_) => AccountScreen(),
        '/change-number': (_) => ChangeNumberScreen(),
        '/wallpaper': (_) => ChatWallpaperScreen(),
        '/help': (_) => HelpScreen(),
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
