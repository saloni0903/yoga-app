// lib/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'models/user.dart';
import 'models/yoga_group.dart';
import 'models/session_qr_code.dart';
import 'models/attendance.dart';

class ApiService {
  final String baseUrl = kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
  String? token;

  Future<User> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    final data = _decode(res);
    _ensureOk(res, data);
    token = data['data']['token'] as String?;
    return User.fromAuthJson(data['data']);
  }

  Future<User> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    required String location,
  }) async {
    final parts = fullName.trim().split(' ');
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'role': role,
        'location': location,
      }),
    );
    final data = _decode(res);
    _ensureCreated(res, data);
    token = data['data']['token'] as String?;
    return User.fromAuthJson(data['data']);
  }

  Future<List<YogaGroup>> getGroups({String? search}) async {
    final uri = Uri.parse('$baseUrl/api/groups').replace(
      queryParameters: { if (search != null && search.isNotEmpty) 'search': search },
    );
    final res = await http.get(uri, headers: _authHeaders(optional: true));
    final data = _decode(res);
    _ensureOk(res, data);
    final payload = data['data'];
    List listJson = (payload is Map && payload['groups'] is List) ? payload['groups'] : [];
    return listJson.map((e) => YogaGroup.fromJson(e)).toList();
  }

Future<void> createGroup({
  required String groupName,
  required String location,
  required String timings,
  required String instructorId,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/api/groups'),
    headers: _authHeaders(),
    body: jsonEncode({
      'group_name': groupName,
      'location': location,
      'location_text': location,
      'timings_text': timings,
      'latitude': 22.7196,
      'longitude': 75.8577,
      'instructor_id': instructorId,
    }),
  );
  _ensureCreated(res, _decode(res));
}
  
  Future<void> updateGroup({required String id, String? groupName, String? location, String? timings}) async {
    final body = {
      if (groupName != null) 'group_name': groupName,
      if (location != null) 'location_text': location,
      if (timings != null) 'timings_text': timings,
    };
    final res = await http.put(
      Uri.parse('$baseUrl/api/groups/$id'),
      headers: _authHeaders(),
      body: json.encode(body),
    );
    _ensureOk(res, _decode(res));
  }
  
  Future<SessionQrCode> qrGenerate({
    required String groupId, 
    required DateTime sessionDate,
    required String createdBy,
    }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/qr/generate'),
      headers: _authHeaders(),
      body: json.encode({
        'group_id': groupId,
        'session_date': sessionDate.toIso8601String(),
        'created_by': createdBy
      }),
    );
    final data = _decode(res);
    _ensureCreated(res, data);
    return SessionQrCode.fromJson(data['data']);
  }

  // Future<void> joinGroup(String groupId) async {
  //   final res = await http.post(
  //     Uri.parse('$baseUrl/api/groups/$groupId/join'),
  //     headers: _authHeaders(),
  //     body: jsonEncode({}),
  //   );
  //   _ensureOk(res, _decode(res));
  // }
  Future<void> joinGroup(String groupId, String userId) async {
  final res = await http.post(
    Uri.parse('$baseUrl/api/groups/$groupId/join'),
    headers: _authHeaders(),
    body: jsonEncode({}), // ✅ send user_id
  );
  _ensureOk(res, _decode(res));
}


  Map<String, String> _authHeaders({bool optional = false}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      return json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Invalid response from server (${res.statusCode})'};
    }
  }

  void _ensureOk(http.Response res, Map<String, dynamic> data) {
    if (res.statusCode < 200 || res.statusCode >= 300 || (data['success'] == false)) {
      throw Exception(data['message'] ?? 'Request failed (${res.statusCode})');
    }
  }

  void _ensureCreated(http.Response res, Map<String, dynamic> data) {
    if ((res.statusCode != 201) || (data['success'] == false)) {
      throw Exception(data['message'] ?? 'Request failed (${res.statusCode})');
    }
  }
}