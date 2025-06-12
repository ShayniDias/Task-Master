import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:taskmaster/pages/ServiceProvider/AddPost.dart';
import 'package:taskmaster/pages/ServiceProvider/ViewPost.dart';
import 'package:taskmaster/pages/ServiceProvider/ContactAdmin.dart';
import 'package:taskmaster/pages/ServiceProvider/Profile.dart';
import 'package:taskmaster/pages/ServiceProvider/ProviderInquiryManagement.dart';
import 'package:taskmaster/pages/ServiceProvider/BookedServicesPage.dart';

class ServiceProviderDashboard extends StatefulWidget {
  const ServiceProviderDashboard({super.key});

  @override
  State<ServiceProviderDashboard> createState() =>
      _ServiceProviderDashboardState();
}

class _ServiceProviderDashboardState extends State<ServiceProviderDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  User? _currentUser;
  Map<dynamic, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      if (_currentUser == null) {
        setState(() {
          _errorMessage = 'No user logged in';
          _isLoading = false;
        });
        return;
      }

      final DatabaseEvent event = await _database
          .child('users/${_currentUser!.uid}')
          .once();
      final DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        setState(() {
          _userData = snapshot.value as Map<dynamic, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'User data not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching user data: $e';
        _isLoading = false;
      });
    }
  }

  String get _userName {
    if (_userData?['name'] != null) return _userData!['name'];
    if (_currentUser?.displayName != null) return _currentUser!.displayName!;
    return _currentUser?.email?.split('@').first ?? 'User';
  }

  String get _profileImageUrl {
    if (_userData?['profileImage'] != null) return _userData!['profileImage'];
    if (_currentUser?.photoURL != null) return _currentUser!.photoURL!;
    return 'https://ui-avatars.com/api/?name=${_userName.replaceAll(' ', '+')}&background=random';
  }

  String get _userEmail => _currentUser?.email ?? 'No email';
//logout button
  Future<bool> _showLogoutDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _logout() async {
    bool confirm = await _showLogoutDialog(context);
    if (confirm) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/authentication');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage != null)
            Expanded(child: Center(child: Text(_errorMessage!)))
          else
            _buildDashboardGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _logout,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: NetworkImage(_profileImageUrl),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _userEmail,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        if (_userData?['userType'] != null)
                          Text(
                            '(${_userData!['userType']})',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.logout_rounded,
                        color: Colors.white, size: 30),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Service Provider Dashboard',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardGrid() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _DashboardButton(
              title: "Add Post",
              icon: Icons.add_circle_outline,
              color: Colors.blue.shade600,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddPost()),
              ),
            ),
            _DashboardButton(
              title: "Manage Posts",
              icon: Icons.edit_note,
              color: Colors.purple.shade600,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ViewPost()),
              ),
            ),
            _DashboardButton(
              title: "Profile Edit",
              icon: Icons.edit,
              color: Colors.blue.shade600,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Profile()),
              ),
            ),
            _DashboardButton(
              title: "Contact Admin",
              icon: Icons.contact_support,
              color: Colors.purple.shade600,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ContactAdmin()),
              ),
            ),
            _DashboardButton(
              title: "Inquiries",
              icon: Icons.contact_support,
              color: Colors.blue.shade600,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProviderInquiryManagement()),
              ),
            ),
            _DashboardButton(
              title: "Book Services",
              icon: Icons.add_shopping_cart,
              color: Colors.purple.shade600,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BookedServicesPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color.withOpacity(0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
