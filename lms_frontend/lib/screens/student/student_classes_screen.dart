import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../services/class_api_service.dart';
import '../../utils/logout_helper.dart';
import 'student_class_detail_screen.dart';

class StudentClassesScreen extends StatefulWidget {
  const StudentClassesScreen({super.key});

  @override
  State<StudentClassesScreen> createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends State<StudentClassesScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const EnrolledClassesTab(),
    const AllClassesTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: "Enrolled",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: "All Classes",
          ),
        ],
      ),
    );
  }
}

// =================== Enrolled Classes Tab ===================
class EnrolledClassesTab extends StatefulWidget {
  const EnrolledClassesTab({super.key});

  @override
  State<EnrolledClassesTab> createState() => _EnrolledClassesTabState();
}

class _EnrolledClassesTabState extends State<EnrolledClassesTab> {
  List<dynamic> enrolledClasses = [];
  bool isLoading = true;
  int currentPage = 1;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchEnrolledClasses();
  }

  Future<void> fetchEnrolledClasses() async {
    setState(() => isLoading = true);
    final response = await ClassApiService.getStudentEnrolledClasses(
      page: currentPage,
      limit: 10,
    );
    setState(() {
      enrolledClasses = response["data"] ?? [];
      isLoading = false;
    });
  }

  Future<void> searchEnrolled(String query) async {
    if (query.isEmpty) {
      fetchEnrolledClasses();
      return;
    }
    setState(() => isLoading = true);
    final response =
    await ClassApiService.searchEnrolledClasses(query, page: 1, limit: 10);
    setState(() {
      enrolledClasses = response["data"] ?? [];
      isLoading = false;
    });
  }

  String formatDate(dynamic timestamp) {
    if (timestamp == null) return "";
    int ts;
    if (timestamp is String) {
      ts = int.tryParse(timestamp) ?? 0;
    } else if (timestamp is int) {
      ts = timestamp;
    } else {
      return "";
    }
    final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String formatTime(String? startTime, String? endTime) {
    if (startTime == null || endTime == null) return "";
    try {
      final start = DateFormat("HH:mm").parse(startTime);
      final end = DateFormat("HH:mm").parse(endTime);
      final formattedStart = DateFormat.jm().format(start);
      final formattedEnd = DateFormat.jm().format(end);
      return "$formattedStart - $formattedEnd";
    } catch (e) {
      return "$startTime - $endTime";
    }
  }

  String formatDays(List<dynamic>? days) {
    if (days == null || days.isEmpty) return "";
    return days.join(", ");
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Enrolled Classes"),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => LogoutHelper.showLogoutConfirmationDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search enrolled classes...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    searchQuery = "";
                    fetchEnrolledClasses();
                  },
                ),
                filled: true,
                fillColor: AppColors.secondaryColor.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                searchQuery = value;
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce =
                    Timer(const Duration(milliseconds: 500), () {
                      searchEnrolled(searchQuery);
                    });
              },
            ),
            const SizedBox(height: 12),
            // List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : enrolledClasses.isEmpty
                  ? const Center(child: Text("No classes found"))
                  : ListView.builder(
                itemCount: enrolledClasses.length,
                itemBuilder: (context, index) {
                  final cls = enrolledClasses[index];
                  return _buildClassCard(cls);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(dynamic cls) {
    return InkWell(
      onTap: () async {
        try {
          final response = await ClassApiService.getClassById(cls["_id"]);
          if (response["success"] == true) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentClassDetailScreen(
                  classData: response["data"]["class"],
                  hasHomeworks: response["data"]["hasHomeworks"],
                  isEnrolled: true,
                    isFeePaid: response["data"]["isFeePaid"]
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response["message"] ?? "Failed to load class")),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.class_,
                  size: 40,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cls['title'] ?? "",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(cls['description'] ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text("Start: ${formatDate(cls['startDate'])}",
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 10),
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text("End: ${formatDate(cls['endDate'])}",
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "Time: ${formatTime(cls['schedule']?['startTime'], cls['schedule']?['endTime'])}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "Days: ${formatDays(cls['schedule']?['days'])}",
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: const Chip(
                        label: Text(
                          "Enrolled",
                          style: TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.greenAccent,
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
  }

}

// =================== All Classes Tab ===================
class AllClassesTab extends StatefulWidget {
  const AllClassesTab({super.key});

  @override
  State<AllClassesTab> createState() => _AllClassesTabState();
}

class _AllClassesTabState extends State<AllClassesTab> {
  List<dynamic> allClasses = [];
  bool isLoading = true;
  String searchQuery = "";
  int currentPage = 1;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchAllClasses();
  }

  Future<void> fetchAllClasses() async {
    setState(() => isLoading = true);
    final response = await ClassApiService.getAllClasses(
      page: currentPage,
      limit: 10,
    );
    setState(() {
      allClasses = response["data"] ?? [];
      isLoading = false;
    });
  }

  Future<void> searchAll(String query) async {
    if (query.isEmpty) {
      fetchAllClasses();
      return;
    }
    setState(() => isLoading = true);
    final response =
    await ClassApiService.searchAllClasses(query, page: 1, limit: 10);
    setState(() {
      allClasses = response["data"] ?? [];
      isLoading = false;
    });
  }

  Future<void> enrollInClass(String classId, int index) async {
    try {
      final response = await ClassApiService.enrollClass(classId);
      if (response["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enrolled successfully!")),
        );

        // Update the class locally to show URL and hide enroll button
        setState(() {
          allClasses[index]["isEnrolled"] = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response["message"] ?? "Failed to enroll")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String formatDate(dynamic timestamp) {
    if (timestamp == null) return "";
    int ts;
    if (timestamp is String) {
      ts = int.tryParse(timestamp) ?? 0;
    } else if (timestamp is int) {
      ts = timestamp;
    } else {
      return "";
    }
    final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String formatTime(String? startTime, String? endTime) {
    if (startTime == null || endTime == null) return "";
    try {
      final start = DateFormat("HH:mm").parse(startTime);
      final end = DateFormat("HH:mm").parse(endTime);
      final formattedStart = DateFormat.jm().format(start);
      final formattedEnd = DateFormat.jm().format(end);
      return "$formattedStart - $formattedEnd";
    } catch (e) {
      return "$startTime - $endTime";
    }
  }

  String formatDays(List<dynamic>? days) {
    if (days == null || days.isEmpty) return "";
    return days.join(", ");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Classes"),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => LogoutHelper.showLogoutConfirmationDialog(context),
          ),
        ],

      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search all classes...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    searchQuery = "";
                    fetchAllClasses();
                  },
                ),
                filled: true,
                fillColor: AppColors.secondaryColor.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                searchQuery = value;
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  searchAll(searchQuery);
                });
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : allClasses.isEmpty
                  ? const Center(child: Text("No classes found"))
                  : ListView.builder(
                itemCount: allClasses.length,
                itemBuilder: (context, index) {
                  final cls = allClasses[index];
                  final bool isEnrolled = cls["isEnrolled"] == true;
                  return _buildClassCard(cls, isEnrolled, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(dynamic cls, bool isEnrolled, int index) {
    return InkWell(
      onTap: () async {
        final response = await ClassApiService.getClassById(cls["_id"]);
        if (response["success"] == true) {
          // Navigate to detail screen and wait for return
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentClassDetailScreen(
                classData: response["data"]["class"],
                hasHomeworks: response["data"]["hasHomeworks"],
                isEnrolled: isEnrolled,
                  isFeePaid: response["data"]["isFeePaid"]
              ),
            ),
          );

          // Refresh the list after coming back
          fetchAllClasses();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response["message"] ?? "Failed to load class"),
            ),
          );
        }
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.class_,
                  size: 40,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cls['title'] ?? "",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(cls['description'] ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text("Start: ${formatDate(cls['startDate'])}",
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 10),
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text("End: ${formatDate(cls['endDate'])}",
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "Time: ${formatTime(cls['schedule']?['startTime'], cls['schedule']?['endTime'])}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "Days: ${formatDays(cls['schedule']?['days'])}",
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: isEnrolled
                          ? const Chip(
                        label: Text(
                          "Enrolled",
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.greenAccent,
                      )
                          : ElevatedButton(
                        onPressed: () =>
                            enrollInClass(cls["_id"], index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Enroll",
                            style: TextStyle(color: Colors.white)),
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
  }
}
