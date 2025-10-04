import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../services/class_api_service.dart';
import '../../services/fee_api_service.dart';
import '../../routes.dart';
import '../../utils/logout_helper.dart';


class StudentClassDetailScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  final bool hasHomeworks;
  final bool isEnrolled;
  final bool isFeePaid;

  const StudentClassDetailScreen({
    super.key,
    required this.classData,
    required this.hasHomeworks,
    this.isEnrolled = false,
    this.isFeePaid = false,
  });

  @override
  State<StudentClassDetailScreen> createState() =>
      _StudentClassDetailScreenState();
}

class _StudentClassDetailScreenState extends State<StudentClassDetailScreen> {
  late bool _isEnrolled;
  bool _isPaying = false;
  bool _isFeePaid = false;

  @override
  void initState() {
    super.initState();
    _isEnrolled = widget.isEnrolled;

    final feeData = widget.classData['fee'] ?? {};
    _isFeePaid = feeData['isFeePaid'] ?? widget.isFeePaid;
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

  Future<void> _enrollClass() async {
    try {
      final response =
      await ClassApiService.enrollClass(widget.classData["_id"]);
      if (response["success"] == true) {
        setState(() {
          _isEnrolled = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enrolled successfully!")),
        );
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

  Future<void> _payFee() async {
    final fee = widget.classData['fee'] ?? {};
    final amount = (fee['amount'] ?? 0).toDouble();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pay Fee"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Fee Amount: ₹${amount.toStringAsFixed(2)}"),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isPaying = true);

              final response = await FeeApiService.payFee(
                classId: widget.classData["_id"],
                amountPaid: amount,
                description: descriptionController.text.trim(),
              );

              setState(() => _isPaying = false);

              if (response["success"] == true) {
                setState(() {
                  _isFeePaid = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Payment successful")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(response["message"] ?? "Payment failed")),
                );
              }
            },
            child: const Text("Pay Now"),
          ),
        ],
      ),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basic Info Card
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Basic Info",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Title: ${widget.classData['title'] ?? ""}",
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 6),
                  Text("Description: ${widget.classData['description'] ?? ""}",
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 6),
                  if (_isEnrolled &&
                      widget.classData['url'] != null &&
                      widget.classData['url'].isNotEmpty)
                    Text("URL: ${widget.classData['url']}",
                        style: const TextStyle(
                            fontSize: 14, color: Colors.blue)),
                ],
              ),
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Schedule",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14),
                      const SizedBox(width: 4),
                      Text("Start: ${formatDate(widget.classData['startDate'])}"),
                      const SizedBox(width: 12),
                      const Icon(Icons.calendar_today, size: 14),
                      const SizedBox(width: 4),
                      Text("End: ${formatDate(widget.classData['endDate'])}"),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "Time: ${formatTime(schedule['startTime'], schedule['endTime'])}",
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.event, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Days: ${formatDays(schedule['days'])}",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Fee Details",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                      "Amount: ₹${(fee['amount'] ?? 0).toDouble().toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 6),
                  Text("Frequency: ${fee['frequency'] ?? ""}",
                      style: const TextStyle(fontSize: 14)),
                  if (_isEnrolled && fee.isNotEmpty && !_isFeePaid)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ElevatedButton(
                        onPressed: _payFee,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.payment, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              "Pay Fee ₹${fee['amount']?.toStringAsFixed(2) ?? "0.00"}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_isFeePaid)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "Fee Paid ✅",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isEnrolled
          ? (widget.hasHomeworks
          ? Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(
              context,
              Routes.studentHomeworkList,
              arguments: widget.classData["_id"],
            );
          },
          icon: const Icon(Icons.assignment),
          label: const Text("View Homework"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      )
          : null)
          : Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _enrollClass,
          icon: const Icon(Icons.school),
          label: const Text("Enroll"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
