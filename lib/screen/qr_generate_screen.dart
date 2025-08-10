import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'dart:convert'; // for jsonEncode

class QRGenerateScreen extends StatefulWidget {
  final String email;
  final String name; 
  const QRGenerateScreen({Key? key, required this.email, required this.name}) : super(key: key);

  @override
  State<QRGenerateScreen> createState() => _QRGenerateScreenState();
}

class _QRGenerateScreenState extends State<QRGenerateScreen> {
  late String uniqueId;
  late String qrData;

  @override
  void initState() {
    super.initState();
    uniqueId = const Uuid().v4();

    qrData = jsonEncode({
      'id' : uniqueId,
      'email' : widget.email,
      'name' : widget.name,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade800,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Generate QR Code',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // QR Code Placeholder
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: PrettyQrView.data(
                    data: qrData!
                  )
                ),
                const SizedBox(height: 32),

                const Text(
                  "Your QR Code",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  "Others can scan this QR code\nto start chatting with you",
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
