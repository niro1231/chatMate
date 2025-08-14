import 'package:chatme/database/UserRepository.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "Loading...";
  String about = "Loading...";
  String email = "Loading...";
  String? profileImagePath;
  final Repository _repository = Repository();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final loggedInEmail = await _repository.getLoggedInEmail();
      final user = await _repository.getLoggedInUser();

      setState(() {
        if (loggedInEmail != null) {
          email = loggedInEmail;
        }
        if (user != null) {
          name = user.name;
          about = user.about;
          profileImagePath = user.profileImagePath;
        }
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        name = "Error loading name";
        about = "Error loading about";
        email = "Error loading email";
      });
    }
  }

  Future<void> _saveAbout(String newAbout) async {
    try {
      print('🔄 Starting to save about: $newAbout');
      final loggedInEmail = await _repository.getLoggedInEmail();
      print('📧 Logged in email: $loggedInEmail');

      if (loggedInEmail != null) {
        print('💾 Calling updateUserAbout...');
        await _repository.updateUserAbout(loggedInEmail, newAbout);
        print('✅ About updated successfully in database');

        setState(() {
          about = newAbout;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('About updated successfully'),
              backgroundColor: Color(0xFFEA911D),
            ),
          );
        }
      } else {
        print('❌ No logged in email found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No logged in user found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error updating about: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update about: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveName(String newName) async {
    try {
      print('🔄 Starting to save name: $newName');
      final loggedInEmail = await _repository.getLoggedInEmail();
      print('📧 Logged in email: $loggedInEmail');

      if (loggedInEmail != null) {
        print('💾 Calling updateUserName...');
        await _repository.updateUserName(loggedInEmail, newName);
        print('✅ Name updated successfully in database');

        setState(() {
          name = newName;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Name updated successfully'),
              backgroundColor: Color(0xFFEA911D),
            ),
          );
        }
      } else {
        print('❌ No logged in email found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No logged in user found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error updating name: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update name: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectProfileImage() async {
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF424242),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Profile Photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                    _buildImageSourceOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                    if (profileImagePath != null)
                      _buildImageSourceOption(
                        icon: Icons.delete,
                        label: 'Remove',
                        onTap: () => _removeProfileImage(),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('Error showing image picker: $e');
    }
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFEA911D),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      Navigator.pop(context); // Close the bottom sheet
      
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // Save the image path to database
        final loggedInEmail = await _repository.getLoggedInEmail();
        if (loggedInEmail != null) {
          await _repository.updateUserProfileImage(loggedInEmail, pickedFile.path);
          print('✅ Profile image updated in database successfully!');
        }

        setState(() {
          profileImagePath = pickedFile.path;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully!'),
              backgroundColor: Color(0xFFEA911D),
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeProfileImage() async {
    try {
      Navigator.pop(context); // Close the bottom sheet
      
      // Remove the image path from database
      final loggedInEmail = await _repository.getLoggedInEmail();
      if (loggedInEmail != null) {
        await _repository.updateUserProfileImage(loggedInEmail, null);
        print('✅ Profile image removed from database successfully!');
      }

      setState(() {
        profileImagePath = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo removed'),
            backgroundColor: Color(0xFFEA911D),
          ),
        );
      }
    } catch (e) {
      print('Error removing profile image: $e');
    }
  }

  void _editField(
    String fieldName,
    String currentValue,
    Function(String) onSave,
  ) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF202C33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          "Edit $fieldName",
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter $fieldName",
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFEA911D)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFEA911D), width: 2),
            ),
          ),
          cursorColor: const Color(0xFFEA911D),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final result = onSave(controller.text.trim());
              // Handle both sync and async functions
              if (result is Future) {
                await result;
              }
              Navigator.pop(context);
            },
            child: const Text(
              "Save",
              style: TextStyle(color: Color(0xFFEA911D)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableTile(
    String label,
    String value,
    IconData icon,
    Function() onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFEA911D)),
      title: Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: const Icon(Icons.edit, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildNavigationTile(
    String label,
    String value,
    IconData icon,
    Function() onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFEA911D)),
      title: Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF202C33),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to logout?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final repo = Repository();
              await repo.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF424242),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          Center(
            child: GestureDetector(
              onTap: _selectProfileImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey,
                    backgroundImage: profileImagePath != null 
                        ? FileImage(File(profileImagePath!))
                        : null,
                    child: profileImagePath == null 
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEA911D),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          _buildEditableTile("Name", name, Icons.person_outline, () {
            _editField("Name", name, _saveName);
          }),
          _buildEditableTile("About", about, Icons.info_outline, () {
            _editField("About", about, _saveAbout);
          }),
          _buildNavigationTile("Email", email, Icons.email_outlined, () {
            Navigator.pushNamed(context, '/change-email');
          }),

          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: ElevatedButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout),
              label: const Text("Logout", style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
