using Npgsql;
using System.Text.RegularExpressions;
using yesmain.Models;

public class AttendanceRepository : IAttendanceRepository
{
    private readonly string _connectionString;

    public AttendanceRepository(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection");
    }

    // Check if user is an active member of a group
    public async Task<bool> IsMemberAsync(Guid userId, Guid groupId)
    {
        try
        {

            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(
                "SELECT COUNT(1) FROM yesgroupmembers WHERE UserId=@userId AND GroupId=@groupId AND Status='active'",
                conn);
            cmd.Parameters.AddWithValue("@userId", userId);
            cmd.Parameters.AddWithValue("@groupId", groupId);

            var count = await cmd.ExecuteScalarAsync();
            if (count == null)
            {
                return false;
            }

            return true;
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    // Check if attendance already exists for a user in a session
    public async Task<bool> ExistsAsync(Guid userId, Guid groupId, DateTime sessionDate,Guid qrcodeId)
    {
        try
        {

            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(
                "SELECT COUNT(1) FROM yesattendance WHERE UserId=@userId AND GroupId=@groupId AND SessionDate=@sessionDate and qr_code_id = @qrcodeId",
                conn);
            cmd.Parameters.AddWithValue("@userId", userId);
            cmd.Parameters.AddWithValue("@groupId", groupId);
            cmd.Parameters.AddWithValue("@qrcodeId", qrcodeId);
            cmd.Parameters.AddWithValue("@sessionDate", sessionDate.Date);

            var count = await cmd.ExecuteScalarAsync();
            if (count == null)
            {
                return false;
            }

            return true;
        }
        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }


    // Mark attendance
    public async Task<Attendance> MarkAttendanceAsync(Attendance attendance)
    {
        try
        {

            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            var sql = @"
            INSERT INTO yesattendance (user_id, group_id, session_date, qr_code_id, attendance_type,marked_at,check_in_time)
            VALUES (@userId, @groupId, @sessionDate, @qrCodeId, @attendanceType,@markedAt,@CheckInTime)
            RETURNING *";

            await using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@userId", attendance.UserId);
            cmd.Parameters.AddWithValue("@groupId", attendance.GroupId);
            cmd.Parameters.AddWithValue("@sessionDate", attendance.SessionDate);
            cmd.Parameters.AddWithValue("@qrCodeId", attendance.QrCodeId);
            cmd.Parameters.AddWithValue("@attendanceType", attendance.AttendanceType);
            cmd.Parameters.AddWithValue("@markedAt", attendance.MarkedAt);
            cmd.Parameters.AddWithValue("@CheckInTime", attendance.CheckInTime);

            await using var reader = await cmd.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                return new Attendance
                {
                    Id = reader.GetGuid(reader.GetOrdinal("id")),
                    UserId = reader.GetGuid(reader.GetOrdinal("user_id")),
                    GroupId = reader.GetGuid(reader.GetOrdinal("group_id")),
                    SessionDate = reader.GetDateTime(reader.GetOrdinal("session_date")),
                    CheckInTime = reader.GetDateTime(reader.GetOrdinal("check_in_time")),
                    MarkedAt = reader.GetDateTime(reader.GetOrdinal("marked_at")),
                    QrCodeId =  reader.GetGuid(reader.GetOrdinal("qr_code_id")),
                    AttendanceType = reader.GetString(reader.GetOrdinal("attendance_type"))
                };
            }

            return null;
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    // Get QR Code by token
    public async Task<SessionQrCode> GetQrCodeAsync(string token)
    {
        try
        {

            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(
                "SELECT * FROM session_qr_codes WHERE Token=@token",
                conn);
            cmd.Parameters.AddWithValue("@token", token);

            await using var reader = await cmd.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                return new SessionQrCode
                {
                    Id = reader.GetGuid(reader.GetOrdinal("id")),
                    Token = reader.GetString(reader.GetOrdinal("token")),
                    GroupId = reader.GetGuid(reader.GetOrdinal("group_id")),
                    SessionDate = reader.GetDateTime(reader.GetOrdinal("session_date")),
                    ExpiresAt = reader.GetDateTime(reader.GetOrdinal("expires_at"))
                };
            }

            return null;
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    // Update user stats: total sessions, minutes practiced, streak
    public async Task UpdateUserStatsAsync(Guid userId, Guid groupId, DateTime sessionDate)
    {
        try
        {
            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            // 1. Get group schedule times
            await using var scheduleCmd = new NpgsqlCommand(
                "SELECT startTime, endTime FROM yesgroups WHERE Id = @groupId",
                conn);

            scheduleCmd.Parameters.AddWithValue("@groupId", groupId);

            TimeSpan? startTime = null;
            TimeSpan? endTime = null;

            await using var reader = await scheduleCmd.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                if (!reader.IsDBNull(reader.GetOrdinal("startTime")))
                    startTime = reader.GetTimeSpan(reader.GetOrdinal("startTime"));

                if (!reader.IsDBNull(reader.GetOrdinal("endTime")))
                    endTime = reader.GetTimeSpan(reader.GetOrdinal("endTime"));
            }

            if (startTime == null || endTime == null)
                return;

            // 2. Calculate duration
            var durationMinutes = (endTime.Value - startTime.Value).TotalMinutes;

            // Optional: handle overnight sessions (e.g. 22:00 → 01:00)
            if (durationMinutes < 0)
                durationMinutes += 24 * 60;

            // 3. Update user stats
            await using var updateCmd = new NpgsqlCommand(@"
            UPDATE Users SET
                totalSessionsAttended = COALESCE(totalSessionsAttended, 0) + 1,
                totalMinutesPracticed = COALESCE(totalMinutesPracticed, 0) + @minutes
            WHERE Id = @userId",
                conn);

            updateCmd.Parameters.AddWithValue("@minutes", (int)durationMinutes);
            updateCmd.Parameters.AddWithValue("@userId", userId);

            await updateCmd.ExecuteNonQueryAsync();
        }
        catch (Exception ex)
        {
            throw; // keep stack trace
        }

        // 4. Streak logic can go here later
    }

    // Delete attendance
    public async Task DeleteAsync(Guid id)
    {
        try
        {

            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand("DELETE FROM Attendance WHERE Id=@id", conn);
            cmd.Parameters.AddWithValue("@id", id);

            await cmd.ExecuteNonQueryAsync();
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    // Get user attendance with pagination
    public async Task<IEnumerable<Attendance>> GetUserAttendanceAsync(
        Guid userId,
        UserAttendanceFilterDTO dto)
    {
        var list = new List<Attendance>();

        await using var conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        var page = dto.Page <= 0 ? 1 : dto.Page;
        var limit = dto.Limit <= 0 ? 10 : dto.Limit;
        var offset = (page - 1) * limit;

        var sql = @"
        SELECT *
        FROM yesattendance
        WHERE user_id = @userId
    ";

        if (dto.GroupId.HasValue)
            sql += " AND group_id = @groupId";

        if (dto.StartDate.HasValue && dto.EndDate.HasValue)
            sql += " AND session_date BETWEEN @start AND @end";

        sql += " ORDER BY session_date DESC OFFSET @offset LIMIT @limit";

        await using var cmd = new NpgsqlCommand(sql, conn);

        cmd.Parameters.AddWithValue("@userId", userId);
        cmd.Parameters.AddWithValue("@offset", offset);
        cmd.Parameters.AddWithValue("@limit", limit);

        if (dto.GroupId.HasValue)
            cmd.Parameters.AddWithValue("@groupId", dto.GroupId.Value);

        if (dto.StartDate.HasValue && dto.EndDate.HasValue)
        {
            cmd.Parameters.AddWithValue("@start", dto.StartDate.Value);
            cmd.Parameters.AddWithValue("@end", dto.EndDate.Value);
        }

        await using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            list.Add(new Attendance
            {
                Id = reader.GetGuid(reader.GetOrdinal("id")),
                UserId = reader.GetGuid(reader.GetOrdinal("user_id")),
                GroupId = reader.GetGuid(reader.GetOrdinal("group_id")),
                SessionDate = reader.GetDateTime(reader.GetOrdinal("session_date")),
                QrCodeId =  reader.GetGuid(reader.GetOrdinal("qrcode_id")),
                AttendanceType = reader.GetString(reader.GetOrdinal("attendance_type"))
            });
        }

        return list;
    }

    // Count total user attendance (for pagination)
    public async Task<int> GetUserAttendanceCountAsync(
      Guid userId,
      UserAttendanceFilterDTO dto)
    {
        await using var conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        var sql = @"
        SELECT COUNT(1)
        FROM yesattendance
        WHERE user_id = @userId
    ";

        if (dto.GroupId.HasValue)
            sql += " AND group_id = @groupId";

        if (dto.StartDate.HasValue && dto.EndDate.HasValue)
            sql += " AND session_date BETWEEN @start AND @end";

        await using var cmd = new NpgsqlCommand(sql, conn);

        cmd.Parameters.AddWithValue("@userId", userId);

        if (dto.GroupId.HasValue)
            cmd.Parameters.AddWithValue("@groupId", dto.GroupId.Value);

        if (dto.StartDate.HasValue && dto.EndDate.HasValue)
        {
            cmd.Parameters.AddWithValue("@start", dto.StartDate.Value);
            cmd.Parameters.AddWithValue("@end", dto.EndDate.Value);
        }

        return Convert.ToInt32(await cmd.ExecuteScalarAsync());
    }
    public Task<Attendance> GetByIdAsync(Guid id)
    {
        throw new NotImplementedException();
    }

    public async Task<(List<AttendanceDto>, int)> GetAttendancesAsync(AttendanceFilterDto filter)
    {
        try
        {

            var attendances = new List<AttendanceDto>();
            int total = 0;
            int offset = (filter.Page - 1) * filter.Limit;

            using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            // Dynamic sorting
            var orderBy = "marked_at DESC";
            if (!string.IsNullOrWhiteSpace(filter.Sort))
            {
                var fields = filter.Sort.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
                var orders = fields.Select(f =>
                {
                    var dir = f.StartsWith("-") ? "DESC" : "ASC";
                    var name = f.TrimStart('-');
                    return $"{name} {dir}";
                });
                orderBy = string.Join(", ", orders);
            }

            // Build SQL with optional joins
            string sql = @"
            SELECT 
    a.*,

    g.id AS group_id,
    g.group_name,
    g.group_type AS group_type,
    g.color,
    g.instructor_id,

    u.id AS user_id,
    u.first_name,
    u.last_name,

    q.email,

    i.id AS instructor_user_id,
    i.first_name AS instructor_first_name,
    i.last_name AS instructor_last_name

FROM yesattendance a
LEFT JOIN yesgroups g ON g.id = a.group_id
LEFT JOIN user_profiles u ON u.id = a.user_id
LEFT JOIN user_profiles i ON i.id = g.instructor_id
LEFT JOIN yes_users q ON q.id = a.user_id

ORDER BY " + orderBy + @"
LIMIT @Limit OFFSET @Offset;

SELECT COUNT(*) FROM yesattendance;

        ";

            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@Limit", filter.Limit);
            cmd.Parameters.AddWithValue("@Offset", offset);

            using var reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                attendances.Add(new AttendanceDto
                {
                    _id = reader.GetGuid(reader.GetOrdinal("id")),
                    Id = reader.GetGuid(reader.GetOrdinal("id")),
                    MarkedAt = reader.GetDateTime(reader.GetOrdinal("marked_at")),
                    Group = reader.IsDBNull(reader.GetOrdinal("group_id"))
        ? null
        : new GroupDto
        {
            _id = reader.GetGuid(reader.GetOrdinal("group_id")),   // Node.js compatible
            id = reader.GetGuid(reader.GetOrdinal("group_id")),
            group_name = reader.IsDBNull(reader.GetOrdinal("group_name"))
                ? null
                : reader.GetString(reader.GetOrdinal("group_name")),
            groupType = reader.IsDBNull(reader.GetOrdinal("group_type"))
                ? null
                : reader.GetString(reader.GetOrdinal("group_type")),

            InstructorAttendanceDto = reader.IsDBNull(reader.GetOrdinal("instructor_user_id"))
                ? null
                : new InstructorAttenDto
                {
                    _id = reader.GetGuid(reader.GetOrdinal("instructor_user_id")),
                    FirstName = reader.IsDBNull(reader.GetOrdinal("instructor_first_name"))
                        ? null
                        : reader.GetString(reader.GetOrdinal("instructor_first_name")),
                    LastName = reader.IsDBNull(reader.GetOrdinal("instructor_last_name"))
                        ? null
                        : reader.GetString(reader.GetOrdinal("instructor_last_name")),
                    Email = reader.IsDBNull(reader.GetOrdinal("email"))
                        ? null
                        : reader.GetString(reader.GetOrdinal("email"))
                }
        },

                    User = reader.IsDBNull(reader.GetOrdinal("user_id")) ? null : new UserDto
                    {
                        _id = reader.GetGuid(reader.GetOrdinal("user_id")),
                        FirstName = reader.GetString(reader.GetOrdinal("first_name")),
                        LastName = reader.GetString(reader.GetOrdinal("last_name")),
                        Email = reader.GetString(reader.GetOrdinal("email"))
                    }
                });
            }

            if (await reader.NextResultAsync() && await reader.ReadAsync())
            {
                total = reader.GetInt32(0);
            }

            return (attendances, total);
        }

        catch(Exception ex)
        {
            throw new Exception(ex.Message);
        }


    }
}

    // Helper to convert TimeSpan to DateTime for today
    public static class TimeSpanExtensions
{
    public static DateTime ToDateTime(this TimeSpan ts) => DateTime.Today.Add(ts);
}
