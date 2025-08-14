import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatWallpaperScreen extends StatefulWidget {
  const ChatWallpaperScreen({Key? key}) : super(key: key);

  @override
  State<ChatWallpaperScreen> createState() => _ChatWallpaperScreenState();
}

class _ChatWallpaperScreenState extends State<ChatWallpaperScreen> {
  Color? selectedColor;

  final List<Color> colorOptions = [
    // Classic colors
    Colors.black,
    Colors.white,
    Colors.grey.shade800,
    Colors.grey.shade600,
    Colors.grey.shade400,
    Colors.grey.shade200,

    // Blue shades
    Colors.blue.shade900,
    Colors.blue.shade500,
    Colors.blue.shade200,
    Colors.lightBlue.shade400,
    Colors.cyan.shade300,
    Colors.teal.shade400,

    // Green shades
    Colors.green.shade900,
    Colors.green.shade500,
    Colors.green.shade200,
    Colors.lightGreen.shade400,
    Colors.lime.shade300,

    // Red/Pink shades
    Colors.red.shade900,
    Colors.red.shade500,
    Colors.red.shade200,
    Colors.pink.shade400,

    // Orange/Yellow shades
    Colors.orange.shade700,
    Colors.orange.shade300,
    Colors.deepOrange.shade400,
    Colors.amber.shade400,
    Colors.yellow.shade300,

    // Purple shades
    Colors.purple.shade700,
    Colors.purple.shade300,
    Colors.deepPurple.shade400,
    Colors.indigo.shade400,

    // Brown and other colors
    Colors.brown.shade600,
    Colors.blueGrey.shade600,
  ];

  void _applyWallpaper() async {
    if (selectedColor != null) {
      // Save the selected color to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('chat_wallpaper_color', selectedColor!.value);

      // Return the selected color to the calling screen
      Navigator.pop(context, {'color': selectedColor});
    }
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
          const Text(
            'Solid Colors',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colorOptions.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedColor = color;
                  });
                },
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: color,
                    border: selectedColor == color
                        ? Border.all(width: 2.5, color: const Color(0xFFEA911D))
                        : Border.all(width: 1, color: Colors.grey.shade700),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: selectedColor == color
                        ? [
                            BoxShadow(
                              color: const Color(0xFFEA911D).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Apply Wallpaper',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
