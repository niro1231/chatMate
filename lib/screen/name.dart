import 'package:chatme/database/UserRepository.dart';
import 'package:flutter/material.dart';
import 'package:chatme/modal/user.dart'; 
import 'package:uuid/uuid.dart';

class NameScreen extends StatefulWidget {
  final String email;
  const NameScreen({super.key, required this.email});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _submitName() async {
    if (_formKey.currentState!.validate()) {
      String name = _nameController.text.trim();
      String newUuid = const Uuid().v4();

      try {
        final now = DateTime.now().toIso8601String();
        final user = User(
          uuid: newUuid,
          email: widget.email,
          name: name,
          createdAt: now,
          updatedAt: now,
        );

        final repo = Repository();
        
        // Create user both locally and in Firestore
        await repo.insertUser(user); 

        // Set as logged in user
        await repo.setLoggedIn(user.email);

        // Sync other users from Firestore to local database
        await repo.syncUsersFromFirestore();

        if (!mounted) return;
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Navigate to home
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_rounded, size: 100, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  "What's your name?",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Enter a name for your profile",
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                Card(
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            style: const TextStyle(color: Colors.black87, fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Your Name',
                              hintText: 'John Doe',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEA911D), width: 2)),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitName,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEA911D),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Save Name', style: TextStyle(fontSize: 18, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}