using Npgsql;

public class AdminRepository : IAdminRepository
{
    private readonly string _connectionString;

    public AdminRepository(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")!;
    }

    private NpgsqlConnection GetConnection()
        => new(_connectionString);

    public async Task<IEnumerable<UserResponseDto>> GetAllInstructorsAsync(GetInstructorDto dto)
    {
        const string sql = @"SELECT y.id, p.first_name, p.last_name, y.email, p.status,
                            p.created_at FROM yes_users y JOIN user_profiles p ON y.id = p.id
                            WHERE y.role = @Role AND p.status = COALESCE(@Status, p.status) 
                            ORDER BY p.created_at DESC LIMIT @Limit";

        try
        {
            var list = new List<UserResponseDto>();

            await using var conn = GetConnection();
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@Role", "instructor");
            cmd.Parameters.AddWithValue("@Status", string.IsNullOrEmpty(dto.Status)
                ? DBNull.Value
                : dto.Status);
            cmd.Parameters.AddWithValue("@Limit", dto.Limit);

            await using var reader = await cmd.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                list.Add(new UserResponseDto
                {
                    Id = reader.GetGuid(0),
                    FirstName = reader.GetString(1),
                    LastName = reader.GetString(2),
                    Email = reader.GetString(3),
                    Status = reader.GetString(4),
                    CreatedAt = reader.GetDateTime(5)
                });
            }

            return list;
        }
        catch(Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<bool> UpdateInstructorStatusAsync(Guid id, string status)
    {
        const string sql =
                @"UPDATE user_profiles p
            SET status = @status,
                updated_at = NOW()
            FROM yes_users u
            WHERE u.id = p.id
              AND u.id = @id
              AND u.role = 'instructor'; ";


        try
        {
            await using var conn = GetConnection();
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@id", id);
            cmd.Parameters.AddWithValue("@status", status);

            return await cmd.ExecuteNonQueryAsync() > 0;
        }
        catch(Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<bool> DeleteInstructorAsync(Guid id)
    {
        const string sql = """
            DELETE FROM yes_users
            WHERE id = @id
              AND role = 'instructor';
        """;

        try
        {
            await using var conn = GetConnection();
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@id", id);

            return await cmd.ExecuteNonQueryAsync() > 0;
        }
        catch(Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<DashboardStatsDto> GetDashboardStatsAsync()
    {
        const string sql = """
            SELECT
                (SELECT COUNT(*) FROM yes_users WHERE role = 'participant') AS participants,
                (SELECT COUNT(*) FROM yes_users WHERE role = 'instructor') AS instructors,
                (SELECT COUNT(*) FROM yesattendance WHERE marked_at::date = CURRENT_DATE) AS sessions_today,
                (SELECT COUNT(*) FROM yesattendance) AS total_attendance;
        """;

        try
        {
            await using var conn = GetConnection();
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(sql, conn);
            await using var reader = await cmd.ExecuteReaderAsync();

            await reader.ReadAsync();

            return new DashboardStatsDto
            {
                TotalParticipants = reader.GetInt32(0),
                TotalInstructors = reader.GetInt32(1),
                SessionsToday = reader.GetInt32(2),
                TotalAttendance = reader.GetInt32(3)
            };
        }
        catch(Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<IEnumerable<AttendanceOverTimeDto>> GetAttendanceOverTimeAsync(int period)
    {
        const string sql = """
            SELECT marked_at::date AS day, COUNT(*)::int
            FROM yesattendance
            WHERE marked_at >= CURRENT_DATE - make_interval(days => @days - 1)
            GROUP BY day
            ORDER BY day;
        """;

        try
        {
            var list = new List<AttendanceOverTimeDto>();

            await using var conn = GetConnection();
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@days", period);

            await using var reader = await cmd.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                list.Add(new AttendanceOverTimeDto
                {
                    Date = reader.GetDateTime(0),
                    Attendance = reader.GetInt32(1)
                });
            }

            return list;
        }
        catch(Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<IEnumerable<ActivityFeedDto>> GetActivityFeedAsync(int limit)
    {
        const string sql = """
            SELECT id, timestamp, type
            FROM (
                SELECT id, created_at AS timestamp, 'USER_REGISTERED' AS type
                FROM yes_users
                WHERE role = 'participant'

                UNION ALL

                SELECT u.id, p.updated_at AS timestamp, 'INSTRUCTOR_APPROVED'
                FROM yes_users u
                JOIN user_profiles p ON u.id = p.id
                WHERE u.role = 'instructor'
                  AND p.status = 'approved'
            ) t
            ORDER BY timestamp DESC
            LIMIT @limit;
        """;

        try
        {
            var list = new List<ActivityFeedDto>();

            await using var conn = GetConnection();
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@limit", limit);

            await using var reader = await cmd.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                list.Add(new ActivityFeedDto
                {
                    Id = reader.GetGuid(0),
                    Timestamp = reader.GetDateTime(1),
                    Type = reader.GetString(2)
                });
            }

            return list;
        }
        catch
        {
            throw;
        }
    }

    public async Task<IEnumerable<TopGroupDto>> GetTopGroupsAsync(int limit)
    {
        const string sql = """
            SELECT g.id, g.group_name, COUNT(a.id)::int
            FROM yesattendance a
            JOIN yesgroups g ON g.id = a.group_id
            WHERE a.marked_at >= CURRENT_DATE - INTERVAL '7 days'
            GROUP BY g.id, g.group_name
            ORDER BY COUNT(a.id) DESC
            LIMIT @limit;
        """;

        try
        {
            var list = new List<TopGroupDto>();

            await using var conn = GetConnection();
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@limit", limit);

            await using var reader = await cmd.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                list.Add(new TopGroupDto
                {
                    Id = reader.GetGuid(0),
                    Name = reader.GetString(1),
                    AttendanceCount = reader.GetInt32(2)
                });
            }

            return list;
        }
        catch(Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }
}
