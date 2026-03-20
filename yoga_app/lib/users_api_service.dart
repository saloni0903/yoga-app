import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class UsersApiService {
  String get baseUrl {
    if (kIsWeb) return 'http://localhost:5078';
    return 'http://10.0.2.2:5078';
  }

  Future<List<dynamic>> getUsers(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/users'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load users');
    }

    final body = jsonDecode(res.body);
    return body['data']['users'];
  }

  Future<dynamic> getUserById(int id, String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/users/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('User not found');
    }

    final body = jsonDecode(res.body);
    return body['data'];
  }
}
