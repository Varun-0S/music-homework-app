import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lms_frontend/services/fee_api_service.dart';
import '../../services/class_api_service.dart';
import '../../constants/colors.dart';
import '../../utils/logout_helper.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<String> _selectedDays = [];
  String _feeFrequency = "weekly";

  bool isLoading = false;

  final List<String> daysOfWeek = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          if (_endTime != null) {
            final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
            final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
            if (endMinutes - startMinutes < 30) {
              final newEnd = startMinutes + 30;
              _endTime = TimeOfDay(hour: newEnd ~/ 60, minute: newEnd % 60);
            }
          }
        } else {
          if (_startTime != null) {
            final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
            final endMinutes = picked.hour * 60 + picked.minute;
            if (endMinutes - startMinutes < 30) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("End time must be at least 30 minutes after start time")),
              );
              return;
            }
          }
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _startDate == null ||
        _endDate == null ||
        _startTime == null ||
        _endTime == null ||
        _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End date cannot be before start date")),
      );
      return;
    }

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    if (endMinutes - startMinutes < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Time gap must be at least 30 minutes")),
      );
      return;
    }

    setState(() => isLoading = true);

    final payload = {
      "title": _titleController.text.trim(),
      "description": _descriptionController.text.trim(),
      "url": _urlController.text.trim(),
      "startDate": (_startDate!.millisecondsSinceEpoch ~/ 1000).toString(),
      "endDate": (_endDate!.millisecondsSinceEpoch ~/ 1000).toString(),
      "schedule": {
        "days": _selectedDays,
        "startTime": "${_startTime!.hour.toString().padLeft(2,'0')}:${_startTime!.minute.toString().padLeft(2,'0')}",
        "endTime": "${_endTime!.hour.toString().padLeft(2,'0')}:${_endTime!.minute.toString().padLeft(2,'0')}"
      },
      "fee":{
        "amount": double.tryParse(_amountController.text.trim()) ?? 0,
        "frequency": _feeFrequency
      }
    };

    final response = await ClassApiService.createClass(payload);

    if (response['success'] == true) {
      final classId = response['data']['_id'];

      final feePayload = {
        "classId": classId,
        "amount": double.tryParse(_amountController.text.trim()) ?? 0,
        "frequency": _feeFrequency,
      };

      final feeResponse = await FeeApiService.setClassFee(feePayload);

      setState(() => isLoading = false);

      if (feeResponse['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Class and Fee set successfully")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Class created but fee not set: ${feeResponse['message']}")),
        );
      }
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? "Failed to create class")),
      );
    }
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

  Widget _outlinedButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: AppColors.primaryColor),
      ),
      icon: Icon(icon, color: AppColors.primaryColor),
      label: Text(label, style: TextStyle(color: AppColors.primaryColor)),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Class"),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => LogoutHelper.showLogoutConfirmationDialog(context),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection("Basic Info", [
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration("Class Title"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration("Description"),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlController,
                decoration: _inputDecoration("Class URL"),
              ),
            ]),

            _buildSection("Schedule", [
              Row(
                children: [
                  Expanded(
                    child: _outlinedButton(
                      label: _startDate == null
                          ? "Start Date"
                          : DateFormat("yyyy-MM-dd").format(_startDate!),
                      icon: Icons.calendar_today,
                      onPressed: () => _pickDate(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _outlinedButton(
                      label: _endDate == null
                          ? "End Date"
                          : DateFormat("yyyy-MM-dd").format(_endDate!),
                      icon: Icons.calendar_today,
                      onPressed: () => _pickDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _outlinedButton(
                      label: _startTime == null
                          ? "Start Time"
                          : _startTime!.format(context),
                      icon: Icons.access_time,
                      onPressed: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _outlinedButton(
                      label: _endTime == null
                          ? "End Time"
                          : _endTime!.format(context),
                      icon: Icons.access_time,
                      onPressed: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: daysOfWeek.map((day) {
                  final selected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: selected,
                    selectedColor: AppColors.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppColors.primaryColor,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ]),

            _buildSection("Fee Details", [
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Fee Amount"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _feeFrequency,
                items: ["daily", "weekly", "monthly", "yearly"]
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => _feeFrequency = v!),
                decoration: _inputDecoration("Fee Frequency"),
              ),
            ]),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text("Create Class"),
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
