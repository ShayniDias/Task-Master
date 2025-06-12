import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:taskmaster/pages/Customer/Profile.dart';
import 'package:taskmaster/pages/Customer/ChatbotPage.dart';
import 'package:taskmaster/pages/Customer/RepairingService.dart';
import 'package:taskmaster/pages/Customer/CleaningService.dart';
import 'package:taskmaster/pages/Customer/PaintingService.dart';
import 'package:taskmaster/pages/Customer/FAQPage.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late User _currentUser;
  Map<String, dynamic>? _userData;

  List<String> _imageUrls = [];

  void _loadBannerImages() async {
    final snapshot = await _database.child('banners').get();

    if (snapshot.exists) {
      final List<String> urls = [];

      final data = Map<String, dynamic>.from(snapshot.value as Map);

      data.forEach((key, value) {
        final entry = Map<String, dynamic>.from(value);
        final imageUrl = entry['imageUrl'];
        final isActive = entry['active'] ?? true;

        if (imageUrl != null && isActive == true) {
          urls.add(imageUrl);
        }
      });

      setState(() {
        _imageUrls = urls;
      });
    }
  }



  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser!;
    _loadUserData();
    _loadBannerImages();
  }

  void _loadUserData() async {
    DataSnapshot snapshot =
    await _database.child('users/${_currentUser.uid}').get();
    if (snapshot.exists) {
      setState(() {
        _userData = Map<String, dynamic>.from(snapshot.value as Map);
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _logout() async {
    bool confirm = await _showLogoutDialog();
    if (confirm) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/authentication');
      }
    }
  }

  Future<bool> _showLogoutDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final userName =
        _userData?['name'] ?? _currentUser.displayName ?? 'User';
    final profileUrl = _currentUser.photoURL;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 110,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade900, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade900.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      backgroundImage: profileUrl != null
                          ? NetworkImage(profileUrl)
                          : null,
                      child: profileUrl == null
                          ? const Icon(Icons.person,
                          size: 35, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getGreeting(),
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: _logout,
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// Image Slider Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 180,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.9,
                  aspectRatio: 16 / 9,
                  autoPlayInterval: const Duration(seconds: 3),
                ),
                items: _imageUrls.map((imageUrl) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          /// Dashboard Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _DashboardSection(
                    title: 'Services',
                    children: [
                      // _ActionCard(
                      //   icon: Icons.computer,
                      //   title: 'Computer Troubleshooting',
                      //   color: Colors.blue,
                      //   onTap: () {
                      //     // Navigator.push(
                      //     //   context,
                      //     //   MaterialPageRoute(builder: (context) => ComputerTroubleshooting()),
                      //     // );
                      //   },
                      // ),
                      _ActionCard(
                        icon: Icons.cleaning_services,
                        title: 'Cleaning Service',
                        color: Colors.green,
                        onTap: () {
                          // Navigate to Profile page
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CleaningServices()),
                          );
                        },
                      ),
                      _ActionCard(
                        icon: Icons.build,
                        title: 'Repairing Service',
                        color: Colors.orange,
                        onTap: () {
                          // Navigate to Profile page
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RepairingServices()),
                          );
                        },
                      ),
                      _ActionCard(
                        icon: Icons.format_paint,
                        title: 'Painting Service',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PaintingServices()),
                          );
                        },
                      ),  _ActionCard(
                        icon: Icons.info,
                        title: 'AI Chat Bot',
                        color: Colors.amber,
                        onTap: () {
                          // Navigate to Profile page
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChatbotPage()),
                          );
                        },
                      ),
                      _ActionCard(
                        icon: Icons.person,
                        title: 'Manage Profile',
                        color: Colors.teal,
                        onTap: () {
                          // Navigate to Profile page
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProfilePage()),
                          );
                        },
                      ),

                      _ActionCard(
                        icon: Icons.computer,
                        title: 'Computer Troubleshooting',
                        color: Colors.teal,
                        onTap: () {
                          // Navigate to Profile page
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => FAQPage()),
                          );
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DashboardSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: children,
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard(
      {required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(height: 10),
              Text(title, style: GoogleFonts.poppins(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
