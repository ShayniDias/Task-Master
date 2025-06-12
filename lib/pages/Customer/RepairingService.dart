import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import 'package:taskmaster/pages/Customer/Details/RepairingServiceDetails.dart';

class RepairingServices extends StatefulWidget {
  @override
  _RepairingServicesState createState() => _RepairingServicesState();
}

class _RepairingServicesState extends State<RepairingServices> {
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> filteredServices = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  String selectedFilter = 'rating_high';

  final Map<String, String> filterOptions = {
    'rating_high': 'Rating: High to Low',
    'rating_low': 'Rating: Low to High',
    'name_asc': 'Name: A-Z',
    'name_desc': 'Name: Z-A',
  };

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
              if (serviceDetails["serviceType"] == "Repairing service") {
                double averageRating = 0.0;
                if (serviceDetails["reviews"] != null) {
                  final reviews = serviceDetails["reviews"] as Map<dynamic, dynamic>;
                  double totalRating = 0.0;
                  int reviewCount = 0;
                  reviews.forEach((reviewId, reviewDetails) {
                    totalRating += (reviewDetails["rating"] as num).toDouble();
                    reviewCount++;
                  });
                  averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;
                }
                tempList.add({
                  "serviceId": serviceId,
                  ...serviceDetails,
                  "averageRating": averageRating
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
        filterServices(''); // Apply initial sorting
      } else {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  void filterServices(String query) {
    setState(() {
      // Apply search filter
      if (query.isEmpty) {
        filteredServices = List.from(services);
      } else {
        filteredServices = services
            .where((service) =>
            service["serviceName"].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }

      // Apply sorting based on selected filter
      switch (selectedFilter) {
        case 'rating_high':
          filteredServices.sort((a, b) =>
              (b["averageRating"] as double).compareTo(a["averageRating"] as double));
          break;
        case 'rating_low':
          filteredServices.sort((a, b) =>
              (a["averageRating"] as double).compareTo(b["averageRating"] as double));
          break;
        case 'name_asc':
          filteredServices.sort((a, b) {
            String nameA = a["serviceName"].toString().toLowerCase();
            String nameB = b["serviceName"].toString().toLowerCase();
            return nameA.compareTo(nameB);
          });
          break;
        case 'name_desc':
          filteredServices.sort((a, b) {
            String nameA = a["serviceName"].toString().toLowerCase();
            String nameB = b["serviceName"].toString().toLowerCase();
            return nameB.compareTo(nameA);
          });
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Repairing Services",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: DropdownButtonFormField<String>(
              value: selectedFilter,
              items: filterOptions.entries
                  .map((entry) => DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value, style: GoogleFonts.poppins()),
              ))
                  .toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedFilter = newValue;
                  });
                  filterServices(searchController.text);
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              style: GoogleFonts.poppins(color: Colors.black),
              dropdownColor: Colors.white,
              isExpanded: true,
            ),
          ),
          isLoading
              ? Expanded(
              child: Center(child: CircularProgressIndicator(color: Colors.teal)))
              : Expanded(
            child: filteredServices.isEmpty
                ? Center(
                child: Text("No Repairing Services Found",
                    style: GoogleFonts.poppins()))
                : Padding(
              padding: const EdgeInsets.all(10.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                  MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio:
                  MediaQuery.of(context).size.width > 600 ? 0.8 : 0.9,
                ),
                itemCount: filteredServices.length,
                itemBuilder: (context, index) {
                  var service = filteredServices[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RepairingServiceDetails(service: service),
                        ),
                      );
                    },
                    child: FadeInUp(
                      duration:
                      Duration(milliseconds: 300 + (index * 100)),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(15)),
                                child: CachedNetworkImage(
                                  imageUrl: service["imageUrl"],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Center(
                                          child:
                                          CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.center,
                                children: [
                                  Text(service["serviceName"],
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  SizedBox(height: 5),
                                  Text("Price: Rs. ${service["price"]}",
                                      style: GoogleFonts.poppins(
                                          color: Colors.grey,
                                          fontSize: 12)),
                                  SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.access_time,
                                          color: Colors.teal, size: 14),
                                      SizedBox(width: 4),
                                      Text("${service["duration"]} hrs",
                                          style: GoogleFonts.poppins(
                                              fontSize: 12)),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: List.generate(
                                      5,
                                          (index) => Icon(
                                        index <
                                            (service["averageRating"]
                                            as double)
                                                .round()
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
