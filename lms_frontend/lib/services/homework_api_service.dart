import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/api_config.dart';
class HomeworkApiService {

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>> createHomework({
    required String classId,
    required String title,
    String? description,
    required String dueDate,
    File? file,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse("${AppConfig.baseUrl}/homework/create");

    var request = http.MultipartRequest("POST", uri);
    request.headers['Authorization'] = "Bearer $token";

    request.fields['classId'] = classId;
    request.fields['title'] = title;
    request.fields['description'] = description ?? "";
    request.fields['dueDate'] = dueDate;

    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('audio', file.path.split('.').last),
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> fetchHomeworks({
    required String classId,
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse("${AppConfig.baseUrl}/homework/class/$classId?page=$page&limit=$limit");

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          return data["data"] ?? [];
        } else {
          throw Exception(data["message"] ?? "Failed to fetch homework");
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching homework: $e");
    }
  }

  static Future<String> downloadAudio(String fileId, String fileName) async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isDenied) {
        var status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          throw Exception("Storage permission denied");
        }
      }
    }

    final token = await _getToken();
    final url = Uri.parse("${AppConfig.baseUrl}/homework/audio/$fileId");

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {

      Directory externalDir = Directory("/storage/emulated/0/MyAppAudios");

      if (!(await externalDir.exists())) {
        await externalDir.create(recursive: true);
      }

      final filePath = "${externalDir.path}/$fileName";

      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return filePath;
    } else {
      throw Exception("Failed to download audio. Status code: ${response.statusCode}");
    }
  }

  static Future<Map<String, dynamic>> submitHomework({
    required String homeworkId,
    required File file,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse("${AppConfig.baseUrl}/homework/$homeworkId/submit");

    var request = http.MultipartRequest("POST", uri);
    request.headers['Authorization'] = "Bearer $token";

    // Add file
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType('audio', file.path.split('.').last),
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> fetchHomeworkSubmissions({
    required String homeworkId,
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse("${AppConfig.baseUrl}/homework/$homeworkId/submissions?page=$page&limit=$limit");

    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["success"] == true) {
      return data["data"] ?? [];
    } else {
      throw Exception(data["message"] ?? "Failed to fetch submissions");
    }
  }

  static Future<Map<String, dynamic>> gradeHomeworkSubmission({
    required String submissionId,
    required int grade,
    required String feedback,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse("${AppConfig.baseUrl}/homework/grade/$submissionId");

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"grade": grade, "feedback": feedback}),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> fetchMySubmission({
    required String homeworkId,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse("${AppConfig.baseUrl}/homework/$homeworkId/my-submission");

    final response = await http.get(uri, headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    });

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['success'] == true && result['data'] is List && result['data'].isNotEmpty) {
        return result['data'][0]; // Return first submission
      }
    }

    return {};
  }


}
