import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BookedServiceDetails extends StatefulWidget {
  final Map<String, dynamic> booking;

  BookedServiceDetails({required this.booking});

  @override
  _BookedServiceDetailsState createState() => _BookedServiceDetailsState();
}

class _BookedServiceDetailsState extends State<BookedServiceDetails> {
  User? _user;
  String _status = '';
  String? _bookingId;

  @override
  void initState() {
    super.initState();
    _getUser();
    _status = widget.booking['status'];
    _bookingId = widget.booking['bookingId'];
  }

  void _getUser() {
    _user = FirebaseAuth.instance.currentUser;
  }

  Future<void> _updateBookingStatus(String newStatus) async {
    if (_bookingId == null || _bookingId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Invalid booking ID.")),
      );
      return;
    }

    DatabaseReference ref = FirebaseDatabase.instance.ref("bookings").child(_bookingId!);
    try {
      await ref.update({"status": newStatus});
      setState(() {
        _status = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking status updated to $newStatus!")),
      );
      if (newStatus == 'completed') {
        await _generateInvoice();
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update booking status.")),
      );
    }
  }

  Future<void> _generateInvoice() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Invoice", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text("Booking ID: $_bookingId", style: pw.TextStyle(fontSize: 16)),
                pw.Text("Service Name: ${widget.booking['serviceName']}", style: pw.TextStyle(fontSize: 16)),
                pw.Text("Customer Name: ${widget.booking['userName']}", style: pw.TextStyle(fontSize: 16)),
                pw.Text("Booking Time: ${DateTime.fromMillisecondsSinceEpoch(widget.booking['bookingTime'])}", style: pw.TextStyle(fontSize: 16)),
                pw.Text("Status: $_status", style: pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 20),
                pw.Text("Thank you for using our service!", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/invoice_$_bookingId.pdf';
    final file = File(path);
    await file.writeAsBytes(bytes);
    await _uploadInvoice(file);
  }

  Future<void> _uploadInvoice(File file) async {
    if (_bookingId == null) return;
    final storageRef = FirebaseStorage.instance.ref().child('invoices/$_bookingId.pdf');
    final uploadTask = storageRef.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();
    DatabaseReference ref = FirebaseDatabase.instance.ref("bookings").child(_bookingId!);
    ref.update({"invoiceUrl": downloadUrl}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invoice uploaded successfully!")),
      );
    });
  }
//UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Booked Service Details", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Service Name", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(widget.booking['serviceName'], style: GoogleFonts.poppins(fontSize: 16)),
            SizedBox(height: 10),
            Text("Customer Name", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(widget.booking['userName'], style: GoogleFonts.poppins(fontSize: 16)),
            SizedBox(height: 10),
            Text("Booking Time", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(DateTime.fromMillisecondsSinceEpoch(widget.booking['bookingTime']).toString(), style: GoogleFonts.poppins(fontSize: 16)),
            SizedBox(height: 10),
            Text("Status", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: ['pending', 'in progress', 'completed'].map((String status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status, style: GoogleFonts.poppins(fontSize: 16)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _updateBookingStatus(newValue);
                }
              },
            ),
            SizedBox(height: 20),
            if (_status == 'completed')
              ElevatedButton(
                onPressed: _generateInvoice,
                child: Text("Generate Invoice", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25)),
              ),
          ],
        ),
      ),
    );
  }
}