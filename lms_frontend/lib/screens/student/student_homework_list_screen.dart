import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/colors.dart';
import '../../services/homework_api_service.dart';
import '../../utils/logout_helper.dart';

class StudentHomeworkListScreen extends StatefulWidget {
  final String classId;
  const StudentHomeworkListScreen({super.key, required this.classId});

  @override
  State<StudentHomeworkListScreen> createState() =>
      _StudentHomeworkListScreenState();
}

class _StudentHomeworkListScreenState extends State<StudentHomeworkListScreen> {
  bool _isLoading = true;
  List<dynamic> homeworkList = [];
  Map<String, bool> isDownloading = {};
  Map<String, bool> isUploading = {};
  Map<String, File?> selectedFile = {}; // Track selected file per homework

  @override
  void initState() {
    super.initState();
    _fetchHomeworkList();
  }

  Future<void> _fetchHomeworkList() async {
    setState(() => _isLoading = true);
    try {
      final data = await HomeworkApiService.fetchHomeworks(
        classId: widget.classId,
      );
      setState(() => homeworkList = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String formatDate(dynamic dateString) {
    if (dateString == null) return "";
    try {
      final date = DateTime.parse(dateString);
      return DateFormat("yyyy-MM-dd").format(date);
    } catch (e) {
      return dateString.toString();
    }
  }

  Future<void> _downloadAudio(String fileId, String title) async {
    setState(() => isDownloading[fileId] = true);
    try {
      final fileName = "$title.mp3";
      final savedPath =
      await HomeworkApiService.downloadAudio(fileId, fileName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Audio downloaded to $savedPath")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    } finally {
      setState(() => isDownloading[fileId] = false);
    }
  }

  Future<void> _pickFile(String homeworkId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      if (result != null && result.files.single.path != null) {
        setState(() => selectedFile[homeworkId] = File(result.files.single.path!));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to pick audio file")),
      );
    }
  }

  Future<void> _submitHomework(String homeworkId) async {
    final file = selectedFile[homeworkId];
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an audio file to submit")),
      );
      return;
    }

    setState(() => isUploading[homeworkId] = true);
    try {
      final result = await HomeworkApiService.submitHomework(
        homeworkId: homeworkId,
        file: file,
      );
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Homework submitted successfully")),
        );
        selectedFile[homeworkId] = null;
        _fetchHomeworkList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Submit failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submit failed: $e")),
      );
    } finally {
      setState(() => isUploading[homeworkId] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Homework"),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => LogoutHelper.showLogoutConfirmationDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : homeworkList.isEmpty
          ? const Center(child: Text("No homework available"))
          : RefreshIndicator(
        onRefresh: _fetchHomeworkList,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: homeworkList.length,
          itemBuilder: (context, index) {
            final hw = homeworkList[index];
            final bool isSubmitted = hw['isHomeworkSubmitted'] ?? false;
            final String? audioFileId = hw['referenceAudioFileId'];
            final homeworkId = hw['_id'];
            final File? file = selectedFile[homeworkId];

            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment,
                            color: AppColors.primaryColor, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                hw['title'] ?? "",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Teacher: ${hw['teacher']?['name'] ?? 'N/A'}",
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Due: ${formatDate(hw['dueDate'])}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        if (isSubmitted)
                          Chip(
                            label: const Text("Submitted",
                                style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.green,
                          )
                        else if (file == null)
                          ElevatedButton(
                            onPressed: () => _pickFile(homeworkId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Select Audio"),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (hw['description'] != null)
                      Text(hw['description'],
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    if (audioFileId != null)
                      Row(
                        children: [
                          isDownloading[audioFileId] == true
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : GestureDetector(
                            onTap: () => _downloadAudio(
                                audioFileId, hw['title'] ?? 'audio'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.download,
                                      color: AppColors.primaryColor,
                                      size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    "Reference Audio",
                                    style: TextStyle(
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    // File upload section
                    if (file != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                file.path.split('/').last,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            isUploading[homeworkId] == true
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : ElevatedButton.icon(
                              onPressed: () => _submitHomework(homeworkId),
                              icon: const Icon(Icons.upload_file),
                              label: const Text("Submit"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (isSubmitted) ...[
                      const SizedBox(height: 12),
                      FutureBuilder<Map<String, dynamic>>(
                        future: HomeworkApiService.fetchMySubmission(
                            homeworkId: homeworkId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator(strokeWidth: 2));
                          }
                          final submission = snapshot.data ?? {};
                          if (submission.isEmpty) return const SizedBox.shrink();

                          final feedback = submission['feedback'] ?? "";
                          final grade = submission['grade'];

                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blueGrey.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.feedback,
                                        color: AppColors.primaryColor, size: 20),
                                    SizedBox(width: 6),
                                    Text(
                                      "Teacher Feedback",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  feedback.isNotEmpty ? feedback : "No feedback yet",
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.black87),
                                ),
                                const Divider(height: 16, thickness: 0.8),
                                Row(
                                  children: [
                                    const Icon(Icons.grade,
                                        color: Colors.orangeAccent, size: 20),
                                    const SizedBox(width: 6),
                                    const Text(
                                      "Grade: ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      grade != null ? grade.toString() : "Not graded",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: grade != null ? Colors.green : Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
