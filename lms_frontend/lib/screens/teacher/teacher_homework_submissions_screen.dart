import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/homework_api_service.dart';
import '../../utils/logout_helper.dart';

class TeacherHomeworkSubmissionsScreen extends StatefulWidget {
  final String homeworkId;
  const TeacherHomeworkSubmissionsScreen({super.key, required this.homeworkId});

  @override
  State<TeacherHomeworkSubmissionsScreen> createState() =>
      _TeacherHomeworkSubmissionsScreenState();
}

class _TeacherHomeworkSubmissionsScreenState
    extends State<TeacherHomeworkSubmissionsScreen> {
  List<dynamic> submissions = [];
  bool isLoading = true;

  Map<String, bool> isDownloading = {};

  @override
  void initState() {
    super.initState();
    fetchSubmissions();
  }

  Future<void> fetchSubmissions() async {
    setState(() => isLoading = true);
    try {
      final data = await HomeworkApiService.fetchHomeworkSubmissions(
        homeworkId: widget.homeworkId,
      );
      setState(() {
        submissions = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> submitFeedback(String submissionId, int grade, String feedback) async {
    try {
      await HomeworkApiService.gradeHomeworkSubmission(
        submissionId: submissionId,
        grade: grade,
        feedback: feedback,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback submitted successfully")),
      );

      // Refresh list after update
      fetchSubmissions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _downloadAudio(String fileId, String title) async {
    setState(() => isDownloading[fileId] = true);
    try {
      final fileName = "$title.mp3";
      final savedPath = await HomeworkApiService.downloadAudio(fileId, fileName);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Homework Submissions"),
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
          : submissions.isEmpty
          ? const Center(child: Text("No submissions found"))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: submissions.length,
        itemBuilder: (context, index) {
          final submission = submissions[index];
          final student = submission['student'] ?? {};
          final hasFeedback = submission['feedback'] != null &&
              submission['feedback'].toString().isNotEmpty;

          final gradeController = TextEditingController();
          final feedbackController = TextEditingController();

          final audioFileId = submission['audioFileId'] ?? '';

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name'] ?? "Unknown Student",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(student['email'] ?? ""),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Audio File: submission.mp3"),
                      IconButton(
                        icon: isDownloading[audioFileId] == true
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.download),
                        onPressed: isDownloading[audioFileId] == true
                            ? null
                            : () => _downloadAudio(audioFileId, 'submission_${student['name']}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  hasFeedback
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Grade: ${submission['grade']}"),
                      Text("Feedback: ${submission['feedback']}"),
                    ],
                  )
                      : Column(
                    children: [
                      TextField(
                        controller: gradeController,
                        decoration: const InputDecoration(
                          labelText: "Grade",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: feedbackController,
                        decoration: const InputDecoration(
                          labelText: "Feedback",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          final grade = int.tryParse(gradeController.text) ?? 0;
                          final feedback = feedbackController.text.trim();
                          if (feedback.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Feedback cannot be empty")),
                            );
                            return;
                          }
                          submitFeedback(submission['_id'], grade, feedback);
                        },
                        child: const Text("Submit Feedback"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
