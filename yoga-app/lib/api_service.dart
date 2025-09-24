// lib/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart' show kIsAndroid;

import 'package:http/http.dart' as http;
import 'models/user.dart';
import 'models/yoga_group.dart';
import 'models/session_qr_code.dart';
import 'models/attendance.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService with ChangeNotifier {
  String get baseUrl {
    if (kIsWeb) {
      // For web/Chrome - use localhost
      return 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      // 🔧 REPLACE 'YOUR_PC_IP' with your actual computer's IP address
      return 'http://10.104.65.41:3000'; // Example: your PC's IP
    } else {
      // For iOS or other platforms
      return 'http://localhost:3000';
    }
  }

  String? _token;
  User? _currentUser;

  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _currentUser != null;

  Future<void> _setAuth(String? token, User? user) async {
    _token = token;
    _currentUser = user;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('token', token);
    } else {
      await prefs.clear(); // Clear all data on logout
    }
  }

  /// ✅ FIXED & IMPROVED: Attempts to log in using a stored token.
  /// It now fetches the user's profile to ensure the token is valid and the
  /// user data is fully loaded.
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('token');
    if (storedToken == null || storedToken.isEmpty) {
      return false;
    }
    _token = storedToken;

    try {
      // Use the token to fetch the full user profile.
      final user = await getMyProfile();
      // If successful, the user is fully authenticated.
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      // If fetching fails (e.g., expired token), clear the invalid token.
      await logout();
      return false;
    }
  }

  Future<User> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    final data = _decode(res);
    _ensureOk(res, data);

    final user = User.fromAuthJson(data['data']);
    await _setAuth(user.token, user);
    return user;
  }

  /// ✅ FIXED: Logout now correctly clears state and notifies listeners.
  Future<void> logout() async {
    await _setAuth(null, null);
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

    final user = User.fromAuthJson(data['data']);
    await _setAuth(user.token, user);
    return user;
  }

  Future<User> getMyProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/auth/profile'),
      headers: _authHeaders(),
    );
    final data = _decode(res);
    _ensureOk(res, data);
    return User.fromJson(data['data']);
  }

  Future<User> updateMyProfile(Map<String, dynamic> profileData) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/auth/profile'),
      headers: _authHeaders(),
      body: json.encode(profileData),
    );
    final data = _decode(res);
    _ensureOk(res, data);

    final updatedUser = User.fromJson(data['data']);
    // Keep the token from the original currentUser object.
    _currentUser = updatedUser.copyWith(token: _token);
    notifyListeners();

    return updatedUser;
  }

  Future<List<YogaGroup>> getGroups({
    String? search,
    String? instructorId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/groups').replace(
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (instructorId != null && instructorId.isNotEmpty)
          'instructor_id': instructorId,
      },
    );
    final res = await http.get(uri, headers: _authHeaders(optional: true));
    final data = _decode(res);
    _ensureOk(res, data);
    final payload = data['data'];
    List listJson = (payload is Map && payload['groups'] is List)
        ? payload['groups']
        : [];
    return listJson.map((e) => YogaGroup.fromJson(e)).toList();
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
        'created_by': createdBy,
      }),
    );
    final data = _decode(res);
    _ensureCreated(res, data);
    return SessionQrCode.fromJson(data['data']);
  }

  Future<YogaGroup> getGroupById(String groupId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/groups/$groupId'),
      headers: _authHeaders(),
    );
    final data = _decode(res);
    _ensureOk(res, data);
    // The group data is directly in 'data' for this endpoint
    return YogaGroup.fromJson(data['data']);
  }

  Future<void> createGroup({
    required String groupName,
    required String location,
    required String locationText,
    required double latitude,
    required double longitude,
    required String timingsText,
    required String instructorId,
    String? description,
    int maxParticipants = 20,
    String yogaStyle = 'hatha',
    String difficultyLevel = 'all-levels',
    int sessionDuration = 60,
    double pricePerSession = 0,
    String currency = 'RUPEE',
    List<String> requirements = const [],
    List<String> equipmentNeeded = const [],
    bool isActive = true,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/groups'),
      headers: _authHeaders(),
      body: jsonEncode({
        'group_name': groupName,
        'location': location,
        'location_text': locationText,
        'latitude': latitude,
        'longitude': longitude,
        'timings_text': timingsText,
        'instructor_id': instructorId,
        'description': description,
        'max_participants': maxParticipants,
        'yoga_style': yogaStyle,
        'difficulty_level': difficultyLevel,
        'session_duration': sessionDuration,
        'price_per_session': pricePerSession,
        'currency': currency,
        'requirements': requirements,
        'equipment_needed': equipmentNeeded,
        'is_active': isActive,
      }),
    );
    _ensureCreated(res, _decode(res));
  }

  /// ✅ NEW METHOD: Updates an existing yoga group.
  Future<void> updateGroup({
    required String id,
    String? groupName,
    String? location,
    String? locationText,
    double? latitude,
    double? longitude,
    String? timingsText,
    String? description,
    int? maxParticipants,
    String? yogaStyle,
    String? difficultyLevel,
    int? sessionDuration,
    double? pricePerSession,
    String? currency,
    List<String>? requirements,
    List<String>? equipmentNeeded,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};

    // Only include fields that are not null to avoid overwriting existing data.
    if (groupName != null) body['group_name'] = groupName;
    if (location != null) body['location'] = location;
    if (locationText != null) body['location_text'] = locationText;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (timingsText != null) body['timings_text'] = timingsText;
    if (description != null) body['description'] = description;
    if (maxParticipants != null) body['max_participants'] = maxParticipants;
    if (yogaStyle != null) body['yoga_style'] = yogaStyle;
    if (difficultyLevel != null) body['difficulty_level'] = difficultyLevel;
    if (sessionDuration != null) body['session_duration'] = sessionDuration;
    if (pricePerSession != null) body['price_per_session'] = pricePerSession;
    if (currency != null) body['currency'] = currency;
    if (requirements != null) body['requirements'] = requirements;
    if (equipmentNeeded != null) body['equipment_needed'] = equipmentNeeded;
    if (isActive != null) body['is_active'] = isActive;

    final res = await http.put(
      Uri.parse('$baseUrl/api/groups/$id'),
      headers: _authHeaders(),
      body: json.encode(body),
    );
    _ensureOk(res, _decode(res));
  }

  Future<void> joinGroup({required String groupId}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/groups/$groupId/join'),
      headers: _authHeaders(),
      body: jsonEncode({}),
    );
    _ensureOk(res, _decode(res));
  }

  Future<List<YogaGroup>> getMyJoinedGroups() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/groups/my-groups'),
      headers: _authHeaders(), // This is a protected route
    );

    final data = _decode(res);
    _ensureOk(res, data);

    final List listJson = data['data']['groups'];
    return listJson.map((e) => YogaGroup.fromJson(e)).toList();
  }

  Future<void> markAttendanceByQr({required String qrToken}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/attendance/scan'),
      headers: _authHeaders(), // Must be authenticated
      body: json.encode({'token': qrToken}),
    );
    final data = _decode(res);
    _ensureOk(res, data); // ensureOk is fine, we want a 200 or 201 status
  }

  Future<List<AttendanceRecord>> getAttendanceForGroup(String groupId) async {
    // This assumes the user is authenticated, so _currentUser should not be null.
    if (_currentUser == null) {
      throw Exception('User not authenticated.');
    }
    final userId = _currentUser!.id;

    // Construct the correct URI: /api/attendance/user/:user_id?group_id=:group_id
    final uri = Uri.parse(
      '$baseUrl/api/attendance/user/$userId',
    ).replace(queryParameters: {'group_id': groupId});

    final res = await http.get(uri, headers: _authHeaders());
    final data = _decode(res);
    _ensureOk(res, data);

    // The backend nests the result in data -> attendance.
    final List listJson = data['data']['attendance'];
    return listJson.map((e) => AttendanceRecord.fromJson(e)).toList();
  }

  Map<String, String> _authHeaders({bool optional = false}) {
    print('[ApiService] Preparing headers. Current token is: $_token');
    final headers = {'Content-Type': 'application/json'};
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    } else if (!optional) {
      throw Exception('Authentication token is missing for a protected route.');
    }
    return headers;
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      return json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Invalid response from server (${res.statusCode})',
      };
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
    if ((res.statusCode != 201) || (data['success'] == false)) {
      throw Exception(data['message'] ?? 'Request failed (${res.statusCode})');
    }
  }
}
