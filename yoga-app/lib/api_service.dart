// lib/api_service.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // Use the correct IP depending on the platform (web vs mobile)
  final String _baseUrl = kIsWeb ? 'http://localhost:3000/api' : 'http://10.0.2.2:3000/api';

  /// Fetches the list of all yoga groups from the server.
  Future<List<dynamic>> getGroups() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/groups'));

      if (response.statusCode == 200) {
        final decodedJson = json.decode(response.body);
        return decodedJson['data']['groups'];
      } else {
        throw Exception('Failed to load groups. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }
  }

  /// Logs a user in.
  /// NOTE: The backend you have uses email/password, not mobile number.
  /// We are passing a test email here to make the login work.
  Future<Map<String, dynamic>> loginUser(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': 'password123' // Using the default password from the seed script
        }),
      );

      final decodedJson = json.decode(response.body);

      if (response.statusCode == 200 && decodedJson['success'] == true) {
        return decodedJson['data']['user']; // The user data is nested here
      } else {
        throw Exception(decodedJson['message'] ?? 'Failed to login.');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }
  }
}