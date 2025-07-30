import 'package:flutter/material.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> contacts = const [
    {'name': 'John Doe', 'status': 'Available'},
    {'name': 'Sarah Wilson', 'status': 'At work'},
    {'name': 'Mike Johnson', 'status': 'Busy'},
    {'name': 'Emily Davis', 'status': 'Chilling'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        title: const Text('Select Contact', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF424242),
      ),
      body: ListView.builder(
        itemCount: contacts.length + 2, // +1 for "New Contact", +1 for "Saved Contacts" label
        itemBuilder: (context, index) {
          if (index == 0) {
            // New Contact button
            return ListTile(
              onTap: () {
               Navigator.pushNamed(context, '/qr-system');
                },
              leading: const Icon(Icons.person_add, color: Colors.white),
              title: const Text(
                'New Contact',
                style: TextStyle(color: Colors.white),
              ),
            );
          } else if (index == 1) {
            // "Saved Contacts" header
            return const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                'Saved Contacts',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final contact = contacts[index - 2]; // shift by 2 because of the above 2 widgets
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(contact['name']!, style: const TextStyle(color: Colors.white)),
            subtitle: Text(contact['status']!, style: const TextStyle(color: Colors.white70)),
            onTap: () {
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
