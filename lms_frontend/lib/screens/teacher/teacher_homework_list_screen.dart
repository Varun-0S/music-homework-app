import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../services/homework_api_service.dart';
import '../../routes.dart';
import '../../utils/logout_helper.dart';

class TeacherHomeworkListScreen extends StatefulWidget {
  final String classId;
  const TeacherHomeworkListScreen({super.key, required this.classId});

  @override
  State<TeacherHomeworkListScreen> createState() =>
      _TeacherHomeworkListScreenState();
}

class _TeacherHomeworkListScreenState extends State<TeacherHomeworkListScreen> {
  List<dynamic> homeworks = [];
  bool isLoading = true;
  int currentPage = 1;
  int limit = 10;

  @override
  void initState() {
    super.initState();
    fetchHomeworks();
  }

  Future<void> fetchHomeworks() async {
    setState(() => isLoading = true);
    try {
      final data = await HomeworkApiService.fetchHomeworks(
        classId: widget.classId,
        page: currentPage,
        limit: limit,
      );
      setState(() {
        homeworks = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  String formatDate(String? isoDate) {
    if (isoDate == null) return "";
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return isoDate ?? "";
    }
  }

  Color dueDateColor(String? isoDate) {
    if (isoDate == null) return Colors.grey;
    final now = DateTime.now();
    final dueDate = DateTime.tryParse(isoDate);
    if (dueDate == null) return Colors.grey;

    if (dueDate.isBefore(now)) return Colors.redAccent; // overdue
    if (dueDate.day == now.day &&
        dueDate.month == now.month &&
        dueDate.year == now.year) return Colors.orangeAccent; // today
    return Colors.green; // upcoming
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Class Homeworks"),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => LogoutHelper.showLogoutConfirmationDialog(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : homeworks.isEmpty
          ? const Center(child: Text("No homework found"))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: homeworks.length,
        itemBuilder: (context, index) {
          final hw = homeworks[index];
          final dueColor = dueDateColor(hw['dueDate']);
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      Colors.deepPurpleAccent
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              title: Text(hw['title'] ?? "",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hw['description'] ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                        const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.date_range, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "Due: ${formatDate(hw['dueDate'])}",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: dueColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(

                    ),
                  ],
                ),
              ),
              trailing: hw['referenceAudioFileId'] != null
                  ? const Icon(
                Icons.audiotrack,
                color: AppColors.primaryColor,
                size: 28,
              )
                  : null,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  Routes.homeworkSubmissions,
                  arguments: hw['_id'] as String, // must be string id
                );
              },
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to AddHomeworkScreen using named route
          final added = await Navigator.pushNamed(
            context,
            Routes.addHomework,
            arguments: widget.classId,
          );

          // Refresh list if homework was added
          if (added == true) {
            fetchHomeworks();
          }
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),

    );
  }
}
