// lib/api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'models/user.dart';
import 'models/yoga_group.dart';
import 'models/session_qr_code.dart';
import 'models/attendance.dart';

class ApiService {
  // Base URL (adjust port if needed)
  final String baseUrl = kIsWeb
      ? 'http://localhost:3000'
      : 'http://10.0.2.2:3000';

  // Persist token after login/register for protected endpoints
  String? token;

  // ---------------- Auth ----------------

  Future<User> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    final data = _decode(res);
    _ensureOk(res, data);
    token = data['token'] as String?;
    return User.fromAuthJson(data['data']);
  }

  Future<User> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
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
      }),
    );
    final data = _decode(res);
    _ensureCreated(res, data);
    token = data['token'] as String?;
    return User.fromAuthJson(data['data']);
  }

  Future<User> getUserProfile(String bearerToken) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $bearerToken',
      },
    );
    final data = _decode(res);
    _ensureOk(res, data);
    return User.fromProfileJson(data['data']);
  }

  // ---------------- Groups ----------------

  Future<List<YogaGroup>> getGroups({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/api/groups').replace(
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': '$page',
        'limit': '$limit',
      },
    );
    final res = await http.get(uri, headers: _authHeaders(optional: true));
    final data = _decode(res);
    _ensureOk(res, data);

    // Accept both: {data: [..]} or {data: {groups: [..]}}
    final payload = data['data'];
    List listJson;
    if (payload is List) {
      listJson = payload;
    } else if (payload is Map && payload['groups'] is List) {
      listJson = payload['groups'];
    } else {
      // Fallback for unknown shapes
      listJson = [];
    }
    return listJson.map((e) => YogaGroup.fromJson(e)).toList();
  }

  Future<YogaGroup> getGroupById(String id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/groups/$id'),
      headers: _authHeaders(optional: true),
    );
    final data = _decode(res);
    _ensureOk(res, data);
    return YogaGroup.fromJson(data['data']);
  }

  Future<void> joinGroup(String groupId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/groups/$groupId/join'),
      headers: _authHeaders(),
      body: json.encode({}),
    );
    final data = _decode(res);
    _ensureOk(res, data);
  }

  Future<void> leaveGroup(String groupId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/groups/$groupId/leave'),
      headers: _authHeaders(),
      body: json.encode({}),
    );
    final data = _decode(res);
    _ensureOk(res, data);
  }

  // Instructor: create/update group (session metadata)
  Future<void> createGroup({
    required String groupname,
    required String locationtext,
    required String timingstext,
    required String yogastyle,
    required String difficultylevel,
    double? latitude,
    double? longitude,
  }) async {
    final body = {
      'groupname': groupname,
      'locationtext': locationtext,
      'timingstext': timingstext,
      'yogastyle': yogastyle,
      'difficultylevel': difficultylevel,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
    final res = await http.post(
      Uri.parse('$baseUrl/api/groups'),
      headers: _authHeaders(),
      body: json.encode(body),
    );
    final data = _decode(res);
    _ensureCreated(res, data);
  }

  Future<void> updateGroup({
    required String id,
    String? groupname,
    String? locationtext,
    String? timingstext,
    String? yogastyle,
    String? difficultylevel,
    bool? isactive,
  }) async {
    final body = {
      if (groupname != null) 'groupname': groupname,
      if (locationtext != null) 'locationtext': locationtext,
      if (timingstext != null) 'timingstext': timingstext,
      if (yogastyle != null) 'yogastyle': yogastyle,
      if (difficultylevel != null) 'difficultylevel': difficultylevel,
      if (isactive != null) 'isactive': isactive,
    };
    final res = await http.put(
      Uri.parse('$baseUrl/api/groups/$id'),
      headers: _authHeaders(),
      body: json.encode(body),
    );
    final data = _decode(res);
    _ensureOk(res, data);
  }

  Future<List<dynamic>> getGroupMembers(
    String groupId,
    String bearerToken,
  ) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/groups/$groupId/members'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $bearerToken',
      },
    );
    final data = _decode(res);
    _ensureOk(res, data);
    return (data['data'] as List);
  }

  // ---------------- Attendance ----------------

  // Participant: own attendance by group
  Future<List<AttendanceRecord>> getAttendanceByGroup(
    String groupId, {
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/api/attendance/user/me').replace(
      queryParameters: {'groupid': groupId, 'page': '$page', 'limit': '$limit'},
    );
    final res = await http.get(uri, headers: _authHeaders());
    final data = _decode(res);
    _ensureOk(res, data);

    // Accept both: {data: [..]} or {data: {items:[..]}}
    final payload = data['data'];
    List listJson;
    if (payload is List) {
      listJson = payload;
    } else if (payload is Map && payload['items'] is List) {
      listJson = payload['items'];
    } else {
      listJson = [];
    }
    return listJson.map((e) => AttendanceRecord.fromJson(e)).toList();
  }

  // Instructor: full group attendance list (if backend exposes it)
  // Replace getGroupAttendanceAll in ApiService
  Future<List<AttendanceRecord>> getGroupAttendanceAll({
    required String groupId,
    int page = 1,
    int limit = 50,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/attendance/group/$groupId',
    ).replace(queryParameters: {'page': '$page', 'limit': '$limit'});
    final res = await http.get(uri, headers: _authHeaders());
    final data = _decode(res);
    _ensureOk(res, data);
    final payload = data['data'];
    final listJson = payload is List
        ? payload
        : (payload is Map && payload['items'] is List ? payload['items'] : []);
    return listJson.map((e) => AttendanceRecord.fromJson(e)).toList();
  }

  // ---------------- QR ----------------

  // Instructor: generate QR for session
  Future<SessionQrCode> qrGenerate({
    required String groupId,
    required DateTime sessionDate,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/qr/generate'),
      headers: _authHeaders(),
      body: json.encode({
        'groupid': groupId,
        'sessiondate': sessionDate.toIso8601String(),
        'options': {'maxusage': 100},
      }),
    );
    final data = _decode(res);
    _ensureCreated(res, data);
    return SessionQrCode.fromJson(data['data']);
  }

  Future<void> qrDeactivate(String qrId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/qr/$qrId/deactivate'),
      headers: _authHeaders(),
      body: json.encode({}),
    );
    final data = _decode(res);
    _ensureOk(res, data);
  }

  // Participant: scan QR to mark attendance
  Future<void> qrScan({
    required String tokenValue,
    required String groupId,
    required DateTime sessionDate,
    double? lat,
    double? lng,
  }) async {
    final body = {
      'token': tokenValue,
      'groupid': groupId,
      'sessiondate': sessionDate.toIso8601String(),
      if (lat != null && lng != null)
        'gps': {'latitude': lat, 'longitude': lng},
    };
    final res = await http.post(
      Uri.parse('$baseUrl/api/qr/scan'),
      headers: _authHeaders(),
      body: json.encode(body),
    );
    final data = _decode(res);
    _ensureCreatedOrOk(
      res,
      data,
    ); // scan may return 201 or 200 depending on backend
  }

  // ---------------- Helpers ----------------

  Map<String, String> _authHeaders({bool optional = false}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else if (!optional) {
      // If needed, throw to signal missing token on protected endpoints
      // throw Exception('Not authenticated');
    }
    return headers;
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      return json.decode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {'message': 'Invalid JSON response', 'success': false};
    }
  }

  void _ensureOk(http.Response res, Map<String, dynamic> data) {
    if (res.statusCode < 200 ||
        res.statusCode >= 300 ||
        (data['success'] == false)) {
      throw Exception(data['message'] ?? 'Request failed (${res.statusCode})');
    }
  }

  void _ensureCreated(http.Response res, Map<String, dynamic> data) {
    if ((res.statusCode != 201 && res.statusCode != 200) ||
        (data['success'] == false)) {
      throw Exception(data['message'] ?? 'Request failed (${res.statusCode})');
    }
  }

  void _ensureCreatedOrOk(http.Response res, Map<String, dynamic> data) {
    if (!((res.statusCode >= 200 && res.statusCode < 300)) ||
        (data['success'] == false)) {
      throw Exception(data['message'] ?? 'Request failed (${res.statusCode})');
    }
  }
}