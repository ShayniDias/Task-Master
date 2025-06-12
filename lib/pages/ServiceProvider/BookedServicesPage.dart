import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskmaster/pages/ServiceProvider/booked_service_details.dart';

class BookedServicesPage extends StatefulWidget {
  @override
  _BookedServicesPageState createState() => _BookedServicesPageState();
}

class _BookedServicesPageState extends State<BookedServicesPage> {
  User? _user;
  List<Map<String, dynamic>> _bookedServices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUser();
    _fetchBookedServices();
  }

  void _getUser() {
    _user = FirebaseAuth.instance.currentUser;
  }

  void _fetchBookedServices() {
    if (_user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    DatabaseReference ref = FirebaseDatabase.instance.ref("bookings");
    ref.orderByChild("companyId").equalTo(_user!.uid).onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        List<Map<String, dynamic>> tempList = [];
        data.forEach((key, value) {
          if (value != null) {
            // Convert value to a Map and add bookingId
            var booking = Map<String, dynamic>.from(value);
            booking['bookingId'] = key;
            tempList.add(booking);
          }
        });
        setState(() {
          _bookedServices = tempList;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }, onError: (error) {
      print("Error fetching booked services: $error");
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Booked Services",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.teal))
          : _bookedServices.isEmpty
          ? Center(child: Text("No Booked Services Found", style: GoogleFonts.poppins()))
          : ListView.builder(
        itemCount: _bookedServices.length,
        itemBuilder: (context, index) {
          var booking = _bookedServices[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              title: Text(
                booking['serviceName'] ?? 'Unknown Service',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Customer: ${booking['userName'] ?? 'Unknown'}",
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  Text(
                    "Booking Time: ${booking['bookingTime'] != null ? DateTime.fromMillisecondsSinceEpoch(booking['bookingTime']).toString() : 'N/A'}",
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    "Status: ${booking['status'] ?? 'Unknown'}",
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.blue),
                  ),
                ],
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookedServiceDetails(booking: booking),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
