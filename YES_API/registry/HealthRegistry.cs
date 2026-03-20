using Npgsql;
using System.Text.Json;
using yesmain.DTOs;
using yesmain.Models;
using yesmain.Registry.Interfaces;

namespace yesmain.Registry
{
    public class HealthRegistry : IHealthRepo
    {
        private readonly string _connectionString;

        public HealthRegistry(IConfiguration config)
        {
            _connectionString = config.GetConnectionString("DefaultConnection");
        }

        public async Task<Guid> CreateHealthReport(HealthProfile health)
        {
            health.Id = Guid.NewGuid();
            health.Date = DateTime.UtcNow;

            const string insertSql = @"
        INSERT INTO health_profiles (id, user_id, responses, total_score, date)
        VALUES (@Id, @UserId, @Responses, @TotalScore, @Date);
    ";

            const string updateSql = @"
        UPDATE user_profiles
        SET is_health_profile_completed = TRUE
        WHERE id = @UserId;
    ";

            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            await using var tx = await conn.BeginTransactionAsync();
            try
            {
                await using var insertCmd = new NpgsqlCommand(insertSql, conn, tx);
                insertCmd.Parameters.AddWithValue("Id", health.Id);
                insertCmd.Parameters.AddWithValue("UserId", health.UserId);
                insertCmd.Parameters.Add(new NpgsqlParameter("Responses", NpgsqlTypes.NpgsqlDbType.Jsonb)
                {
                    Value = JsonSerializer.Serialize(health.Responses)
                }); insertCmd.Parameters.AddWithValue("TotalScore", health.TotalScore ?? (object)DBNull.Value);
                insertCmd.Parameters.AddWithValue("Date", health.Date);

                await insertCmd.ExecuteNonQueryAsync();

                await using var updateCmd = new NpgsqlCommand(updateSql, conn, tx);
                updateCmd.Parameters.AddWithValue("UserId", health.UserId);
                await updateCmd.ExecuteNonQueryAsync();

                await tx.CommitAsync();

                return health.Id;
            }
            catch
            {
                await tx.RollbackAsync();
                throw;
            }
        }

        public async Task<List<HealthResponseDto>> GetHealthReport()
        {
            try
            {
                const string sql = @"
            SELECT
    h.id AS health_id,
    h.user_id,
    h.responses,
    h.total_score,
    h.date,

    p.first_name,
    p.last_name,
    p.phone,

    u.email
FROM health_profiles h
LEFT JOIN user_profiles p ON h.user_id = p.id
LEFT JOIN yes_users u ON h.user_id = u.id
ORDER BY h.date DESC
        ";

                await using var conn = new NpgsqlConnection(_connectionString);
                await conn.OpenAsync();

                await using var cmd = new NpgsqlCommand(sql, conn);

                await using var reader = await cmd.ExecuteReaderAsync();

                var healthReport = new List<HealthResponseDto>();

                while (await reader.ReadAsync())
                {
                    var user = new UserHealthDto
                    {
                        Id = reader.GetGuid(reader.GetOrdinal("user_id")),

                        FirstName = reader.IsDBNull(reader.GetOrdinal("first_name"))
                            ? string.Empty
                            : reader.GetString(reader.GetOrdinal("first_name")),

                        LastName = reader.IsDBNull(reader.GetOrdinal("last_name"))
                            ? string.Empty
                            : reader.GetString(reader.GetOrdinal("last_name")),

                        Email = reader.IsDBNull(reader.GetOrdinal("email"))
                            ? string.Empty
                            : reader.GetString(reader.GetOrdinal("email")),

                        Phone = reader.IsDBNull(reader.GetOrdinal("phone"))
                            ? null
                            : reader.GetString(reader.GetOrdinal("phone"))
                    };

                    var profile = new HealthResponseDto
                    {
                        Id = reader.GetGuid(reader.GetOrdinal("health_id")),
                        UserId = reader.GetGuid(reader.GetOrdinal("user_id")),

                        Responses = JsonDocument.Parse(
                            reader.GetString(reader.GetOrdinal("responses"))
                        ),

                        TotalScore = reader.IsDBNull(reader.GetOrdinal("total_score"))
                            ? null
                            : reader.GetInt32(reader.GetOrdinal("total_score")),

                        Date = reader.GetDateTime(reader.GetOrdinal("date")),
                        User = user
                    };

                    healthReport.Add(profile);
                }


                return healthReport;
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

    }
}

