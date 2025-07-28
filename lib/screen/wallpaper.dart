import 'package:flutter/material.dart';

class ChatWallpaperScreen extends StatefulWidget {
  const ChatWallpaperScreen({Key? key}) : super(key: key);

  @override
  State<ChatWallpaperScreen> createState() => _ChatWallpaperScreenState();
}

class _ChatWallpaperScreenState extends State<ChatWallpaperScreen> {
  Color? selectedColor;
  String? selectedImage;

  final List<Color> colorOptions = [
    Colors.black,
    Colors.white,
    Colors.blue.shade200,
    Colors.green.shade200,
    Colors.orange.shade200,
    Colors.purple.shade200,
  ];

  final List<String> imageOptions = [
    'assets/wall.png',
    
  ];

  void _applyWallpaper() {
    // Save selection to SharedPreferences or global state management
    // You can retrieve this in your chat screen for background
    Navigator.pop(context, {
      'color': selectedColor,
      'image': selectedImage,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Chat Wallpaper'),
        backgroundColor: const Color(0xFF1F1F1F),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Solid Colors', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: colorOptions.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedColor = color;
                    selectedImage = null;
                  });
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    border: selectedColor == color ? Border.all(width: 3, color: Colors.white) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('Image Wallpapers', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: imageOptions.map((path) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedImage = path;
                    selectedColor = null;
                  });
                },
                child: Container(
                  width: 100,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: selectedImage == path ? Border.all(width: 3, color: Colors.white) : null,
                    image: DecorationImage(
                      image: AssetImage(path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _applyWallpaper,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA911D),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Apply Wallpaper', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),

          ),
        ],
      ),
    );
  }
}
