import 'dart:convert';
import 'dart:io';
import 'models/user.dart';
import 'models/yoga_group.dart';
import 'models/attendance.dart';
import 'models/session_qr_code.dart';
import 'package:flutter/material.dart';
import 'models/session.dart'; 
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
// lib/api_service.dart

class ApiService with ChangeNotifier {
  // Local dev
  // String baseURL() {
  //   if (kIsWeb) {
  //     return 'http://localhost:3000'; // Web uses localhost directly
  //   } else {
  //     // Mobile platforms need to use the local network IP address of the machine running the backend.
  //     // Replace with your machine's local IP address.
  //     return 'http://10.104.65.41:3000';
  //   }
  // }

  // Deployed
  String get baseUrl => 'https://yoga-app-7drp.onrender.com';

  String? _token;
  User? _currentUser;

  List<AttendanceRecord> recentAttendance = [];

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
      await prefs.remove('token');
    }
  }

  Future<List<AttendanceRecord>> getAttendanceHistory() async {
    if (_currentUser == null)
      throw Exception('Must be logged in to get history.');

    // This calls the backend route you provided: GET /api/attendance/user/:user_id
    final res = await http.get(
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
      final res = await http.get(
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
      // await fetchDashboardData();
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
    // await fetchDashboardData(); // Fetch dashboard data after manual login
    return _currentUser!;
    // return user;
  }

  /// ✅ FIXED: Logout now correctly clears state and notifies listeners.
  Future<void> logout() async {
    await _setAuth(null, null);
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
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'samagraId': samagraId,
        'password': password,
        'role': role,
        'location': location,
        'samagraId': samagraId,
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

  Future<User> updateMyProfile({
    required Map<String, dynamic> profileData,
    File? imageFile, // ⭐ ADDITION: Optional parameter for the image file
  }) async {
    if (_currentUser == null) throw Exception('Not authenticated.');

    final uri = Uri.parse('$baseUrl/api/users/${_currentUser!.id}');
    http.Response res;

    // ⭐ CHANGE: Use a multipart request if an image file is provided.
    if (imageFile != null) {
      var request = http.MultipartRequest('PUT', uri);

      // Add headers
      request.headers.addAll(_authHeaders(includeContentType: false));

      // Add text fields
      profileData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'profileImage', // This key must match what your backend expects
          imageFile.path,
        ),
      );

      final streamedResponse = await request.send();
      res = await http.Response.fromStream(streamedResponse);
    } else {
      // If no file, use the original JSON request
      res = await http.put(
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

  // ⭐ You may also need to slightly adjust your _authHeaders helper
  // to prevent it from setting a 'Content-Type' for multipart requests.

  Map<String, String> _authHeaders({
    bool optional = false,
    bool includeContentType = true,
  }) {
    final headers = <String, String>{};
    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }

    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    } else if (!optional) {
      throw Exception('Authentication token is missing for a protected route.');
    }
    return headers;
  }

  Future<List<User>> getGroupMembers({required String groupId}) async {
    // This calls the backend route: GET /api/groups/:groupId/members
    final res = await http.get(
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

  Future<List<Session>> getInstructorSchedule() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/schedule/instructor'),
      headers: _authHeaders(),
    );
    final data = _decode(res);
    _ensureOk(res, data);
    final List listJson = data['data'] ?? [];
    return listJson.map((e) => Session.fromJson(e)).toList();
  }

  Future<List<Session>> getParticipantSchedule() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/schedule/participant'),
      headers: _authHeaders(),
    );
    final data = _decode(res);
    _ensureOk(res, data);
    final List listJson = data['data'] ?? [];
    return listJson.map((e) => Session.fromJson(e)).toList();
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

  Future<void> createGroup(Map<String, dynamic> groupData) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/groups'),
      headers: _authHeaders(),
      body: jsonEncode(groupData), // It simply encodes the map it receives.
    );
    _ensureCreated(res, _decode(res));
  }

  Future<void> updateGroup(String id, Map<String, dynamic> groupData) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/groups/$id'),
      headers: _authHeaders(),
      body: json.encode(groupData), // It simply encodes the map it receives.
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
    final res = await http.get(uri, headers: _authHeaders(optional: true));
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
    final res = await http.get(uri, headers: _authHeaders(optional: true));
    final data = _decode(res);
    _ensureOk(res, data);

    // Return a map with both address and city
    return {
      'address': data['data']['address'] ?? 'Could not fetch address',
      'city': data['data']['city'] ?? '',
    };
  }
}
