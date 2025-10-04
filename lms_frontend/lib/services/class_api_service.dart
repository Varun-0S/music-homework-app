import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';

class ClassApiService {


  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }


  static Future<Map<String, dynamic>> getTeacherClasses(
      {int page = 1, int limit = 10}) async {
    final token = await _getToken();
    final url = "${AppConfig.baseUrl}/teacher/classes?page=$page&limit=$limit";
    print("[GET] $url"); // Log request
    final response = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );
    print("[RESPONSE] ${response.body}");
    return jsonDecode(response.body);
  }


  static Future<Map<String, dynamic>> searchTeacherClasses(String query,
      {int page = 1, int limit = 10}) async {
    final token = await _getToken();
    final url = "${AppConfig.baseUrl}/teacher/classes/search?query=$query&page=$page&limit=$limit";
    print("[GET] $url");
    final response = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );
    print("[RESPONSE] ${response.body}");
    return jsonDecode(response.body);
  }


  static Future<Map<String, dynamic>> createClass(
      Map<String, dynamic> classData) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse("${AppConfig.baseUrl}/class/create"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(classData),
    );

    print("Create Class Response: ${response.body}");
    return jsonDecode(response.body);
  }


  static Future<Map<String, dynamic>> getStudentEnrolledClasses(
      {int page = 1, int limit = 10}) async {
    final token = await _getToken();
    final url = "${AppConfig.baseUrl}/class/my?page=$page&limit=$limit";
    print("[GET] $url");
    final response = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );
    print("[RESPONSE] ${response.body}");
    return jsonDecode(response.body);
  }


  static Future<Map<String, dynamic>> getAllClasses({
    int page = 1,
    int limit = 10,
    String? searchQuery,
  }) async {
    final token = await _getToken();
    String url = "${AppConfig.baseUrl}/class/all?page=$page&limit=$limit";
    if (searchQuery != null && searchQuery.isNotEmpty) {
      url += "&query=$searchQuery";
    }

    final response = await http.get(Uri.parse(url),
        headers: {"Authorization": "Bearer $token"});
    return jsonDecode(response.body);
  }


  static Future<Map<String, dynamic>> searchEnrolledClasses(String query,
      {int page = 1, int limit = 10}) async {
    final token = await _getToken();
    final url = "${AppConfig.baseUrl}/class/my/search?query=$query&page=$page&limit=$limit";
    print("[GET] $url");
    final response = await http.get(Uri.parse(url),
        headers: {"Authorization": "Bearer $token"});
    print("[RESPONSE] ${response.body}");
    return jsonDecode(response.body);
  }


  static Future<Map<String, dynamic>> searchAllClasses(String query,
      {int page = 1, int limit = 10}) async {
    final token = await _getToken();
    final url = "${AppConfig.baseUrl}/class/search?query=$query&page=$page&limit=$limit";
    print("[GET] $url");
    final response = await http.get(Uri.parse(url),
        headers: {"Authorization": "Bearer $token"});
    print("[RESPONSE] ${response.body}");
    return jsonDecode(response.body);
  }


  static Future<Map<String, dynamic>> enrollClass(String classId) async {
    final token = await _getToken();
    final url = "${AppConfig.baseUrl}/class/enroll";

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"classId": classId}),
    );

    print("[POST] $url");
    print("[BODY] {classId: $classId}");
    print("[RESPONSE] ${response.body}");

    return jsonDecode(response.body);
  }


  static Future<Map<String, dynamic>> getClassById(String classId) async {
    final token = await _getToken();
    final url = "${AppConfig.baseUrl}/class/$classId";

    final response = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );

    print("[GET] $url");
    print("[RESPONSE] ${response.body}");

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteClass(String classId) async {
    final token = await _getToken();
    final url = "${AppConfig.baseUrl}/class/$classId";

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("[DELETE] $url");
    print("[RESPONSE] ${response.body}");

    return jsonDecode(response.body);
  }


}
