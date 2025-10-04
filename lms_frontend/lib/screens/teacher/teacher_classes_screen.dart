import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../services/class_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/logout_helper.dart';
import 'add_class_screen.dart';
import 'teacher_class_detail_screen.dart';

class TeacherClassesScreen extends StatefulWidget {
  const TeacherClassesScreen({super.key});

  @override
  State<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends State<TeacherClassesScreen> {
  List<dynamic> classes = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  int limit = 10;
  String role = "";
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    loadClasses();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100 &&
          !isLoadingMore &&
          hasMore) {
        loadMoreClasses();
      }
    });
  }

  Future<void> loadClasses({int page = 1}) async {
    setState(() {
      isLoading = true;
      currentPage = page;
    });

    final prefs = await SharedPreferences.getInstance();
    role = prefs.getString('userRole') ?? "student";

    Map<String, dynamic> fetchedData;
    if (role == "teacher") {
      fetchedData =
      await ClassApiService.getTeacherClasses(page: page, limit: limit);
    } else {
      fetchedData = await ClassApiService.getStudentEnrolledClasses(
          page: page, limit: limit);
    }

    setState(() {
      classes = fetchedData['data'] ?? [];
      hasMore = fetchedData['pagination'] != null &&
          currentPage < (fetchedData['pagination']['totalPages'] ?? 1);
      isLoading = false;
    });
  }

  Future<void> loadMoreClasses() async {
    if (!hasMore) return;

    setState(() => isLoadingMore = true);
    currentPage++;

    Map<String, dynamic> fetchedData;
    if (role == "teacher") {
      fetchedData =
      await ClassApiService.getTeacherClasses(page: currentPage, limit: limit);
    } else {
      fetchedData = await ClassApiService.getStudentEnrolledClasses(
          page: currentPage, limit: limit);
    }

    setState(() {
      classes.addAll(fetchedData['data'] ?? []);
      hasMore = fetchedData['pagination'] != null &&
          currentPage < (fetchedData['pagination']['totalPages'] ?? 1);
      isLoadingMore = false;
    });
  }

  Future<void> searchClasses(String query) async {
    if (query.isEmpty) {
      loadClasses();
      return;
    }

    setState(() {
      isLoading = true;
      currentPage = 1;
      hasMore = true;
    });

    Map<String, dynamic> searchData;
    if (role == "teacher") {
      searchData = await ClassApiService.searchTeacherClasses(query,
          page: currentPage, limit: limit);
    } else {
      searchData = await ClassApiService.searchAllClasses(query,
          page: currentPage, limit: limit);
    }

    setState(() {
      classes = searchData['data'] ?? [];
      hasMore = searchData['pagination'] != null &&
          currentPage < (searchData['pagination']['totalPages'] ?? 1);
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
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
        title: Text(role == "teacher" ? "My Classes (Teacher)" : "My Classes"),
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
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search classes...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    searchQuery = "";
                    loadClasses();
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
                  searchClasses(searchQuery);
                });
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : classes.isEmpty
                  ? const Center(child: Text("No classes found"))
                  : ListView.builder(
                controller: _scrollController,
                itemCount: classes.length + (isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= classes.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                          child: CircularProgressIndicator()),
                    );
                  }
                  final cls = classes[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final response = await ClassApiService.getClassById(cls["_id"]);

                        if (response["success"]) {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TeacherClassDetailScreen(
                                classData: response["data"]["class"],
                                hasHomeworks: response["data"]["hasHomeworks"],
                              ),
                            ),
                          );

                          if (result == true) {
                            loadClasses();
                          }
                        }
                      },
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
                                  Text(
                                    cls['title'] ?? "",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cls['description'] ?? "",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Start: ${formatDate(cls['startDate'])}",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.calendar_today,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        "End: ${formatDate(cls['endDate'])}",
                                        style: const TextStyle(fontSize: 12),
                                      ),
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
          ],
        ),
      ),
      floatingActionButton: role == "teacher"
          ? FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddClassScreen()),
          );
          if (added == true) {
            loadClasses();
          }
        },
      )
          : null,
    );
  }
}
