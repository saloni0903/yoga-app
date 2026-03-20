using Npgsql;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using yesmain.DTOs;
using yesmain.Registry;

namespace yesmain.Registry
{
    public class UserRepository : IUserRepository
    {
        private readonly string _connectionString;

        public UserRepository(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")!;
        }

        public async Task<List<UserResponseDto>> GetAllListAsync()
        {
            try
            {

            const string sql = "SELECT * FROM yesusers";
            var users = new List<UserResponseDto>();

            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(sql, conn);
            await using var reader = await cmd.ExecuteReaderAsync();

            while (await reader.ReadAsync())
                users.Add(MapToUserResponseDto(reader));

            return users;
            }

            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        public async Task<List<UserResponseDto>> GetAllLocationListAsync(string location)
        {
            try
            {

            const string sql = "SELECT * FROM yesusers WHERE location = @location";
            var users = new List<UserResponseDto>();

            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@location", location);

            await using var reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
                users.Add(MapToUserResponseDto(reader));

            return users;
            }

            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        public async Task<List<UserResponseDto>> GetAllInstructorByLocationListAsync(string location)
        {
            try
            {

            const string sql = "SELECT * FROM yesusers WHERE role = 'instructor' AND location = @location";
            var users = new List<UserResponseDto>();

            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@location", location);

            await using var reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
                users.Add(MapToUserResponseDto(reader));

            return users;
            }

            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        public async Task<UserResponseDto?> GetByIdRepoAsync(Guid id)
        {
            try
            {

            const string sql = "SELECT * FROM yesusers WHERE id = @id LIMIT 1";

            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@id", id);

            await using var reader = await cmd.ExecuteReaderAsync();
            if (!await reader.ReadAsync()) return null;

            return MapToUserResponseDto(reader);
            }

            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        public async Task<UserResponseDto?> UpdateListAsync(Guid id, UserRequestDto dto)
        {
            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            await using var tran = await conn.BeginTransactionAsync();

            try
            {
                // 1️⃣ Update user_profiles
                const string sqlProfiles = @"
            UPDATE user_profiles
            SET first_name = @firstname,
                last_name = @lastname,
                phone = @phone,
                samagra_id = @samagra_id,
                location = @location,
                is_active = @isactive,
                emergency_contact = @emergency_contact,
                medical_info = @medical_info,
                preferences = @preferences,
                status = @status,
                updated_at = NOW()
            WHERE id = @id
            RETURNING *";

                await using var cmdProfiles = new NpgsqlCommand(sqlProfiles, conn, tran);

                cmdProfiles.Parameters.AddWithValue("@id", id);
                cmdProfiles.Parameters.AddWithValue("@firstname", dto.FirstName ?? (object)DBNull.Value);
                cmdProfiles.Parameters.AddWithValue("@lastname", dto.LastName ?? (object)DBNull.Value);
                cmdProfiles.Parameters.AddWithValue("@phone", dto.Phone ?? (object)DBNull.Value);
                cmdProfiles.Parameters.AddWithValue("@samagra_id", dto.SamagraId ?? (object)DBNull.Value);
                cmdProfiles.Parameters.AddWithValue("@location", dto.Location ?? (object)DBNull.Value);
                cmdProfiles.Parameters.AddWithValue("@isactive", dto.IsActive);
                cmdProfiles.Parameters.AddWithValue("@emergency_contact", dto.EmergencyContact ?? (object)DBNull.Value);
                cmdProfiles.Parameters.AddWithValue("@medical_info", dto.MediacalInfo ?? (object)DBNull.Value);
                cmdProfiles.Parameters.AddWithValue("@preferences", dto.Preferences ?? (object)DBNull.Value);
                cmdProfiles.Parameters.AddWithValue("@status", dto.Status);

                UserResponseDto? user = null;

                await using (var reader = await cmdProfiles.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                        user = MapToUserResponseDto(reader);
                }

                // 2️⃣ Update fcm_tokens in user_credentials
                if (dto.FcmTokens != null)
                {
                    const string sqlFcm = @"
                UPDATE user_credentials
                SET fcm_tokens = @fcmtokens,
                    updated_at = NOW()
                WHERE id = @id";

                    await using var cmdFcm = new NpgsqlCommand(sqlFcm, conn, tran);
                    cmdFcm.Parameters.AddWithValue("@id", id);
                    cmdFcm.Parameters.Add(
                        new NpgsqlParameter
                        {
                            ParameterName = "@fcmtokens",
                            NpgsqlDbType = NpgsqlTypes.NpgsqlDbType.Array | NpgsqlTypes.NpgsqlDbType.Text,
                            Value = dto.FcmTokens
                        }
                    );

                    await cmdFcm.ExecuteNonQueryAsync();
                }

                // ✅ Commit transaction
                await tran.CommitAsync();

                return user;
            }
            catch
            {
                await tran.RollbackAsync();
                throw;
            }
        }

        public async Task<bool> DeleteListAsync(Guid id)
        {
            try
            {

            const string sql = "DELETE FROM yesusers WHERE id = @id";

            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@id", id);

            return await cmd.ExecuteNonQueryAsync() > 0;
            }

            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
            
        }

        private static UserResponseDto MapToUserResponseDto(NpgsqlDataReader reader)
        {
            return new UserResponseDto
            {
                FirstName = reader.GetString(reader.GetOrdinal("first_name")),
                LastName = reader.GetString(reader.GetOrdinal("last_name")),
                Phone = reader.IsDBNull(reader.GetOrdinal("phone")) ? string.Empty : reader.GetString(reader.GetOrdinal("phone")),
                SamagraId = reader.IsDBNull(reader.GetOrdinal("samagra_id")) ? string.Empty : reader.GetString(reader.GetOrdinal("samagra_id")),
                Location = reader.GetString(reader.GetOrdinal("location")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("is_active")),
                Status = reader.GetString(reader.GetOrdinal("status")),
                CreatedAt = reader.GetDateTime(reader.GetOrdinal("created_at")),
                UpdatedAt = reader.GetDateTime(reader.GetOrdinal("updated_at"))
            };
        }
    }
}
