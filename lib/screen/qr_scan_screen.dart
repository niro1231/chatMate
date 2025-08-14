import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'chat_screen.dart';
import 'package:chatme/modal/user.dart';
import 'package:chatme/database/UserRepository.dart';

class QRScanScreen extends StatefulWidget {
  QRScanScreen({super.key});
  
  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  bool _isProcessing = false; // to avoid multiple scans firing
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
          'Scan QR Code',
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
                // Camera preview placeholder
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFEA911D),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Scanning animation overlay
                      Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: MobileScanner(
                            controller: MobileScannerController(
                              detectionSpeed: DetectionSpeed.noDuplicates
                            ),
                            onDetect: (capture) async {
                              if (_isProcessing) return;
                              final barcodes = capture.barcodes;
                              if (barcodes.isEmpty) return;

                              final raw = barcodes.first.rawValue;
                              if (raw == null) return;

                              try {
                                final Map<String, dynamic> data = jsonDecode(raw);
                                if(data.containsKey('email') && data['email'] is String) {
                                  _isProcessing = true;

                                  // Use the UUID from the QR code data for the new user
                                  final scannedUserUuid = data['uuid'] as String?;
                                  final scannedUserEmail = data['email'] as String;
                                  final scannedUserName = data['name'] as String?;

                                  if (scannedUserUuid != null && scannedUserName != null) {
                                    final now = DateTime.now().toIso8601String();
                                    final newUser = User(
                                      uuid: scannedUserUuid, // Use the UUID from the scan
                                      email: scannedUserEmail,
                                      name: scannedUserName,
                                      createdAt: now,
                                      updatedAt: now,
                                    );

                                    final repo = Repository();
                                    await repo.insertUser(newUser); // Save the user to the local database
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(receiverId: data['uuid']),
                                      ),
                                    ).then((_) {
                                      // Reset processing flag when returning to scanner
                                      _isProcessing = false;
                                    });
                                  }
                                } else {
                                    // Handle invalid QR format here if you want
                                    if (!mounted) return;
                                    _showInvalidQRCodeDialog();
                                }
                              }  catch (e) {
                                // Handle JSON parse error if needed
                                if (!mounted) return;
                                _showInvalidQRCodeDialog();
                              }                              
                            },
                          ),
                        ),
                      ),
                      // Corner indicators
                      ...List.generate(4, (index) {
                        return Positioned(
                          top: index < 2 ? 20 : null,
                          bottom: index >= 2 ? 20 : null,
                          left: index % 2 == 0 ? 20 : null,
                          right: index % 2 == 1 ? 20 : null,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              border: Border(
                                top: index < 2
                                    ? const BorderSide(
                                        color: Color(0xFFEA911D),
                                        width: 3,
                                      )
                                    : BorderSide.none,
                                bottom: index >= 2
                                    ? const BorderSide(
                                        color: Color(0xFFEA911D),
                                        width: 3,
                                      )
                                    : BorderSide.none,
                                left: index % 2 == 0
                                    ? const BorderSide(
                                        color: Color(0xFFEA911D),
                                        width: 3,
                                      )
                                    : BorderSide.none,
                                right: index % 2 == 1
                                    ? const BorderSide(
                                        color: Color(0xFFEA911D),
                                        width: 3,
                                      )
                                    : BorderSide.none,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  "Scan QR Code",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  "Point your camera at a QR code\nto scan and connect",
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

  void _showInvalidQRCodeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Invalid QR Code'),
          content: const Text('The scanned QR code is not valid or not supported.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

}
