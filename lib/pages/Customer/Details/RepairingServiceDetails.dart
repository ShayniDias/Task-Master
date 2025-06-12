import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';

class RepairingServiceDetails extends StatefulWidget {
  final Map<String, dynamic> service;

  RepairingServiceDetails({required this.service});

  @override
  _RepairingServiceDetailsState createState() => _RepairingServiceDetailsState();
}

class _RepairingServiceDetailsState extends State<RepairingServiceDetails> {
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _inquiryController = TextEditingController();
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _inquiries = [];
  List<Map<String, dynamic>> _completedBookings = [];
  List<Map<String, dynamic>> _allBookings = [];
  double _rating = 0;
  User? _user;
  bool isAgreed = false;
  bool isBooked = false;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
    _fetchInquiries();
    _getUser();
    _checkBookingStatus();
    _fetchCompletedBookings();
    _fetchAllBookings();
  }

  void _getUser() {
    _user = FirebaseAuth.instance.currentUser;
  }

  void _fetchReviews() {
    DatabaseReference ref = FirebaseDatabase.instance
        .ref("companies/${widget.service['companyId']}/services/${widget.service['serviceId']}/reviews");
    ref.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        List<Map<String, dynamic>> tempList = [];
        data.forEach((key, value) {
          if (value != null) {
            tempList.add(Map<String, dynamic>.from(value));
          }
        });
        setState(() {
          _reviews = tempList;
        });
      }
    }, onError: (error) {
      print("Error fetching reviews: $error");
    });
  }

  void _fetchInquiries() {
    DatabaseReference ref = FirebaseDatabase.instance
        .ref("companies/${widget.service['companyId']}/services/${widget.service['serviceId']}/inquiries");
    ref.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        List<Map<String, dynamic>> tempList = [];
        data.forEach((key, value) {
          if (value != null && (_user?.uid == value['userId'] || value['isProviderReply'] == true)) {
            tempList.add({'key': key, ...Map<String, dynamic>.from(value)});
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

  void _checkBookingStatus() {
    if (_user == null) {
      return;
    }

    DatabaseReference ref = FirebaseDatabase.instance.ref("bookings");
    ref.orderByChild("userId").equalTo(_user!.uid).onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          if (value['serviceId'] == widget.service['serviceId']) {
            if (value['status'] == 'pending') {
              setState(() {
                isBooked = true;
              });
            } else if (value['status'] == 'completed') {
              DateTime bookingTime = DateTime.fromMillisecondsSinceEpoch(value['bookingTime']);
              if (DateTime.now().difference(bookingTime).inDays >= 1) {
                setState(() {
                  isBooked = false;
                });
              } else {
                setState(() {
                  isBooked = true;
                });
              }
            }
          }
        });
      }
    }, onError: (error) {
      print("Error checking booking status: $error");
    });
  }

  void _fetchCompletedBookings() {
    if (_user == null) {
      return;
    }

    DatabaseReference ref = FirebaseDatabase.instance.ref("bookings");
    ref.orderByChild("userId").equalTo(_user!.uid).onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        List<Map<String, dynamic>> tempList = [];
        data.forEach((key, value) {
          if (value['serviceId'] == widget.service['serviceId'] && value['status'] == 'completed') {
            tempList.add(Map<String, dynamic>.from(value));
          }
        });
        setState(() {
          _completedBookings = tempList;
        });
      }
    }, onError: (error) {
      print("Error fetching completed bookings: $error");
    });
  }

  void _fetchAllBookings() {
    DatabaseReference ref = FirebaseDatabase.instance.ref("bookings");
    ref.orderByChild("serviceId").equalTo(widget.service['serviceId']).onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        List<Map<String, dynamic>> tempList = [];
        data.forEach((key, value) {
          tempList.add(Map<String, dynamic>.from(value));
        });
        setState(() {
          _allBookings = tempList;
        });
      }
    }, onError: (error) {
      print("Error fetching all bookings: $error");
    });
  }

  void _addReview(String review, double rating) {
    if (_user == null) {
      print("User not logged in");
      return;
    }

    DatabaseReference ref = FirebaseDatabase.instance
        .ref("companies/${widget.service['companyId']}/services/${widget.service['serviceId']}/reviews")
        .push();
    ref.set({
      'review': review,
      'user': _user!.displayName ?? 'Anonymous',
      'rating': rating,
      'status': 'pending'
    }).then((_) {
      _reviewController.clear();
      setState(() {
        _rating = 0;
      });
    }).catchError((error) {
      print("Error adding review: $error");
    });
  }

  void _addInquiry(String inquiry) {
    if (_user == null) {
      print("User not logged in");
      return;
    }

    DatabaseReference ref = FirebaseDatabase.instance
        .ref("companies/${widget.service['companyId']}/services/${widget.service['serviceId']}/inquiries")
        .push();
    ref.set({
      'inquiry': inquiry,
      'userId': _user!.uid,
      'userName': _user!.displayName ?? 'Anonymous',
      'isProviderReply': false,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }).then((_) {
      _inquiryController.clear();
    }).catchError((error) {
      print("Error adding inquiry: $error");
    });
  }

  void _deleteInquiry(String key) {
    if (key.isEmpty) {
      print("Inquiry key is null or empty");
      return;
    }

    DatabaseReference ref = FirebaseDatabase.instance
        .ref("companies/${widget.service['companyId']}/services/${widget.service['serviceId']}/inquiries/$key");
    ref.remove().then((_) {
      print("Inquiry deleted successfully");
    }).catchError((error) {
      print("Error deleting inquiry: $error");
    });
  }

  void _bookService() {
    if (_user == null) {
      print("User not logged in");
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Confirm Booking"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Are you sure you want to book this service?"),
                  SizedBox(height: 10),
                  CheckboxListTile(
                    title: Text("I agree to the Privacy Policy"),
                    value: isAgreed,
                    onChanged: (bool? value) {
                      setState(() {
                        isAgreed = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  SizedBox(height: 10),
                  Text("Select Date:"),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Text(selectedDate == null ? "Select Date" : "${selectedDate!.toLocal()}".split(' ')[0]),
                  ),
                  SizedBox(height: 10),
                  Text("Select Time:"),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null && picked != selectedTime) {
                        setState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                    child: Text(selectedTime == null ? "Select Time" : selectedTime!.format(context)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: isAgreed && selectedDate != null && selectedTime != null
                      ? () {
                    Navigator.of(context).pop();
                    _confirmBooking();
                  }
                      : null, // Disable button if not agreed or date/time not selected
                  child: Text("Confirm"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  void _confirmBooking() async {
    if (selectedDate == null || selectedTime == null) {
      print("Date or time not selected");
      return;
    }

    DateTime bookingDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    // PayHere Configuration
    final paymentObject = {
      "sandbox": true,
      "merchant_id": "1226542",
      "merchant_secret": "MTcxNzEzMDYxMzQwMzc0OTM0ODExMTU4ODYwNjQ0MDQ3NjgyNTMx",
      "notify_url": "https://henoraads.com",
      "order_id": "ORDER_${DateTime.now().millisecondsSinceEpoch}",
      "items": widget.service['serviceName'],
      "amount": widget.service['price'].toString(),
      "currency": "LKR",
      "first_name": _user?.displayName?.split(" ").first ?? "Customer",
      "last_name": _user?.displayName?.split(" ").last ?? "",
      "email": _user?.email ?? "customer@example.com",
      "phone": _user?.phoneNumber ?? "0779504930",
      "address": "No.1, Street Name",
      "city": "Colombo",
      "country": "Sri Lanka",
      "delivery_address": "No.1, Street Name",
      "delivery_city": "Colombo",
      "delivery_country": "Sri Lanka",
      "custom_1": _user!.uid,
      "custom_2": widget.service['serviceId'],
    };

    print("Payment Object: $paymentObject");

    try {
      PayHere.startPayment(
        paymentObject,
            (paymentId) {
          print("Payment Success: $paymentId");

          DatabaseReference ref = FirebaseDatabase.instance.ref("bookings").push();
          ref.set({
            'userId': _user!.uid,
            'userName': _user!.displayName ?? 'Anonymous',
            'serviceId': widget.service['serviceId'],
            'serviceName': widget.service['serviceName'],
            'companyId': widget.service['companyId'],
            'status': 'pending',
            'bookingTime': bookingDateTime.millisecondsSinceEpoch,
            'paymentId': paymentId,
          }).then((_) {
            setState(() => isBooked = true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Service booked successfully!")),
            );
          }).catchError((error) {
            print("Error booking service: $error");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to book service. Please try again.")),
            );
          });
        },
            (error) {
          // Payment Error
          print("Payment Error: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Payment failed: $error")),
          );
        },
            () {
          // Payment Cancel
          print("Payment Cancelled");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Payment cancelled")),
          );
        },
      );
    } catch (e) {
      print("Payment Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment processing failed")),
      );
    }
  }


  void _viewInvoice(String url) async {
    if (url.isEmpty) {
      print("Invoice URL is empty");
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      print("Invalid URL format");
      return;
    }

    final success = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!success) {
      print("Could not launch the URL");
    }
  }

  void _showBookedSchedules() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.blue),
              SizedBox(width: 8),
              Text("Booked Schedules", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: TableCalendar(
              focusedDay: DateTime.now(),
              firstDay: DateTime.now().subtract(Duration(days: 30)),
              lastDay: DateTime.now().add(Duration(days: 30)),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              eventLoader: (day) {
                return _allBookings.where((booking) {
                  DateTime bookingDate = DateTime.fromMillisecondsSinceEpoch(booking['bookingTime']);
                  return bookingDate.year == day.year && bookingDate.month == day.month && bookingDate.day == day.day;
                }).toList();
              },
              onDaySelected: (selectedDay, focusedDay) {
                List<Map<String, dynamic>> bookingsOnDay = _allBookings.where((booking) {
                  DateTime bookingDate = DateTime.fromMillisecondsSinceEpoch(booking['bookingTime']);
                  return bookingDate.year == selectedDay.year && bookingDate.month == selectedDay.month && bookingDate.day == selectedDay.day;
                }).toList();

                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      title: Row(
                        children: [
                          Icon(FontAwesomeIcons.calendarCheck, color: Colors.green),
                          SizedBox(width: 8),
                          Text("Bookings on ${selectedDay.toLocal()}".split(' ')[0], style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: bookingsOnDay.map((booking) {
                          DateTime bookingDateTime = DateTime.fromMillisecondsSinceEpoch(booking['bookingTime']);
                          return ListTile(
                            leading: Icon(Icons.person, color: Colors.blue),
                            title: Text(booking['userName']),
                            subtitle: Text("${bookingDateTime.hour}:${bookingDateTime.minute}"),
                          );
                        }).toList(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text("Close"),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service["serviceName"],
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[800]!, Colors.blue[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 10,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Container(
                  height: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30)),
                    child: CachedNetworkImage(
                      imageUrl: widget.service["imageUrl"],
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                          child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.error, size: 50),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent
                      ],
                    ),
                  ),
                  child: Text(
                    widget.service["serviceName"],
                    style: GoogleFonts.poppins(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    icon: Icons.currency_exchange,
                    title: "Price",
                    value: "Rs. ${widget.service["price"]}",
                    color: Colors.green,
                  ),
                  SizedBox(height: 15),
                  _buildInfoCard(
                    icon: Icons.access_time,
                    title: "Duration",
                    value: "${widget.service["duration"]} hours",
                    color: Colors.blue,
                  ),
                  SizedBox(height: 25),
                  Text("Service Details",
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Divider(thickness: 2),
                  SizedBox(height: 10),
                  Text(widget.service["description"] ?? "No description available",
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          height: 1.5)),
                  SizedBox(height: 30),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isBooked ? null : _bookService,
                        child: Text(isBooked ? "You already booked this service" : "Book Now",
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[500],
                          padding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 25),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text("Reviews",
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Divider(thickness: 2),
                  SizedBox(height: 10),
                  _buildReviews(),
                  SizedBox(height: 20),
                  _buildReviewForm(),
                  SizedBox(height: 30),
                  Text("Inquiries",
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Divider(thickness: 2),
                  SizedBox(height: 10),
                  _buildInquiries(),
                  SizedBox(height: 20),
                  _buildInquiryForm(),
                  SizedBox(height: 30),
                  Text("Completed Bookings",
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Divider(thickness: 2),
                  SizedBox(height: 10),
                  _buildCompletedBookings(),
                  SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: _showBookedSchedules,
                      child: Text("View All Booked Schedules",
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[500],
                        padding: EdgeInsets.symmetric(
                            vertical: 15, horizontal: 25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: color),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14)),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _reviews.map((review) {
        return ListTile(
          leading: Icon(Icons.person, size: 30),
          title: Text(review['user'] ?? 'Anonymous',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RatingBarIndicator(
                rating: review['rating']?.toDouble() ?? 0,
                itemBuilder: (context, index) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                itemCount: 5,
                itemSize: 20.0,
                direction: Axis.horizontal,
              ),
              Text(review['review'] ?? '',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600])),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviewForm() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Add a Review",
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) {
              setState(() {
                _rating = rating;
              });
            },
          ),
          SizedBox(height: 10),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Write your review here...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                if (_reviewController.text.isNotEmpty) {
                  _addReview(_reviewController.text, _rating);
                }
              },
              child: Text("Submit",
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
    );
  }

  Widget _buildInquiries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _inquiries.map((inquiry) {
        return ListTile(
          leading: Icon(Icons.question_answer, size: 30),
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
                Text('Provider Reply: ${inquiry['reply'] ?? 'No reply yet'}',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.blue)),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              if (inquiry.containsKey('key')) {
                _deleteInquiry(inquiry['key']);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInquiryForm() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Add an Inquiry",
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          TextField(
            controller: _inquiryController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Write your inquiry here...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                if (_inquiryController.text.isNotEmpty) {
                  _addInquiry(_inquiryController.text);
                }
              },
              child: Text("Submit",
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
    );
  }

  Widget _buildCompletedBookings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _completedBookings.map((booking) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            title: Text(booking['serviceName'] ?? 'Unknown Service',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            subtitle: Text("Booked on: ${DateTime.fromMillisecondsSinceEpoch(booking['bookingTime']).toString()}",
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600])),
            trailing: IconButton(
              icon: Icon(Icons.picture_as_pdf, color: Colors.blue),
              onPressed: () {
                if (booking.containsKey('invoiceUrl')) {
                  _viewInvoice(booking['invoiceUrl']);
                }
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}


class CleaningServices extends StatefulWidget {
  @override
  _CleaningServiceState createState() => _CleaningServiceState();
}

class _CleaningServiceState extends State<CleaningServices> {
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> filteredServices = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  void fetchServices() {
    DatabaseReference ref = FirebaseDatabase.instance.ref("companies");
    ref.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        List<Map<String, dynamic>> tempList = [];
        data.forEach((companyId, companyData) {
          if (companyData["services"] != null) {
            final servicesData = companyData["services"] as Map<dynamic, dynamic>;
            servicesData.forEach((serviceId, serviceDetails) {
              if (serviceDetails["serviceType"] == "Cleaning service") {
                tempList.add({
                  "serviceId": serviceId,
                  "companyId": companyId,
                  ...serviceDetails
                });
              }
            });
          }
        });
        setState(() {
          services = tempList;
          filteredServices = tempList;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }, onError: (error) {
      print("Error fetching services: $error");
    });
  }

  void filterServices(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredServices = services;
      } else {
        filteredServices = services
            .where((service) => service["serviceName"].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cleaning Services", style: GoogleFonts.poppins(fontWeight: FontWeight.bold,color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              onChanged: filterServices,
              decoration: InputDecoration(
                hintText: "Search services...",
                hintStyle: GoogleFonts.poppins(),
                prefixIcon: Icon(Icons.search, color: Colors.teal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          isLoading
              ? Expanded(child: Center(child: CircularProgressIndicator(color: Colors.teal)))
              : Expanded(
            child: filteredServices.isEmpty
                ? Center(child: Text("No Cleaning Services Found", style: GoogleFonts.poppins()))
                : Padding(
              padding: const EdgeInsets.all(10.0),
              child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2, // Adaptive columns
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: MediaQuery.of(context).size.width > 600 ? 0.8 : 0.9, // Adjust aspect ratio
                  ),
                  itemCount: filteredServices.length,
                  itemBuilder: (context, index) {
                    var service = filteredServices[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RepairingServiceDetails(service: service),
                          ),
                        );
                      },
                      child: FadeInUp(
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                                  child: CachedNetworkImage(
                                    imageUrl: service["imageUrl"],
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) => Icon(Icons.error),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(service["serviceName"],
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600, fontSize: 14)),
                                    SizedBox(height: 5),
                                    Text("Price: \Rs. ${service["price"]}",
                                        style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                                    SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.access_time, color: Colors.teal, size: 14),
                                        SizedBox(width: 4),
                                        Text("${service["duration"]} hrs",
                                            style: GoogleFonts.poppins(fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

              ),

            ),
          ),
        ],
      ),
    );
  }
}
