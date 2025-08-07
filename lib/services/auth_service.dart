import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendOTPEmail({required String email}) async {
    final otp = _generateOTP();
    final expiry = DateTime.now().add(const Duration(minutes: 5));

    // 1. Store OTP in Firestore
    await _firestore.collection('emailOtps').doc(email).set({
      'otp': otp,
      'expiresAt': expiry.toIso8601String(),
    });

    // 2. Send OTP using EmailJS
    await sendEmailJS(email: email, otp: otp);
  }

  Future<void> sendEmailJS({required String email, required String otp}) async {
    const serviceId = 'service_jypbjj4';      // 🔁 Replace
    const templateId = 'template_cnunvag';    // 🔁 Replace
    const userId = 'o_YB5emFA2VrFX-u1';            // 🔁 Replace

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost', // You can customize this
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'email': email,
          'otp': otp,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send email: ${response.body}');
    }
    print("EmailJS Response: ${response.statusCode} - ${response.body}");
  }

  Future<bool> verifyOTP({required String email, required String otp}) async {
    final doc = await _firestore.collection('emailOtps').doc(email).get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    final storedOtp = data['otp'] as String;
    final expiresAtStr = data['expiresAt'] as String;
    final expiresAt = DateTime.parse(expiresAtStr);
    final now = DateTime.now();

    if (storedOtp == otp && now.isBefore(expiresAt)) {
      await _firestore.collection('emailOtps').doc(email).delete();
      return true;
    }

    return false;
  }

  String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
}
