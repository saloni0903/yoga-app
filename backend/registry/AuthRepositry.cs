using Npgsql;
using System.Text.Json;
using yesmain.DTOs;

public class AuthRepositry : IAuthRepositry
{
    private readonly string _connectionString;

    public AuthRepositry(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")!;
    }

    public async Task CreateUserAsyncRepo(UserRequestDto user)
    {
        await using var conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        await using var tx = await conn.BeginTransactionAsync();

        try
        {
            // 1️⃣ yes_users
            const string userSql = @"
                INSERT INTO yes_users (id, email, role, created_at)
                VALUES (@id, @email, @role, @created_at)";

            await using (var cmd = new NpgsqlCommand(userSql, conn, tx))
            {
                cmd.Parameters.AddWithValue("id", user.Id);
                cmd.Parameters.AddWithValue("email", user.Email.ToLower());
                cmd.Parameters.AddWithValue("role", user.Role);
                cmd.Parameters.AddWithValue("created_at", user.CreatedAt);
                await cmd.ExecuteNonQueryAsync();
            }

            // 2️⃣ user_credentials
            const string credentialSql = @"
                INSERT INTO user_credentials
                (id, password_hash, fcm_tokens)
                VALUES
                (@user_id, @password, @fcm_tokens)";

            await using (var cmd = new NpgsqlCommand(credentialSql, conn, tx))
            {
                cmd.Parameters.AddWithValue("user_id", user.Id);
                cmd.Parameters.AddWithValue(
                    "password",
                    BCrypt.Net.BCrypt.HashPassword(user.Password)
                );
                var fcmTokensJson = JsonSerializer.Serialize(user.FcmTokens);

                cmd.Parameters.Add(
                    new NpgsqlParameter("fcm_tokens", NpgsqlTypes.NpgsqlDbType.Jsonb)
                    {
                        Value = fcmTokensJson
                    });
                await cmd.ExecuteNonQueryAsync();
            }

            // 3️⃣ user_profiles
            const string profileSql = @"
                INSERT INTO user_profiles
                (id, first_name, last_name, phone, samagra_id,
                 location, status, is_active, created_at, updated_at)
                VALUES
                (@user_id, @first_name, @last_name, @phone, @samagra_id,
                 @location, @status, @is_active, @created_at, @updated_at)";

            await using (var cmd = new NpgsqlCommand(profileSql, conn, tx))
            {
                cmd.Parameters.AddWithValue("user_id", user.Id);
                cmd.Parameters.AddWithValue("first_name", user.FirstName);
                cmd.Parameters.AddWithValue("last_name", user.LastName);
                cmd.Parameters.AddWithValue("phone", (object?)user.Phone ?? DBNull.Value);
                cmd.Parameters.AddWithValue("samagra_id", (object?)user.SamagraId ?? DBNull.Value);
                cmd.Parameters.AddWithValue("location", user.Location);
                cmd.Parameters.AddWithValue("status", user.Status);
                cmd.Parameters.AddWithValue("is_active", user.IsActive);
                cmd.Parameters.AddWithValue("created_at", user.CreatedAt);
                cmd.Parameters.AddWithValue("updated_at", user.UpdatedAt);
                await cmd.ExecuteNonQueryAsync();
            }

            await tx.CommitAsync();
        }
        catch
        {
            await tx.RollbackAsync();
            throw;
        }
    }

    public async Task<YesUser> LoginUserAsyncRepo(LoginDto dto)
    {
        try
        {
            const string sql = @"
            SELECT 
                u.id, 
                u.email, 
                u.role, 
                u.created_at, 
                c.password_hash
            FROM yes_users u
            INNER JOIN user_credentials c ON c.id = u.id
            WHERE LOWER(u.email) = @email;
        ";

            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("email", dto.Email.Trim().ToLower());

            await using var reader = await cmd.ExecuteReaderAsync();

            if (!await reader.ReadAsync())
                throw new UnauthorizedAccessException("Invalid credentials");

            var passwordHash = reader.GetString(4);

            if (!BCrypt.Net.BCrypt.Verify(dto.Password, passwordHash))
                throw new UnauthorizedAccessException("Invalid credentials");

            return new YesUser
            {
                Id = reader.GetGuid(0),
                Email = reader.GetString(1),
                Role = reader.GetString(2),
                CreatedAt = reader.GetDateTime(3)
            };
        }
        catch (UnauthorizedAccessException)
        {
            // Preserve auth errors exactly
            throw;
        }
        catch (PostgresException ex)
        {
            // Database-specific issues
            throw new Exception("Database error during login", ex);
        }
        catch (Exception ex)
        {
            // Fallback (unexpected errors)
            throw new Exception("Login failed", ex);
        }
    }

    public async Task<UserProfileResponseDto> GetProfileAsyncRepo(Guid userId)
    {
        const string sql = @"
        SELECT
            u.id,
            u.email,
            u.role,
            p.first_name,
            p.last_name,
            p.phone,
            p.samagra_id,
            p.location,
            p.status
        FROM yes_users u
        LEFT JOIN user_profiles p ON p.id = u.id
        WHERE u.id = @userId;
    ";

        await using var conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        await using var cmd = new NpgsqlCommand(sql, conn);
        cmd.Parameters.AddWithValue("@userId", userId);

        await using var reader = await cmd.ExecuteReaderAsync();

        if (!await reader.ReadAsync())
            throw new UnauthorizedAccessException("Invalid user");

        return new UserProfileResponseDto
        {
            Id = reader.GetGuid(0),
            Email = reader.GetString(1),
            Role = reader.GetString(2),
            FirstName = reader.IsDBNull(3) ? null : reader.GetString(3),
            LastName = reader.IsDBNull(4) ? null : reader.GetString(4),
            Phone = reader.IsDBNull(5) ? null : reader.GetString(5),
            SamagraId = reader.IsDBNull(6) ? null : reader.GetString(6),
            Location = reader.IsDBNull(7) ? null : reader.GetString(7),
            Status = reader.IsDBNull(8) ? null : reader.GetString(8)
        };
    }

    public async Task<UserProfileResponseDto> UpdateProfileAsyncRepo(
        Guid userId,
        UpdateProfileRequest dto)
    {
        try
        {

        await using var conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        var setClauses = new List<string>();
        var cmd = new NpgsqlCommand { Connection = conn };

        if (dto.FirstName != null)
        {
            setClauses.Add("first_name = @first_name");
            cmd.Parameters.AddWithValue("first_name", dto.FirstName);
        }

        if (dto.LastName != null)
        {
            setClauses.Add("last_name = @last_name");
            cmd.Parameters.AddWithValue("last_name", dto.LastName);
        }

        if (dto.Phone != null)
        {
            setClauses.Add("phone = @phone");
            cmd.Parameters.AddWithValue("phone", dto.Phone);
        }

        if (dto.Location != null)
        {
            setClauses.Add("location = @location");
            cmd.Parameters.AddWithValue("location", dto.Location);
        }

        if (setClauses.Count == 0)
            throw new ArgumentException("No fields provided");

        cmd.CommandText = $@"
            UPDATE user_profiles
            SET {string.Join(", ", setClauses)}, updated_at = NOW()
            WHERE user_id = @userId
            RETURNING first_name, last_name, phone, samagra_id,location";

        cmd.Parameters.AddWithValue("userId", userId);

        await using var reader = await cmd.ExecuteReaderAsync();

        if (!await reader.ReadAsync())
            throw new Exception("Profile not found");

        return new UserProfileResponseDto
        {
            Id = userId,
            FirstName = reader.GetString(0),
            LastName = reader.GetString(1),
            Phone = reader.IsDBNull(2) ? null : reader.GetString(2),
            SamagraId = reader.IsDBNull(3) ? null : reader.GetString(3),
            Location = reader.IsDBNull(4) ? null : reader.GetString(4)
        };
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<string> ForgotPasswordAsyncRepo(ForgotRequestDto dto)
    {
        try
        {

            var otp = "123456";

            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            var cmd = new NpgsqlCommand(@"
            UPDATE user_credentials c
            SET c.reset_password_otp = @otp,
                c.reset_password_expires = @exp
            FROM yes_users u
            WHERE u.id = c.id
            AND u.email = @email", conn);

            cmd.Parameters.AddWithValue("otp", otp);
            cmd.Parameters.AddWithValue("exp", DateTime.UtcNow.AddMinutes(10));
            cmd.Parameters.AddWithValue("email", dto.Email.ToLower());

            await cmd.ExecuteNonQueryAsync();

            return otp;
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<string> ResetPasswordAsyncRepo(RequestPasswordDto dto)
    {
        try
        {

        await using var conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        var hash = BCrypt.Net.BCrypt.HashPassword(dto.Password);

        var cmd = new NpgsqlCommand(@"
            UPDATE user_credentials c
            SET password_hash = @password,
                reset_password_otp = NULL,
                reset_password_expires = NULL
            FROM yes_users u
            WHERE u.id = c.id
            AND u.email = @email
            AND c.reset_password_otp = @otp
            AND c.reset_password_expires > NOW()", conn);

        cmd.Parameters.AddWithValue("password", hash);
        cmd.Parameters.AddWithValue("email", dto.Email.ToLower());
        cmd.Parameters.AddWithValue("otp", dto.otp);

        var rows = await cmd.ExecuteNonQueryAsync();

        return rows == 0
            ? "Invalid or expired OTP"
            : "Password reset successful";
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }
}
