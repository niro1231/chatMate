import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade800,
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text("Profile", style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              "View and edit your profile",
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/profile',
              ); // ⬅️ Use named route here
            },
          ),
          ListTile(
            leading: const Icon(Icons.sim_card_alert, color: Colors.white),
            title: const Text(
              "Change Email",
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              "Change your registered Email",
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/change-email',
              ); // ⬅️ Use named route here
            },
          ),

          ListTile(
            leading: const Icon(Icons.wallpaper, color: Colors.white),
            title: const Text(
              "Chat Wallpaper",
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              "Change chat background",
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/wallpaper',
              ); // ⬅️ Use named route here
            },
          ),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.white),
            title: const Text(
              "Delete Account",
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              "Delete your account permanently",
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/accdele',
              ); // ⬅️ Use named route here
            },
          ),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.white),
            title: const Text("Help", style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              "Help center, contact us",
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {
              Navigator.pushNamed(context, '/help'); // ⬅️ Use named route here
            },
          ),
        ],
      ),
    );
  }
}
