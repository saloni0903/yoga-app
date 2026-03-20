  Future<List<AttendanceRecord>> getAttendanceForGroup(String groupId) async {
    // This assumes the user is authenticated, so _currentUser should not be null.
    if (_currentUser == null) {
      throw Exception('User not authenticated.');
    }
final userId = _currentUser!.id.toString();

final uri = Uri.parse(
  '$baseUrl/api/attendance/user/$userId',
).replace(queryParameters: {
  'group_id': groupId,
});

print(uri); // DEBUG


    final res = await _client.get(uri, headers: await _authHeaders());
    final data = _decode(res);
    _ensureOk(res, data);

    // The backend nests the result in data -> attendance.
    final listJson = data is Map
        ? data['data']['attendance']
        :null;

    if (listJson is! List) {
      return [];
    }
    return listJson
      .map((e) => AttendanceRecord.fromJson(e))
      .toList();
  }
