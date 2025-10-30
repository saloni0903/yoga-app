// lib/api_service.dart
import 'dart:convert';
import 'dart:typed_data';

import 'models/user.dart';
import 'models/yoga_group.dart';
import 'models/attendance.dart';
import 'models/session_qr_code.dart';
import 'models/session.dart'; 

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'src/client_provider.dart' // This imports the mobile file by default
    if (dart.library.html) 'src/client_provider_web.dart'; // And this one for web

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';



class ApiService with ChangeNotifier {
String get baseUrl {
    // 1. Read from environment variables.
    //    We default to the deployed URL.
    const String apiUrl = String.fromEnvironment(
      'API_URL',
      defaultValue: 'https://yoga-app-7drp.onrender.com',
    );

    // 2. kIsWeb check for web-specific debugging is acceptable.
    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    // 3. Return the environment-defined URL.
    return apiUrl;
  }

  late http.Client _client;
  ApiService() {
    _client = getClient();
  }

  User? _currentUser;
  bool _isAuthenticated = false;
  String? _token;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  // Secure token helpers
  Future<void> _saveToken(String token) async {
    _token = token;
    await _secureStorage.write(key: 'jwt', value: token);
  }

  Future<String?> _loadToken() async {
    _token ??= await _secureStorage.read(key: 'jwt');
    return _token;
  }

  Future<void> _clearToken() async {
    _token = null;
    await _secureStorage.delete(key: 'jwt');
  }

  Map<String, String> _authHeaders({bool includeContentType = true, bool optional = false}) {
    final headers = <String, String>{};
    if (includeContentType) headers['Content-Type'] = 'application/json';

    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    } else if (!optional) {
      throw Exception('Authentication required. No token found.');
    }

    return headers;
  }

  List<AttendanceRecord> recentAttendance = [];

  Future<List<AttendanceRecord>> getAttendanceHistory() async {
    if (_currentUser == null)
      throw Exception('Must be logged in to get history.');
    final res = await _client.get(
      Uri.parse('$baseUrl/api/attendance/user/${_currentUser!.id}'),
      headers: _authHeaders(),
    );

    final data = _decode(res);
    _ensureOk(res, data);

    // The backend returns a paginated response, we need to get the 'attendance' list from it
    final List listJson = data['data']?['attendance'] ?? [];
    return listJson.map((e) => AttendanceRecord.fromJson(e)).toList();
  }

  Future<void> fetchDashboardData() async {
    if (_currentUser == null) return; // Don't fetch if not logged in

    try {
      final res = await _client.get(
        Uri.parse('$baseUrl/api/dashboard'),
        headers: _authHeaders(),
      );

      final data = _decode(res);
      _ensureOk(res, data);

      final dashboardData = data['data'];
      final statsData = dashboardData['stats'] as Map<String, dynamic>?;
      final attendanceList = dashboardData['recentAttendance'] as List?;

      if (statsData != null) {
        // Update the existing currentUser with new stats from the dashboard
        _currentUser = _currentUser?.copyWith(
          totalMinutesPracticed: statsData['totalMinutesPracticed'],
          totalSessionsAttended: statsData['totalSessionsAttended'],
          currentStreak: statsData['currentStreak'],
        );
      }

      if (attendanceList != null) {
        // Store the recent attendance history
        recentAttendance = attendanceList
            .map((e) => AttendanceRecord.fromJson(e))
            .toList();
      }

      // Notify all widgets listening to ApiService that data has changed
      notifyListeners();
    } catch (e) {
      print('Failed to fetch dashboard data: $e');
      // Optionally re-throw or handle the error
    }
  }

  Future<bool> tryAutoLogin() async {
    debugPrint("[tryAutoLogin] Attempting auto-login...");
    try {
      final token = await _loadToken();
      if (token == null) {
        _isAuthenticated = false;
        notifyListeners();
        return false;
      }
      
      // If token exists, try to get profile (which verifies the token's validity)
      final res = await _client.get(
        Uri.parse('$baseUrl/api/auth/profile'),
        headers: _authHeaders(), // CRITICAL: Must send the token
      );

      if (res.statusCode == 200) {
        final data = _decode(res);
        _currentUser = User.fromJson(data['data']); // User is nested under 'data' in your backend response
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      debugPrint("[tryAutoLogin] Failed. Status code: ${res.statusCode}. Clearing token.");
      // If token is invalid/expired (e.g., status 401), clear it.
      await _clearToken();
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } catch (e) {
      // Catch network errors, server down, etc.
      debugPrint("[tryAutoLogin] CRITICAL FAILURE: $e");
      await _clearToken();
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  Future<User> login(String email, String password) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    final data = _decode(res);
    _ensureOk(res, data);

    final token = data['data']['token']; // Assuming your mobile backend sends JWT here
    if (token == null) {
      throw Exception('Login succeeded but token was not returned in JSON body.');
    }
    
    await _saveToken(token);
    _currentUser = User.fromJson(data['data']['user']);
    _isAuthenticated = true;
    notifyListeners();
    return _currentUser!;
  }

  Future<void> logout() async {
    await _clearToken();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<User> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String samagraId,
    required String role,
    required String location,
  }) async {
    final parts = fullName.trim().split(' ');
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final res = await _client.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'samagraId': samagraId,
        'password': password,
        'role': role,
        'location': location,
      }),
    );
    final data = _decode(res);
    _ensureCreated(res, data);
    final token = data['data']['token']; // Assuming token is returned on successful registration
    if (token != null) {
      await _saveToken(token);
    }
    final user = User.fromAuthJson(data['data']);
    _currentUser = user;
    _isAuthenticated = true;
    notifyListeners();
    return user;
  }

  Future<void> updateUserFcmToken(String fcmToken) async {
    if (_currentUser == null) return; // Don't proceed if not logged in

    // NOTE: This assumes a new backend endpoint `PUT /api/users/me/fcm-token`
    // You will need to create this endpoint.
    final res = await _client.put(
      Uri.parse('$baseUrl/api/users/me/fcm-token'),
      headers: _authHeaders(),
      body: json.encode({'fcmToken': fcmToken}),
    );

    _ensureOk(res, _decode(res));
  }

  Future<User> getMyProfile() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/auth/profile'),
      headers: _authHeaders(),
    );
    final data = _decode(res);
    _ensureOk(res, data);
    return User.fromJson(data['data']);
  }

  Future<User> updateMyProfile({
    required Map<String, dynamic> profileData,
    Uint8List? imageBytes, // <-- To this
    String? imageFileName,
  }) async {
    if (_currentUser == null) throw Exception('Not authenticated.');

    final uri = Uri.parse('$baseUrl/api/users/${_currentUser!.id}');
    http.Response res;

    // ⭐ CHANGE: Use a multipart request if an image file is provided.
    if (imageBytes != null && imageFileName != null) {
      var request = http.MultipartRequest('PUT', uri);

      // Add headers
      request.headers.addAll(_authHeaders(includeContentType: false));

      // Add text fields
      profileData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add the image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'profileImage',
          imageBytes,
          filename: imageFileName,
        ),
      );

      final streamedResponse = await request.send();
      res = await http.Response.fromStream(streamedResponse);
    } else {
      // If no file, use the original JSON request
      res = await _client.put(
        uri,
        headers: _authHeaders(),
        body: json.encode(profileData),
      );
    }

    final data = _decode(res);
    _ensureOk(res, data);

    final updatedUser = User.fromJson(data['data']);
    _currentUser = updatedUser.copyWith(token: _token);
    notifyListeners();

    return updatedUser;
  }

  Future<List<User>> getGroupMembers({required String groupId}) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/groups/$groupId/members'),
      headers: _authHeaders(),
    );
    final data = _decode(res);
    _ensureOk(res, data);
    debugPrint('DEBUG: Raw members JSON from server: $data');
    // The backend returns a list of user objects
    final List listJson = data['data'] ?? [];
    return listJson.map((e) => User.fromMemberJson(e)).toList();
  }

  Future<SessionQrCode> qrGenerate({
    required String groupId,
    required DateTime sessionDate,
    required String createdBy,
  }) async {
    final res = await _client.post(
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

  Future<List<Session>> getInstructorSchedule() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/schedule/instructor'),
      headers: _authHeaders(),
    );
    final data = _decode(res);
    _ensureOk(res, data);
    final List listJson = data['data'] ?? [];
    return listJson.map((e) => Session.fromJson(e)).toList();
  }

  Future<List<Session>> getParticipantSchedule() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/schedule/participant'),
      headers: _authHeaders(),
    );
    final data = _decode(res);
    _ensureOk(res, data);
    final List listJson = data['data'] ?? [];
    return listJson.map((e) => Session.fromJson(e)).toList();
  }

  Future<YogaGroup> getGroupById(String groupId) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/groups/$groupId'),
      headers: _authHeaders(),
    );
    final data = _decode(res);
    _ensureOk(res, data);
    // The group data is directly in 'data' for this endpoint
    return YogaGroup.fromJson(data['data']);
  }

  Future<void> createGroup(Map<String, dynamic> groupData) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/groups'),
      headers: _authHeaders(),
      body: jsonEncode(groupData), // It simply encodes the map it receives.
    );
    _ensureCreated(res, _decode(res));
  }

  Future<void> updateGroup(String id, Map<String, dynamic> groupData) async {
    final res = await _client.put(
      Uri.parse('$baseUrl/api/groups/$id'),
      headers: _authHeaders(),
      body: json.encode(groupData), // It simply encodes the map it receives.
    );
    _ensureOk(res, _decode(res));
  }

  Future<void> joinGroup({required String groupId}) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/groups/$groupId/join'),
      headers: _authHeaders(),
      body: jsonEncode({}),
    );
    _ensureOk(res, _decode(res));
  }

  Future<List<YogaGroup>> getMyJoinedGroups() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/groups/my-groups'),
      headers: _authHeaders(), // This is a protected route
    );

    final data = _decode(res);
    _ensureOk(res, data);

    final List listJson = data['data']['groups'];
    return listJson.map((e) => YogaGroup.fromJson(e)).toList();
  }

  Future<void> markAttendanceByQr({required String qrToken}) async {
    final res = await _client.post(
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

    final res = await _client.get(uri, 
      headers: _authHeaders()
    );
    final data = _decode(res);
    _ensureOk(res, data);

    // The backend nests the result in data -> attendance.
    final List listJson = data['data']['attendance'];
    return listJson.map((e) => AttendanceRecord.fromJson(e)).toList();
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

  Future<List<YogaGroup>> getGroups({
    String? search,
    String? instructorId,
    double? latitude,
    double? longitude,
  }) async {
    final uri = Uri.parse('$baseUrl/api/groups').replace(
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (instructorId != null && instructorId.isNotEmpty)
          'instructor_id': instructorId,
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      },
    );
    final res = await _client.get(uri, 
      headers: _authHeaders(optional: true)
    );
    final data = _decode(res);
    _ensureOk(res, data);
    final payload = data['data'];
    List listJson = (payload is Map && payload['groups'] is List)
        ? payload['groups']
        : [];
    return listJson.map((e) => YogaGroup.fromJson(e)).toList();
  }

  Future<Map<String, String>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$baseUrl/api/groups/location/reverse-geocode')
        .replace(
          queryParameters: {
            'lat': latitude.toString(),
            'lon': longitude.toString(),
          },
        );
    final res = await _client.get(uri, 
      headers: _authHeaders(optional: true)
      );
    final data = _decode(res);
    _ensureOk(res, data);

    // Return a map with both address and city
    return {
      'address': data['data']['address'] ?? 'Could not fetch address',
      'city': data['data']['city'] ?? '',
    };
  }
}
