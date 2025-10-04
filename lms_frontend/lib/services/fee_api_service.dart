import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';

class FeeApiService {

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>> setClassFee(Map<String, dynamic> payload) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/fee/class'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> payFee({
    required String classId,
    required double amountPaid,
    String? description,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse("${AppConfig.baseUrl}/fee/pay"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "classId": classId,
        "amountPaid": amountPaid,
        "description": description,
      }),
    );

    return jsonDecode(response.body);
  }


  static Future<Map<String, dynamic>> getClassPayments({
    required String classId,
    int page = 1,
    int perPage = 10,
  }) async {
    final token = await _getToken();

    final url = Uri.parse("${AppConfig.baseUrl}/fee/class/$classId?page=$page&limit=$perPage");
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to fetch class payments");
    }
  }
}
