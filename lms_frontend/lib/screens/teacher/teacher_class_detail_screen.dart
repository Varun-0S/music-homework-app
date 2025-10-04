import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../services/class_api_service.dart';
import '../../services/fee_api_service.dart';
import '../../routes.dart';
import '../../utils/logout_helper.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class TeacherClassDetailScreen extends StatefulWidget {
  Map<String, dynamic> classData;
  bool hasHomeworks;

  TeacherClassDetailScreen({
    super.key,
    required this.classData,
    required this.hasHomeworks,
  });

  @override
  State<TeacherClassDetailScreen> createState() =>
      _TeacherClassDetailScreenState();
}

class _TeacherClassDetailScreenState extends State<TeacherClassDetailScreen>
    with RouteAware {
  bool _isLoadingPayments = false;
  bool _isRefreshingClass = false;
  List<dynamic> paidStudents = [];
  List<dynamic> unpaidStudents = [];
  int totalPaid = 0;
  int totalUnpaid = 0;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Called when coming back to this screen
  @override
  void didPopNext() {
    _refreshClassDetails();
  }

  Future<void> _refreshClassDetails() async {
    setState(() => _isRefreshingClass = true);
    try {
      final updatedClass =
      await ClassApiService.getClassById(widget.classData['_id']);
      setState(() {
        widget.classData = updatedClass;
        widget.hasHomeworks = updatedClass['hasHomeworks'] ?? false;
      });
      await _fetchPayments(); // refresh payments too
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error refreshing class: $e")),
      );
    } finally {
      setState(() => _isRefreshingClass = false);
    }
  }

  Future<void> _fetchPayments() async {
    setState(() => _isLoadingPayments = true);
    try {
      final response = await FeeApiService.getClassPayments(
        classId: widget.classData['_id'],
      );

      if (response['success'] == true) {
        final data = response['data'] ?? {};
        setState(() {
          paidStudents = data['paid'] ?? [];
          unpaidStudents = data['unpaid'] ?? [];
          totalPaid = paidStudents.length;
          totalUnpaid = unpaidStudents.length;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Failed to fetch payments")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching payments: $e")),
      );
    } finally {
      setState(() => _isLoadingPayments = false);
    }
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

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeleteClass() async {
    final classId = widget.classData['_id'];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this class?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await ClassApiService.deleteClass(classId);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Class deleted successfully")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Delete failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting class: $e")),
      );
    }
  }

  Widget _buildStudentList(String title, List<dynamic> students, Color color) {
    return _buildSection(
      title,
      students.isEmpty
          ? [Text("No students", style: TextStyle(color: Colors.grey))]
          : students.map((s) {
        final name =
        s['student'] != null ? s['student']['name'] : s['name'];
        final email =
        s['student'] != null ? s['student']['email'] : s['email'];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(Icons.person, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(name ?? "")),
              Text(email ?? "", style: const TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.classData['schedule'] ?? {};
    final fee = widget.classData['fee'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classData['title'] ?? "Class Details"),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => LogoutHelper.showLogoutConfirmationDialog(context),
          ),
        ],
      ),
      body: (_isLoadingPayments || _isRefreshingClass)
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basic Info
          _buildSection("Basic Info", [
            Text(widget.classData['title'] ?? "",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.classData['description'] ?? "",
                style:
                const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            if (widget.classData['url'] != null &&
                widget.classData['url'] != "")
              Text("URL: ${widget.classData['url']}",
                  style: const TextStyle(
                      fontSize: 14, color: Colors.blue)),
          ]),

          // Schedule
          _buildSection("Schedule", [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(
                    "Start: ${formatDate(widget.classData['startDate'])}"),
                const SizedBox(width: 16),
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text("End: ${formatDate(widget.classData['endDate'])}"),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(
                    "Time: ${formatTime(schedule['startTime'], schedule['endTime'])}"),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event, size: 16),
                const SizedBox(width: 4),
                Expanded(
                    child: Text("Days: ${formatDays(schedule['days'])}")),
              ],
            ),
          ]),


          _buildSection("Fee Details", [
            Text("Amount: ₹${fee['amount'] ?? 0}",
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            Text("Frequency: ${fee['frequency'] ?? ""}",
                style: const TextStyle(fontSize: 14)),
          ]),


          _buildStudentList(
              "Paid Students ($totalPaid)", paidStudents, Colors.green),
          _buildStudentList("Unpaid Students ($totalUnpaid)",
              unpaidStudents, Colors.red),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    widget.hasHomeworks ? Routes.viewHomework : Routes.addHomework,
                    arguments: widget.classData['_id'],
                  );

                  if (result == true) {
                    setState(() {
                      widget.hasHomeworks = true;
                    });
                  }
                },
                icon: Icon(widget.hasHomeworks ? Icons.visibility : Icons.add),
                label: Text(widget.hasHomeworks ? "View Homework" : "Add Homework"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleDeleteClass,
                icon: const Icon(Icons.delete),
                label: const Text("Delete Class"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
