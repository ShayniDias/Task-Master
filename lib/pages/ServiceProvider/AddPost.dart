import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class AddPost extends StatefulWidget {
  @override
  _AddPostState createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  File? _imageFile;
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  String? _selectedServiceType;
  bool _isLoading = false;

  final List<String> _serviceTypes = [
    'Cleaning service',
    'Repairing service',
    'Painting service',
  ];

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitPost() async {
    if (!_validateForm()) return;
    if (_imageFile == null) return;

    setState(() => _isLoading = true);

    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload image and get URL
      final String imageUrl = await _uploadImage(_imageFile!);

      // Create post data
      final String serviceId = _uuid.v4();
      final Map<String, dynamic> postData = {
        'serviceId': serviceId,
        'companyId': user.uid,
        'serviceName': _serviceNameController.text.trim(),
        'serviceType': _selectedServiceType,
        'description': _descriptionController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'email': _emailController.text.trim(),
        'price': _priceController.text.trim(),
        'duration': _durationController.text.trim(),
        'imageUrl': imageUrl,
        'createdAt': ServerValue.timestamp,
        'accessToken': _uuid.v4(),
      };

      // Save to database
      await _databaseRef
          .child('companies/${user.uid}/services/$serviceId')
          .set(postData);

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service published successfully!')),
      );
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _uploadImage(File image) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child('service_images/$fileName');
      final UploadTask uploadTask = storageRef.putFile(image);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Image upload failed: ${e.toString()}');
    }
  }

  bool _validateForm() {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image')),
      );
      return false;
    }
    if (_selectedServiceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select service type')),
      );
      return false;
    }
    if (_serviceNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter service name')),
      );
      return false;
    }
    return true;
  }
//after published
  void _resetForm() {
    setState(() {
      _imageFile = null;
      _selectedServiceType = null;
    });
    _serviceNameController.clear();
    _descriptionController.clear();
    _whatsappController.clear();
    _emailController.clear();
    _priceController.clear();
    _durationController.clear();
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedServiceType,
      decoration: InputDecoration(
        labelText: 'Service Type',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: _serviceTypes.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedServiceType = newValue;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please login as a service provider',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Create New Service",
          style: GoogleFonts.poppins(),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Upload Section
            GestureDetector(
              onTap: _pickImage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blueAccent,
                    width: 2,
                  ),
                ),
                child: _imageFile == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt,
                        size: 40, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      'Upload Service Image',
                      style: GoogleFonts.poppins(
                        color: Colors.blue,
                      ),
                    ),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imageFile!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form Fields
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInputField(
                      label: 'Service Name',
                      icon: Icons.work_outline,
                      controller: _serviceNameController,
                      hint: 'Enter service name',
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Description',
                      icon: Icons.description,
                      controller: _descriptionController,
                      hint: 'Describe your service...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'WhatsApp Number',
                      icon: Icons.phone,
                      controller: _whatsappController,
                      hint: 'Enter WhatsApp number',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Email',
                      icon: Icons.email,
                      controller: _emailController,
                      hint: 'Enter contact email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'Price',
                            icon: Icons.attach_money,
                            controller: _priceController,
                            hint: 'Enter price',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            label: 'Duration',
                            icon: Icons.timer,
                            controller: _durationController,
                            hint: 'e.g., 2 hours',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitPost,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                    Colors.blueAccent.withOpacity(0.6)),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 16)),
                shadowColor: MaterialStateProperty.all(
                    Colors.blueAccent.withOpacity(0.6)),
                elevation: MaterialStateProperty.all(6),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.6),
                      offset: const Offset(4, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: null,
                  child: Container(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.publish,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Publish Service',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
