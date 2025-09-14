// lib/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'models/user.dart';

class ApiService {
  final String _baseUrl = kIsWeb ? 'http://localhost:3000/api' : 'http://10.0.2.2:3000/api';

  Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return User.fromAuthJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  Future<User> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final nameParts = fullName.trim().split(' ');
    final String firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    final data = json.decode(response.body);
    if (response.statusCode == 201 && data['success']) {
      return User.fromAuthJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Registration failed');
    }
  }

  Future<User> getUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return User.fromProfileJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to load user profile');
    }
  }

  Future<List<dynamic>> getAllGroups(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/groups'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return data['data']['groups'];
    } else {
      throw Exception(data['message'] ?? 'Failed to load groups');
    }
  }

  Future<void> joinGroup(String groupId, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/groups/$groupId/join'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({}),
    );
    final data = json.decode(response.body);
    if (response.statusCode != 200 || !data['success']) {
      throw Exception(data['message'] ?? 'Failed to join group');
    }
  }

  Future<List<dynamic>> getGroupMembers(String groupId, String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/groups/$groupId/members'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Failed to load group members');
    }
  }
}