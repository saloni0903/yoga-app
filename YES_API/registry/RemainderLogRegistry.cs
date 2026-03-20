using Npgsql;
using System;
using System.Collections.Generic;
using Microsoft.Extensions.Configuration;
using System.Linq.Expressions;

public class ReminderLogRepository
{
    private readonly string _connectionString;

    public ReminderLogRepository(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")!;
    }

    private NpgsqlConnection GetConnection()
        => new NpgsqlConnection(_connectionString);

    // INSERT reminder log (ignore duplicates)
    public bool InsertReminderLog(ReminderLogDto log)
    {
        try
        {

            using var conn = GetConnection();
            conn.Open();

            var sql = @"
INSERT INTO reminder_logs
    (id, group_id, session_date_iso, reminder_type, created_at, updated_at)
VALUES
    (@id, @group_id, @session_date_iso, @reminder_type, @created_at, @updated_at)
ON CONFLICT (group_id, session_date_iso, reminder_type)
DO NOTHING;
";

            using var cmd = new NpgsqlCommand(sql, conn);

            cmd.Parameters.AddWithValue("id", log.Id);
            cmd.Parameters.AddWithValue("group_id", log.GroupId);
            cmd.Parameters.AddWithValue("session_date_iso", log.SessionDateISO);
            cmd.Parameters.AddWithValue("reminder_type", log.ReminderType);
            cmd.Parameters.AddWithValue("created_at", log.CreatedAt);
            cmd.Parameters.AddWithValue("updated_at", log.UpdatedAt);

            int affectedRows = cmd.ExecuteNonQuery();
            return affectedRows > 0; // false if duplicate
        }

        catch(Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    // GET reminder logs by group + reminder type
    public List<ReminderLogDto> GetReminderLogs(Guid groupId, string reminderType)
    {
        try { 
        var result = new List<ReminderLogDto>();

        using var conn = GetConnection();
        conn.Open();

        var sql = @"
SELECT 
    id,
    group_id,
    session_date_iso,
    reminder_type,
    created_at,
    updated_at
FROM reminder_logs
WHERE group_id = @group_id
  AND reminder_type = @reminder_type;
";

        using var cmd = new NpgsqlCommand(sql, conn);
        cmd.Parameters.AddWithValue("group_id", groupId);
        cmd.Parameters.AddWithValue("reminder_type", reminderType);

        using var reader = cmd.ExecuteReader();
        while (reader.Read())
        {
            result.Add(new ReminderLogDto
            {
                Id = reader.GetGuid(reader.GetOrdinal("id")),
                GroupId = reader.GetGuid(reader.GetOrdinal("group_id")),
                SessionDateISO = reader.GetString(reader.GetOrdinal("session_date_iso")),
                ReminderType = reader.GetString(reader.GetOrdinal("reminder_type")),
                CreatedAt = reader.GetDateTime(reader.GetOrdinal("created_at")),
                UpdatedAt = reader.GetDateTime(reader.GetOrdinal("updated_at"))
            });
        }

        return result;
        }

        catch(Exception ex)
        {
            throw new Exception(ex.Message);
        }

    

    }
}
