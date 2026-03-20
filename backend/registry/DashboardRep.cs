using Npgsql;
using yesmain.DTOs;

public class DashboardRepository : IDashboardRepository
{
    private readonly string _connectionString;

    public DashboardRepository(IConfiguration config)
    {
        _connectionString = config.GetConnectionString("DefaultConnection");
    }

    public async Task<UserStatsDto?> GetUserStatsAsync(Guid userId)
    {
        try
        {

        const string sql = """
            SELECT id,
                   first_name,
                   current_streak,
                   total_minutes_practiced,
                   total_sessions_attended
            FROM yesusers
            WHERE id = @UserId;
        """;

        await using var conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        await using var cmd = new NpgsqlCommand(sql, conn);
        cmd.Parameters.AddWithValue("@UserId", userId);

        await using var reader = await cmd.ExecuteReaderAsync();

        if (!await reader.ReadAsync())
            return null;

        return new UserStatsDto
        {
            Id = reader.GetGuid(reader.GetOrdinal("id")),
            FirstName = reader.GetString(reader.GetOrdinal("first_name")),
            CurrentStreak = reader.GetInt32(reader.GetOrdinal("current_streak")),
            TotalMinutesPracticed = reader.GetInt32(reader.GetOrdinal("total_minutes_practiced")),
            TotalSessionsAttended = reader.GetInt32(reader.GetOrdinal("total_sessions_attended"))
        };
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<List<RecentAttendanceDto>> GetRecentAttendanceAsync(Guid userId)
    {
        try
        {

        const string sql = """
            SELECT id,
                   session_date,
                   attendance_type,
                   session_duration
            FROM yesattendance
            WHERE user_id = @UserId
            ORDER BY session_date DESC
            LIMIT 7;
        """;

        var result = new List<RecentAttendanceDto>();

        await using var conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        await using var cmd = new NpgsqlCommand(sql, conn);
        cmd.Parameters.AddWithValue("@UserId", userId);

        await using var reader = await cmd.ExecuteReaderAsync();

        while (await reader.ReadAsync())
        {
            result.Add(new RecentAttendanceDto
            {
                Id = reader.GetGuid(reader.GetOrdinal("id")),
                SessionDate = reader.GetDateTime(reader.GetOrdinal("session_date")),
                AttendanceType = reader.GetString(reader.GetOrdinal("attendance_type")),
                SessionDuration = reader.GetInt32(reader.GetOrdinal("session_duration"))
            });
        }

        return result;
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }
}
