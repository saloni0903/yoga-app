// lib/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'models/user.dart';
import 'models/yoga_group.dart';
import 'models/session_qr_code.dart';

class ApiService {
  final String _baseUrl = kIsWeb ? 'http://localhost:3000/api' : 'http://10.0.2.2:3000/api';

  // Handles user login
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

  // Handles new user registration
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

  // Fetches the profile of the currently logged-in user
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

  // Fetches a list of all yoga groups
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

  // Fetches details for a single group by its ID
  Future<YogaGroup> getGroupById(String groupId, String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/groups/$groupId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return YogaGroup.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to load group details');
    }
  }

  // Allows a user to join a group
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
  Future<void> createGroup(String groupName, String location, String timings, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/groups'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'group_name': groupName,
        'location_text': location,
        'timings_text': timings,
        // The backend requires lat/long, we'll send defaults for now.
        'latitude': 22.7196, // Default for Indore
        'longitude': 75.8577, // Default for Indore
      }),
    );
    final data = json.decode(response.body);
    if (response.statusCode != 201 || !data['success']) {
      throw Exception(data['message'] ?? 'Failed to create group');
    }
  }

  // Fetches the list of members for a specific group
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

  // Generates a new QR code for an instructor's group
  Future<SessionQrCode> generateQrCode(String groupId, String token) async {
    final String today = DateTime.now().toIso8601String();
    final response = await http.post(
      Uri.parse('$_baseUrl/qr/generate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'group_id': groupId,
        'session_date': today,
      }),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 201 && data['success']) {
      return SessionQrCode.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to generate QR Code');
    }
  }
  Future<String> scanQrAndMarkAttendance(String qrToken, String authToken) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/qr/scan'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({'token': qrToken}),
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return data['message'] ?? 'Attendance marked successfully!';
    } else {
      throw Exception(data['message'] ?? 'Failed to mark attendance');
    }
  }
}
