import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class ProviderInquiryManagement extends StatefulWidget {
  const ProviderInquiryManagement({super.key});
  @override
  _ProviderInquiryManagementState createState() => _ProviderInquiryManagementState();
}

class _ProviderInquiryManagementState extends State<ProviderInquiryManagement> {
  User? _user;
  List<Map<String, dynamic>> _inquiries = [];
  TextEditingController _replyController = TextEditingController();
  String? _selectedInquiryId;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  void _getUser() {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _fetchInquiries();
    }
  }

  void _fetchInquiries() {
    DatabaseReference ref = FirebaseDatabase.instance.ref("companies/${_user!.uid}/services");
    ref.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        List<Map<String, dynamic>> tempList = [];
        data.forEach((serviceId, serviceData) {
          if (serviceData["inquiries"] != null) {
            final inquiriesData = serviceData["inquiries"] as Map<dynamic, dynamic>;
            inquiriesData.forEach((inquiryId, inquiryDetails) {
              tempList.add({
                "inquiryId": inquiryId,
                "serviceId": serviceId,
                ...inquiryDetails
              });
            });
          }
        });
        setState(() {
          _inquiries = tempList;
        });
      }
    }, onError: (error) {
      print("Error fetching inquiries: $error");
    });
  }
  void _addReply(String inquiryId, String serviceId, String reply) {
    // Sanitize the UID to ensure it doesn't contain invalid characters
    String sanitizedUid = _user!.uid.replaceAll(RegExp(r'[.$#\[\]]'), '_');

    print("Adding reply to inquiryId: $inquiryId, serviceId: $serviceId, reply: $reply");
    DatabaseReference ref = FirebaseDatabase.instance
        .ref("companies/$sanitizedUid/services/$serviceId/inquiries/$inquiryId");
    ref.update({
      'reply': reply,
      'isProviderReply': true,
    }).then((_) {
      print("Reply added successfully");
      _replyController.clear();
      setState(() {
        _selectedInquiryId = null;
        _fetchInquiries(); // Refresh the inquiries list to reflect the new reply
      });
    }).catchError((error) {
      print("Error adding reply: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Inquiries", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Inquiries (${_inquiries.length})",
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: _inquiries.isEmpty
                  ? Center(child: Text("No Inquiries Found", style: GoogleFonts.poppins()))
                  : ListView.builder(
                itemCount: _inquiries.length,
                itemBuilder: (context, index) {
                  var inquiry = _inquiries[index];
                  return FadeInUp(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.0),
                        leading: Icon(Icons.question_answer, color: Colors.blue, size: 36),
                        title: Text(inquiry['userName'] ?? 'Anonymous',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(inquiry['inquiry'] ?? '',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600])),
                            if (inquiry['isProviderReply'] == true)
                              Text('Your Reply: ${inquiry['reply'] ?? 'No reply yet'}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.blue)),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _selectedInquiryId = inquiry['inquiryId'];
                            _replyController.text = inquiry['reply'] ?? '';
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_selectedInquiryId != null)
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Add a Reply",
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    TextField(
                      controller: _replyController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Write your reply here...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_replyController.text.isNotEmpty) {
                            var selectedInquiry = _inquiries.firstWhere(
                                    (inquiry) => inquiry['inquiryId'] == _selectedInquiryId);
                            _addReply(
                                selectedInquiry['inquiryId'],
                                selectedInquiry['serviceId'],
                                _replyController.text);
                          }
                        },
                        child: Text("Submit Reply",
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[500],
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
