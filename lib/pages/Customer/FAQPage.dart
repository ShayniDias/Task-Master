import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

import '../faq_item.dart';
import 'Models/faq_model.dart';

class FAQPage extends StatefulWidget {
  @override
  _FAQPageState createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FAQ> hardwareFAQs = [];
  List<FAQ> softwareFAQs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAndFetchFAQs();
  }

  Future<void> _initializeAndFetchFAQs() async {
    await Firebase.initializeApp();
    await _fetchFAQs();
  }

  Future<void> _fetchFAQs() async {
    DatabaseReference faqsRef = FirebaseDatabase.instance.ref().child('faqs');

    final snapshot = await faqsRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;

      final hardwareList = data['hardware'] as List<dynamic>? ?? [];
      final softwareList = data['software'] as List<dynamic>? ?? [];

      setState(() {
        hardwareFAQs = hardwareList
            .map((item) => FAQ.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        softwareFAQs = softwareList
            .map((item) => FAQ.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("FAQ'S",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Hardware Problems'),
            Tab(text: 'Software Problems'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildFAQList(hardwareFAQs),
          _buildFAQList(softwareFAQs),
        ],
      ),
    );
  }

  Widget _buildFAQList(List<FAQ> faqs) {
    return faqs.isEmpty
        ? const Center(child: Text("No FAQs available"))
        : ListView.builder(
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        return FAQItem(faq: faqs[index]);
      },
    );
  }
}
