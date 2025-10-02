import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'doctor/doctor_detail_screen.dart'; // Import the new doctor detail screen

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  String? _filterSpecialization;
  String? _filterHospital;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }



  void _viewDoctorDetails(UserModel doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorDetailScreen(doctor: doctor),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book an Appointment"),
        actions: [
          // Filter button
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value.startsWith("Spec:")) {
                  _filterSpecialization = value.substring(5);
                  _filterHospital = null;
                } else if (value.startsWith("Hosp:")) {
                  _filterHospital = value.substring(5);
                  _filterSpecialization = null;
                } else {
                  _filterSpecialization = null;
                  _filterHospital = null;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "All", child: Text("All Doctors")),
              const PopupMenuDivider(),
              const PopupMenuItem(value: "Spec:Gynecologist", child: Text("Gynecologist")),
              const PopupMenuItem(value: "Spec:Medicine", child: Text("Medicine")),
              const PopupMenuItem(value: "Spec:Orthopedic", child: Text("Orthopedic")),
              const PopupMenuDivider(),
              const PopupMenuItem(value: "Hosp:General Hospital", child: Text("General Hospital")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search doctors, specialization...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: FirestoreService().getAllDoctors(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No doctors available."));
                
                // Filtering and searching logic
                var doctors = snapshot.data!;
                if (_filterSpecialization != null) {
                  doctors = doctors.where((d) => d.specialization == _filterSpecialization).toList();
                }
                if (_filterHospital != null) {
                  doctors = doctors.where((d) => d.hospitalName == _filterHospital).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  doctors = doctors.where((d) {
                    final name = d.name.toLowerCase();
                    final spec = (d.specialization ?? "").toLowerCase();
                    final hospital = (d.hospitalName ?? "").toLowerCase();


                    return name.contains(_searchQuery) || spec.contains(_searchQuery) || hospital.contains(_searchQuery);
                  }).toList();
                }

                if (doctors.isEmpty) {
                  return const Center(child: Text("No doctors found matching your criteria."));
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    return _buildDoctorCard(doctor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

Widget _buildDoctorCard(UserModel doctor) {
    // Wrap the entire Container with a GestureDetector
    return GestureDetector(
      // Set the onTap callback to call your function
      onTap: () => _viewDoctorDetails(doctor),
      child: Container(
        height: 140,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color.fromARGB(255, 84, 151, 218), Color.fromARGB(255, 45, 150, 255)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                top: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20), 
                    bottomRight: Radius.circular(20)
                  ),
                  child: doctor.avatarUrl != null
                      ? Image.network(
                          doctor.avatarUrl!, 
                          width: 110, 
                          fit: BoxFit.cover, 
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person, 
                            size: 80, 
                            color: Colors.white54
                          )
                        )
                      : const SizedBox(
                          width: 110, 
                          child: Icon(
                            Icons.medical_services_outlined, 
                            size: 80, 
                            color: Colors.white54
                          )
                        ),
                ),
              ),
              Positioned.fill(
                right: 110,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Dr. ${doctor.name}", 
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 18
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.specialization ?? "Specialist", 
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8), 
                          fontSize: 14
                        )
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.hospitalName ?? "Clinic", 
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6), 
                          fontSize: 12
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Rating display
                      Row(
                        children: [
                          const Icon(
                            Icons.star, 
                            color: Colors.amber, 
                            size: 16
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${doctor.averageRating.toStringAsFixed(1)} (${doctor.totalReviews})",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}