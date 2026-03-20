using Npgsql;
using System.Text.Json;
using yesmain.Data;
using yesmain.Models;

public class SessionQRRepository : IQrSessionRepo
{
    private readonly string _connectionString;

    public SessionQRRepository(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")!;
    }

    public async Task InsertAsync(SessionQrCode qr)
    {
        try
        {

            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();
            const string sql = @"
            INSERT INTO session_qr_codes (id, group_id, token, session_date, expires_at, created_by,is_active, usage_count, max_usage,session_start_time, session_end_time,location_restriction, metadata)
            VALUES
            (@id,@group,@token,@date,@expires,@created,
             true,0,@max,@start,@end,@loc,@meta)
        ";
            await using var cmd = new NpgsqlCommand(sql, conn);

            cmd.Parameters.AddWithValue("id", qr.Id);
            cmd.Parameters.AddWithValue("group", qr.GroupId);
            cmd.Parameters.AddWithValue("token", qr.Token);
            cmd.Parameters.AddWithValue("date", qr.SessionDate);
            cmd.Parameters.AddWithValue("expires", qr.ExpiresAt);
            cmd.Parameters.AddWithValue("created", qr.CreatedBy);
            cmd.Parameters.AddWithValue("max", qr.MaxUsage);
            cmd.Parameters.AddWithValue("start", qr.SessionStartTime ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("end", qr.SessionEndTime ?? (object)DBNull.Value);
            cmd.Parameters.Add("loc", NpgsqlTypes.NpgsqlDbType.Jsonb)
               .Value = qr.LocationRestriction.RootElement.GetRawText();

            cmd.Parameters.Add("meta", NpgsqlTypes.NpgsqlDbType.Jsonb)
               .Value = qr.Metadata.RootElement.GetRawText();


            await cmd.ExecuteReaderAsync();
        }


        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<SessionQrCode?> GetByTokenAsync(string token)
    {
        try
        {

        await using var conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();
        await using var cmd = new NpgsqlCommand("""
            SELECT * FROM session_qr_codes
            WHERE token=@token AND is_active=true
        """, conn);

        cmd.Parameters.AddWithValue("token", token);

        using var r = await cmd.ExecuteReaderAsync();
        if (!await r.ReadAsync()) return null;

        return Map(r);
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task IncrementUsageAsync(Guid qrId)
    {
        try
        {

        await using var conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        await using var cmd = new NpgsqlCommand("""
            UPDATE session_qr_codes
            SET usage_count = usage_count + 1
            WHERE id=@id
        """, conn);

        cmd.Parameters.AddWithValue("id", qrId);
        await cmd.ExecuteNonQueryAsync();
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<List<SessionQrCode>> GetActiveForGroupAsync(
        Guid groupId, DateTime? sessionDate)
    {
        try
        {

        await using var conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        var sql = """
            SELECT * FROM session_qr_codes
            WHERE group_id=@group AND is_active=true
        """;

        if (sessionDate != null)
            sql += " AND session_date=@date";
        else
            sql += " AND session_date >= CURRENT_DATE";

        var cmd = new NpgsqlCommand(sql, conn);
        cmd.Parameters.AddWithValue("group", groupId);
        if (sessionDate != null)
            cmd.Parameters.AddWithValue("date", sessionDate.Value);

        var list = new List<SessionQrCode>();
        using var r = await cmd.ExecuteReaderAsync();
        while (await r.ReadAsync())
            list.Add(Map(r));

        return list;
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task DeactivateAsync(Guid id)
    {
        try
        {

        await using var conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        var cmd = new NpgsqlCommand("""
            UPDATE session_qr_codes SET is_active=false WHERE id=@id
        """, conn);

        cmd.Parameters.AddWithValue("id", id);
        await cmd.ExecuteNonQueryAsync();
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    private static SessionQrCode Map(NpgsqlDataReader r) => new()
    {
        Id = r.GetGuid(r.GetOrdinal("id")),
        GroupId = r.GetGuid(r.GetOrdinal("group_id")),
        Token = r.GetString(r.GetOrdinal("token")),
        SessionDate = (r.GetDateTime(r.GetOrdinal("session_date"))),
        ExpiresAt = r.GetDateTime(r.GetOrdinal("expires_at")),
        CreatedBy = r.GetGuid(r.GetOrdinal("created_by")),
        IsActive = r.GetBoolean(r.GetOrdinal("is_active")),
        UsageCount = r.GetInt32(r.GetOrdinal("usage_count")),
        MaxUsage = r.GetInt32(r.GetOrdinal("max_usage")),
        SessionStartTime = r["session_start_time"] as DateTime?,
        SessionEndTime = r["session_end_time"] as DateTime?,
        LocationRestriction = JsonDocument.Parse(
            r.GetString(r.GetOrdinal("location_restriction"))),
        Metadata = JsonDocument.Parse(
            r.GetString(r.GetOrdinal("metadata")))
    };
}
