import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ContactAdmin extends StatefulWidget {
  const ContactAdmin({super.key});

  @override
  State<ContactAdmin> createState() => _ContactAdminState();
}

class _ContactAdminState extends State<ContactAdmin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  User? _user;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _auth.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a message',
            style: GoogleFonts.poppins())),
      );
      return;
    }

    if (_user != null) {
      _database.child('messages').push().set({
        'email': _user!.email,
        'message': message,
        'timestamp': ServerValue.timestamp,
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message sent to admin!',
              style: GoogleFonts.poppins())),
        );
        _messageController.clear();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message',
              style: GoogleFonts.poppins())),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in',
            style: GoogleFonts.poppins())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Contact Admin',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 22,
            )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need Help?',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.deepPurple.shade800,
                )),
            const SizedBox(height: 8),
            Text('We\'re here to help you!',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                )),
            const SizedBox(height: 32),
            _buildContactCards(),
            const SizedBox(height: 40),
            Text('Send Direct Message',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo.shade900,
                )),
            const SizedBox(height: 16),
            _buildMessageField(),
            const SizedBox(height: 24),
            _buildSendButton(),
            const SizedBox(height: 40),
            _buildSocialSection(),
          ],
        ).animate().fadeIn(duration: 500.ms),
      ),
    );
  }

  Widget _buildContactCards() {
    return Column(
      children: [
        _ContactCard(
          icon: FontAwesomeIcons.solidCommentDots,
          title: 'Live Chat',
          subtitle: 'Instant 24/7 support',
          color: Colors.purple,
          gradient: LinearGradient(
            colors: [Colors.purple.shade300, Colors.purple.shade600],
          ),
        ),
        const SizedBox(height: 16),
        _ContactCard(
          icon: FontAwesomeIcons.envelopeOpenText,
          title: 'Email Us',
          subtitle: 'support@taskmaster.com',
          color: Colors.blue,
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade600],
          ),
        ),
        const SizedBox(height: 16),
        _ContactCard(
          icon: FontAwesomeIcons.phoneVolume,
          title: 'Call Us',
          subtitle: '071 - 5119831',
          color: Colors.green,
          gradient: LinearGradient(
            colors: [Colors.green.shade300, Colors.green.shade600],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageField() {
    return TextField(
      controller: _messageController,
      maxLines: 5,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        hintText: 'Type your message...',
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey.shade500,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: Colors.deepPurple.shade200, width: 2),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _sendMessage,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.deepPurple.shade800,
          shadowColor: Colors.deepPurple.shade200,
          elevation: 6,
        ),
        child: Text('Send Message',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            )),
      ).animate().scale(delay: 200.ms),
    );
  }

  Widget _buildSocialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Follow Us',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.indigo.shade900,
            )),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SocialCircle(
              icon: FontAwesomeIcons.facebookF,
              color: Colors.blue.shade800,
            ),
            _SocialCircle(
              icon: FontAwesomeIcons.xTwitter,
              color: Colors.black,
            ),
            _SocialCircle(
              icon: FontAwesomeIcons.instagram,
              color: Colors.pink,
            ),
            _SocialCircle(
              icon: FontAwesomeIcons.linkedinIn,
              color: Colors.blue.shade700,
            ),
          ],
        ).animate().slideX(duration: 500.ms),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Gradient gradient;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        title: Text(title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            )),
        subtitle: Text(subtitle,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
            )),
        trailing: Icon(Icons.arrow_forward_rounded, color: Colors.white),
      ),
    ).animate().scale(delay: 100.ms);
  }
}
//follow us
class _SocialCircle extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SocialCircle({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: FaIcon(icon, color: color, size: 20),
        onPressed: () {},
      ),
    );
  }
}
