import 'package:flutter/material.dart';

class ContactProfileScreen extends StatefulWidget {
  final Map<String, dynamic> contact;

  const ContactProfileScreen({Key? key, required this.contact}) : super(key: key);

  @override
  State<ContactProfileScreen> createState() => _ContactProfileScreenState();
}

class _ContactProfileScreenState extends State<ContactProfileScreen> {
  bool isMuted = false;

  @override
  Widget build(BuildContext context) {
    final contact = widget.contact;

    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // AppBar Row
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Profile Picture & Name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade700,
                    child: Icon(contact['avatar'], size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    contact['name'],
                    style: const TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Online',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // About Section
            _buildSectionTitle('About'),
            _buildCard(
              child: Text(
                contact['about'] ?? 'Hey there! I am using ChatMate.',
                style: TextStyle(color: Colors.grey.shade300, fontSize: 15),
              ),
            ),

            const SizedBox(height: 20),

            // Media Section (Updated like WhatsApp)
            _buildSectionTitle('Media, Links, and Docs'),
            _buildCard(
              child: InkWell(
                onTap: () {
                  // Navigate to full media screen
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Media Thumbnails
                    Row(
                      children: List.generate(3, (index) {
                        return Container(
                          margin: EdgeInsets.only(right: 8),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: const DecorationImage(
                              image: AssetImage('assets/media_placeholder.png'), // Replace with actual image
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }),
                    ),
                    const Row(
                      children: [
                        
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Notification Settings
            _buildSectionTitle('Notification Settings'),
            _buildCard(
              child: SwitchListTile(
                activeColor: const Color(0xFFF57C00),
                title: const Text('Mute Notifications', style: TextStyle(color: Colors.white)),
                value: isMuted,
                onChanged: (val) {
                  setState(() {
                    isMuted = val;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            // Report & Block Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                   
                    label: const Text('Report', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF424242),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showReportDialog(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                
                    label: const Text('Block', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 209, 58, 56),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showBlockConfirmationDialog(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade900, Colors.grey.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  void _showBlockConfirmationDialog(BuildContext context) {
    final contact = widget.contact;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade800,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Block ${contact['name']}?', style: const TextStyle(color: Colors.white)),
          content: Text(
            'Blocked contacts can’t call or message you.',
            style: TextStyle(color: Colors.grey.shade300),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, {'action': 'block', 'contact': contact});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Block', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showReportDialog(BuildContext context) {
    final contact = widget.contact;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade800,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Report ${contact['name']}?', style: const TextStyle(color: Colors.white)),
          content: Text(
            'Reported contacts will be reviewed for policy violations.',
            style: TextStyle(color: Colors.grey.shade300),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User has been reported.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF57C00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Report', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
