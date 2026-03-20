using Npgsql;
using NpgsqlTypes;
using System.Data;
using System.Text.Json;
using yesmain.DTOs;
using yesmain.Models;
using Group = yesmain.Models.Group;

namespace yesmain.registry
{
    public class GroupRepository : IGroupRepo
    {
        private readonly string _connectionString;

        public GroupRepository(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")!;
        }


        public async Task CreateGroupAsync(Group group)
        {
            try
            {
                const string sql = @"
INSERT INTO yesgroups(
    id, instructor_id, group_type, group_name, location_address, latitude, longitude, schedule, color, description,
    yoga_style, difficulty_level, price_per_session, max_participants, meet_link, is_active, created_at, updated_at
)
VALUES (
    @Id, @InstructorId, @GroupType, @GroupName, @LocationAddress, @Latitude, @Longitude, @Schedule, @Color, @Description,
    @YogaStyle, @DifficultyLevel, @PricePerSession, @MaxParticipants, @MeetLink, @IsActive, @CreatedAt, @UpdatedAt
)";

                await using var conn = new NpgsqlConnection(_connectionString);
                await conn.OpenAsync();

                await using var cmd = new NpgsqlCommand(sql, conn);

                cmd.Parameters.AddWithValue("Id", group.Id);
                cmd.Parameters.AddWithValue("InstructorId", group.InstructorId);
                cmd.Parameters.AddWithValue("GroupType", group.GroupType ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("GroupName", group.GroupName ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("LocationAddress", group.LocationAddress ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("Latitude", group.Latitude ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("Longitude", group.Longitude ?? (object)DBNull.Value);
                cmd.Parameters.Add(new NpgsqlParameter("Schedule", NpgsqlDbType.Jsonb)
                {
                    Value = group.Schedule != null
                        ? JsonSerializer.Serialize(group.Schedule)
                        : DBNull.Value
                });
                cmd.Parameters.AddWithValue("Color", group.Color ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("Description", group.Description ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("YogaStyle", group.YogaStyle ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("DifficultyLevel", group.DifficultyLevel ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("PricePerSession", group.PricePerSession);
                cmd.Parameters.AddWithValue("MaxParticipants", group.MaxParticipants);
                cmd.Parameters.AddWithValue("MeetLink", group.MeetLink ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("IsActive", group.IsActive);
                cmd.Parameters.AddWithValue("CreatedAt", group.CreatedAt);
                cmd.Parameters.AddWithValue("UpdatedAt", group.UpdatedAt);

                await cmd.ExecuteNonQueryAsync();
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        public async Task<bool> DeleteGroupAsync(Guid id)
        {
            try
            {

                const string sql = @"DELETE FROM yesgroups WHERE id = @Id";

                await using var conn = new NpgsqlConnection(_connectionString);
                await conn.OpenAsync();

                await using var cmd = new NpgsqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@Id", id);

                var rowsAffected = await cmd.ExecuteNonQueryAsync();

                return rowsAffected > 0;
            }

            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        public async Task<GroupResponseDto?> GetByIdGroupAsync(Guid id)
        {
            const string sql = @"
SELECT *
FROM yesgroups
WHERE id = @Id";

            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@Id", id);

            await using var reader = await cmd.ExecuteReaderAsync();

            if (!await reader.ReadAsync()) return null;

            // Deserialize single schedule object
            GroupScheduleDto? schedule = null;
            var scheduleOrdinal = reader.GetOrdinal("schedule");
            if (!reader.IsDBNull(scheduleOrdinal))
            {
                var scheduleJson = reader.GetFieldValue<string>(scheduleOrdinal);
                if (!string.IsNullOrWhiteSpace(scheduleJson))
                {
                    try
                    {
                        schedule = JsonSerializer.Deserialize<GroupScheduleDto>(scheduleJson);
                    }
                    catch (JsonException ex)
                    {
                        throw new Exception($"Failed to deserialize schedule JSON for group {id}", ex);
                    }
                }
            }

            return new GroupResponseDto
            {
                Id = reader.GetGuid(reader.GetOrdinal("id")),
                InstructorId = reader.GetGuid(reader.GetOrdinal("instructor_id")),
                group_name = reader.GetString(reader.GetOrdinal("group_name")),
                GroupType = reader.GetString(reader.GetOrdinal("group_type")),
                LocationAddress = reader.IsDBNull(reader.GetOrdinal("location_address"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("location_address")),
                Latitude = reader.IsDBNull(reader.GetOrdinal("latitude"))
                    ? null
                    : reader.GetDouble(reader.GetOrdinal("latitude")),
                Longitude = reader.IsDBNull(reader.GetOrdinal("longitude"))
                    ? null
                    : reader.GetDouble(reader.GetOrdinal("longitude")),
                MeetLink = reader.IsDBNull(reader.GetOrdinal("meet_link"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("meet_link")),
                Schedule = schedule,
                Color = reader.GetString(reader.GetOrdinal("color")),
                YogaStyle = reader.GetString(reader.GetOrdinal("yoga_style")),
                DifficultyLevel = reader.GetString(reader.GetOrdinal("difficulty_level")),
                MaxParticipants = reader.GetInt32(reader.GetOrdinal("max_participants")),
                PricePerSession = reader.GetDecimal(reader.GetOrdinal("price_per_session")),
                Currency = reader.GetString(reader.GetOrdinal("currency")),
                Description = reader.IsDBNull(reader.GetOrdinal("description"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("description")),
                Requirements = reader.IsDBNull(reader.GetOrdinal("requirements"))
                    ? new List<string>()
                    : reader.GetFieldValue<string[]>(reader.GetOrdinal("requirements")).ToList(),
                EquipmentNeeded = reader.IsDBNull(reader.GetOrdinal("equipment_needed"))
                    ? new List<string>()
                    : reader.GetFieldValue<string[]>(reader.GetOrdinal("equipment_needed")).ToList(),
                IsActive = reader.GetBoolean(reader.GetOrdinal("is_active")),
                CreatedAt = reader.GetDateTime(reader.GetOrdinal("created_at")),
                UpdatedAt = reader.GetDateTime(reader.GetOrdinal("updated_at"))
            };
        }    //        public async Task<List<GroupResponseDto>> GetGroupsFitlerAsync(GroupFilterDto dto)
        //        {
        //            const string sql = @"SELECT *
        //FROM yesgroups
        //WHERE
        //    instructor_id = COALESCE(@InstructorId, instructor_id)
        //OR
        //    latitude  = COALESCE(@Latitude, latitude)
        //OR
        //    longitude = COALESCE(@Longitude, longitude)
        //OR
        //    (
        //        @Search IS NULL OR
        //        group_name ILIKE '%' || @Search || '%' OR
        //        location_address ILIKE '%' || @Search || '%' OR
        //        description ILIKE '%' || @Search || '%' OR
        //        yoga_style ILIKE '%' || @Search || '%'
        //    )
        //ORDER BY created_at DESC
        //LIMIT @Limit OFFSET @Offset;";

        //            var groups = new List<GroupResponseDto>();

        //            await using var conn = new NpgsqlConnection(_connectionString);
        //            await conn.OpenAsync();

        //            await using var cmd = new NpgsqlCommand(sql, conn);

        //            // 🔒 Explicit parameter typing (THIS FIXES 42P08)

        //            cmd.Parameters.Add("@InstructorId", NpgsqlDbType.Uuid).Value = dto.instructor_id;

        //            cmd.Parameters.Add("@Latitude", NpgsqlDbType.Numeric)
        //                .Value = dto.latitude ?? (object)DBNull.Value;

        //            cmd.Parameters.Add("@Longitude", NpgsqlDbType.Numeric)
        //                .Value = dto.longitude ?? (object)DBNull.Value;

        //            cmd.Parameters.Add("@Search", NpgsqlDbType.Text)
        //                .Value = string.IsNullOrWhiteSpace(dto.search)
        //                    ? DBNull.Value
        //                    : dto.search;

        //            cmd.Parameters.Add("@Limit", NpgsqlDbType.Integer).Value = dto.limit;
        //            cmd.Parameters.Add("@Offset", NpgsqlDbType.Integer)
        //                .Value = (dto.page - 1) * dto.limit;

        //            await using var reader = await cmd.ExecuteReaderAsync();

        //            while (await reader.ReadAsync())
        //            {
        //                groups.Add(new GroupResponseDto
        //                {
        //                    Id = reader.GetGuid(reader.GetOrdinal("id")),
        //                    GroupName = reader.GetString(reader.GetOrdinal("group_name")),
        //                    GroupType = reader.GetString(reader.GetOrdinal("group_type")),
        //                    Latitude = reader.IsDBNull(reader.GetOrdinal("latitude"))
        //                        ? null
        //                        : reader.GetDouble(reader.GetOrdinal("latitude")),
        //                    Longitude = reader.IsDBNull(reader.GetOrdinal("longitude"))
        //                        ? null
        //                        : reader.GetDouble(reader.GetOrdinal("longitude")),
        //                    Schedule = reader.GetString(reader.GetOrdinal("schedule")),
        //                    YogaStyle = reader.GetString(reader.GetOrdinal("yoga_style")),
        //                    DifficultyLevel = reader.GetString(reader.GetOrdinal("difficulty_level")),
        //                    Description = reader.IsDBNull(reader.GetOrdinal("description"))
        //                        ? null
        //                        : reader.GetString(reader.GetOrdinal("description")),
        //                    MaxParticipants = reader.GetInt32(reader.GetOrdinal("max_participants")),
        //                    PricePerSession = reader.GetDecimal(reader.GetOrdinal("price_per_session")),
        //                    Currency = reader.IsDBNull(reader.GetOrdinal("currency"))
        //                        ? null
        //                        : reader.GetString(reader.GetOrdinal("currency")),
        //                    Requirements = reader.IsDBNull(reader.GetOrdinal("requirements"))
        //                        ? null
        //                        : reader.GetFieldValue<string[]>(reader.GetOrdinal("requirements")).ToList(),
        //                    EquipmentNeeded = reader.IsDBNull(reader.GetOrdinal("equipment_needed"))
        //                        ? null
        //                        : reader.GetFieldValue<string[]>(reader.GetOrdinal("equipment_needed")).ToList(),
        //                    IsActive = reader.GetBoolean(reader.GetOrdinal("is_active")),
        //                    Color = reader.GetString(reader.GetOrdinal("color")),
        //                    MeetLink = reader.IsDBNull(reader.GetOrdinal("meet_link"))
        //                        ? null
        //                        : reader.GetString(reader.GetOrdinal("meet_link")),
        //                    CreatedAt = reader.GetDateTime(reader.GetOrdinal("created_at"))
        //                });
        //            }

        //            return groups;
        //        }
        public async Task<List<GroupDto>> GetOfflineGroupsAsync(GroupFilterDto dto)
        {
            try
            {
                var groups = new List<GroupDto>();

                const string sql = @"
SELECT *
FROM (
    SELECT 
        g.id,
        g.group_name,
        g.""group_type"" AS group_type,
        g.description,
        g.yoga_style,
        g.latitude,
        g.longitude,
        g.location_address,
        g.created_at,
        CASE 
            WHEN @Latitude IS NOT NULL AND @Longitude IS NOT NULL THEN
                6371000 * acos(
                    cos(radians(@Latitude)) * cos(radians(g.latitude)) *
                    cos(radians(g.longitude) - radians(@Longitude)) +
                    sin(radians(@Latitude)) * sin(radians(g.latitude))
                )
            ELSE NULL
        END AS distance,
        u.id AS instructor_id,
        u.first_name AS firstName,
        u.last_name AS lastName,
        q.email
    FROM yesgroups g
    LEFT JOIN user_profiles u ON u.id = g.instructor_id
    LEFT JOIN yes_users q ON q.id = g.instructor_id
    WHERE g.""group_type"" = 'offline'
      AND g.instructor_id = COALESCE(@InstructorId, g.instructor_id)
      AND (
          COALESCE(@Search, '') = ''
          OR g.group_name ILIKE '%' || @Search || '%'
          OR g.location_address ILIKE '%' || @Search || '%'
          OR g.description ILIKE '%' || @Search || '%'
          OR g.yoga_style ILIKE '%' || @Search || '%'
      )
      AND g.latitude IS NOT NULL
      AND g.longitude IS NOT NULL
) t
WHERE @Latitude IS NULL OR @Longitude IS NULL OR distance <= 2000000
ORDER BY created_at DESC;

";

                await using var conn = new NpgsqlConnection(_connectionString);
                await conn.OpenAsync();

                await using var cmd = new NpgsqlCommand(sql, conn);

                // Set parameters
                cmd.Parameters.AddWithValue("InstructorId", NpgsqlTypes.NpgsqlDbType.Uuid,
                    dto.instructor_id ?? (object)DBNull.Value);

                cmd.Parameters.AddWithValue("Latitude", NpgsqlTypes.NpgsqlDbType.Double,
                    dto.latitude ?? (object)DBNull.Value);

                cmd.Parameters.AddWithValue("Longitude", NpgsqlTypes.NpgsqlDbType.Double,
                    dto.longitude ?? (object)DBNull.Value);

                cmd.Parameters.AddWithValue("Search", NpgsqlTypes.NpgsqlDbType.Text,
                    string.IsNullOrWhiteSpace(dto.search) ? DBNull.Value : dto.search);

                await using var reader = await cmd.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    groups.Add(new GroupDto
                    {
                        _id = reader.GetGuid(reader.GetOrdinal("id")),
                        id = reader.GetGuid(reader.GetOrdinal("id")),
                        group_name = reader.GetString(reader.GetOrdinal("group_name")),
                        groupType = reader.GetString(reader.GetOrdinal("group_type")),
                        description = reader.IsDBNull(reader.GetOrdinal("description")) ? null : reader.GetString(reader.GetOrdinal("description")),
                        yoga_style = reader.IsDBNull(reader.GetOrdinal("yoga_style")) ? null : reader.GetString(reader.GetOrdinal("yoga_style")),
                        latitude = reader.IsDBNull(reader.GetOrdinal("latitude")) ? null : reader.GetDouble(reader.GetOrdinal("latitude")),
                        longitude = reader.IsDBNull(reader.GetOrdinal("longitude")) ? null : reader.GetDouble(reader.GetOrdinal("longitude")),
                        distance = reader.IsDBNull(reader.GetOrdinal("distance")) ? null : reader.GetDouble(reader.GetOrdinal("distance")),
                        location_address = reader.IsDBNull(reader.GetOrdinal("location_address")) ? null : reader.GetString(reader.GetOrdinal("location_address")),
                        location_text = reader.IsDBNull(reader.GetOrdinal("location_address")) ? null : reader.GetString(reader.GetOrdinal("location_address")),
                        created_at = reader.GetDateTime(reader.GetOrdinal("created_at")),

                        instructor_id = reader.IsDBNull(reader.GetOrdinal("instructor_id"))
                            ? null
                            : new InstructorDto
                            {
                                _id = reader.GetGuid(reader.GetOrdinal("instructor_id")),
                                FirstName = reader.GetString(reader.GetOrdinal("firstName")),
                                LastName = reader.GetString(reader.GetOrdinal("lastName")),
                                Email = reader.GetString(reader.GetOrdinal("email"))
                            }
                    });
                }

                return groups;
            }
            catch (Exception ex)
            {
                throw new Exception($"Error fetching offline groups: {ex.Message}", ex);
            }
        }


        public async Task<List<GroupDto>> GetOnlineGroupsAsync(GroupFilterDto dto)
        {
            var groups = new List<GroupDto>();

            const string sql = @"
    SELECT 
        g.id,
        g.group_name,
        g.""group_type"",
        g.description,
        g.yoga_style,
        g.created_at,

        g.instructor_id,

        u.first_name AS ""firstName"",
        u.last_name  AS ""lastName"",
        q.email      AS ""email""

    FROM yesgroups g
    LEFT JOIN user_profiles u 
        ON u.id = g.instructor_id
    LEFT JOIN yes_users q 
        ON q.id = g.instructor_id

    WHERE g.""group_type"" = 'online'
      AND (@InstructorId IS NULL OR g.instructor_id = @InstructorId)
      AND (
            @Search IS NULL OR
            g.group_name ILIKE '%' || @Search || '%' OR
            g.description ILIKE '%' || @Search || '%' OR
            g.yoga_style ILIKE '%' || @Search || '%'
      )

    ORDER BY g.created_at DESC;
";


            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(sql, conn);

            cmd.Parameters.Add("@InstructorId", NpgsqlDbType.Uuid)
                .Value = dto.instructor_id ?? (object)DBNull.Value;

            cmd.Parameters.Add("@Search", NpgsqlDbType.Text)
                .Value = string.IsNullOrWhiteSpace(dto.search)
                    ? DBNull.Value
                    : dto.search;

            await using var reader = await cmd.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {

                groups.Add(new GroupDto
                {
                    _id = reader.GetGuid(reader.GetOrdinal("id")),
                    id = reader.GetGuid(reader.GetOrdinal("id")),

                    group_name = reader.GetString(reader.GetOrdinal("group_name")),
                    groupType = reader.GetString(reader.GetOrdinal("group_type")),
                    description = reader.IsDBNull("description") ? null : reader.GetString("description"),
                    yoga_style = reader.IsDBNull("yoga_style") ? null : reader.GetString("yoga_style"),
                    created_at = reader.GetDateTime("created_at"),

                    instructor_id = reader.IsDBNull("instructor_id")
    ? null
    : new InstructorDto
    {
        _id = reader.GetGuid("instructor_id"),
        FirstName = reader.GetString("firstName"),
        LastName = reader.GetString("lastName"),
        Email = reader.GetString("email")
    }
                });
            }

            return groups;
        }

        public async Task<List<GroupResponseDto>> GetMyGroupListAsync(Guid userId)
        {
            const string sql = @"
        SELECT
            g.id,
            g.instructor_id,
            g.group_name,
            g.group_type,
            g.location_address,
            g.latitude,
            g.longitude,
            g.meet_link,
            g.schedule,
            g.yoga_style,
            g.difficulty_level,
            g.description,
            g.max_participants,
            g.price_per_session,
            g.currency,
            g.requirements,
            g.equipment_needed,
            g.is_active,
            g.color,
            g.created_at,
            g.updated_at
        FROM yesgroups g
        INNER JOIN yesgroupmembers gm ON gm.group_id = g.id
        WHERE gm.user_id = @UserId
        ORDER BY g.created_at DESC;
    ";

            var groups = new List<GroupResponseDto>();

            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("@UserId", userId);

            await using var reader = await cmd.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                var scheduleJson = reader.GetString(reader.GetOrdinal("schedule"));
                var schedule = JsonSerializer.Deserialize<GroupScheduleDto>(scheduleJson)!;


                groups.Add(new GroupResponseDto
                {
                    Id = reader.GetGuid(reader.GetOrdinal("id")),
                    InstructorId = reader.GetGuid(reader.GetOrdinal("instructor_id")),

                    // Core
                    group_name = reader.GetString(reader.GetOrdinal("group_name")),
                    GroupType = reader.GetString(reader.GetOrdinal("group_type")),

                    // Location
                    LocationAddress = reader.IsDBNull(reader.GetOrdinal("location_address"))
                        ? null
                        : reader.GetString(reader.GetOrdinal("location_address")),

                    Latitude = reader.IsDBNull(reader.GetOrdinal("latitude"))
                        ? null
                        : reader.GetDouble(reader.GetOrdinal("latitude")),

                    Longitude = reader.IsDBNull(reader.GetOrdinal("longitude"))
                        ? null
                        : reader.GetDouble(reader.GetOrdinal("longitude")),

                    // Online
                    MeetLink = reader.IsDBNull(reader.GetOrdinal("meet_link"))
                        ? null
                        : reader.GetString(reader.GetOrdinal("meet_link")),

                    // Schedule
                    Schedule = schedule, // <-- Single object

                    // UI
                    Color = reader.GetString(reader.GetOrdinal("color")),

                    // Session
                    YogaStyle = reader.GetString(reader.GetOrdinal("yoga_style")),
                    DifficultyLevel = reader.GetString(reader.GetOrdinal("difficulty_level")),
                    MaxParticipants = reader.GetInt32(reader.GetOrdinal("max_participants")),
                    PricePerSession = reader.GetDecimal(reader.GetOrdinal("price_per_session")),
                    Currency = reader.GetString(reader.GetOrdinal("currency")),

                    // Description
                    Description = reader.IsDBNull(reader.GetOrdinal("description"))
                        ? null
                        : reader.GetString(reader.GetOrdinal("description")),

                    // Arrays
                    Requirements = reader.IsDBNull(reader.GetOrdinal("requirements"))
                        ? new List<string>()
                        : reader.GetFieldValue<string[]>(reader.GetOrdinal("requirements")).ToList(),

                    EquipmentNeeded = reader.IsDBNull(reader.GetOrdinal("equipment_needed"))
                        ? new List<string>()
                        : reader.GetFieldValue<string[]>(reader.GetOrdinal("equipment_needed")).ToList(),

                    // Status
                    IsActive = reader.GetBoolean(reader.GetOrdinal("is_active")),

                    // Audit
                    CreatedAt = reader.GetDateTime(reader.GetOrdinal("created_at")),
                    UpdatedAt = reader.GetDateTime(reader.GetOrdinal("updated_at"))
                });
            }

            return groups;
        }

        public async Task<List<GroupMemberResponseDto>> GetGroupMemberListAsync(Guid groupId)
        {
            try
            {

                const string sql = @"SELECT * FROM yesgroupmembers WHERE group_id = @Id";
                var groups = new List<GroupMemberResponseDto>();

                await using var conn = new NpgsqlConnection(_connectionString);
                await conn.OpenAsync();

                await using var cmd = new NpgsqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@Id", groupId);

                await using var reader = await cmd.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    groups.Add(new GroupMemberResponseDto
                    {
                        Id = reader.GetGuid(reader.GetOrdinal("id")),
                        UserId = reader.GetGuid(reader.GetOrdinal("user_id")),
                        GroupId = reader.GetGuid(reader.GetOrdinal("group_id")),

                        JoinedAt = reader.GetDateTime(reader.GetOrdinal("joined_at")),
                        Status = reader.IsDBNull(reader.GetOrdinal("status"))
    ? null
    : reader.GetString(reader.GetOrdinal("status")),

                        Role = reader.IsDBNull(reader.GetOrdinal("role"))
    ? null
    : reader.GetString(reader.GetOrdinal("role")),

                        PaymentStatus = reader.IsDBNull(reader.GetOrdinal("payment_status"))
    ? null
    : reader.GetString(reader.GetOrdinal("payment_status")),

                        LastPaymentDate = reader.IsDBNull(reader.GetOrdinal("last_payment_date"))
    ? (DateTime?)null
    : reader.GetDateTime(reader.GetOrdinal("last_payment_date")),

                        NextPaymentDue = reader.IsDBNull(reader.GetOrdinal("next_payment_due"))
    ? (DateTime?)null
    : reader.GetDateTime(reader.GetOrdinal("next_payment_due")),

                        Notes = reader.IsDBNull(reader.GetOrdinal("notes"))
    ? null
    : reader.GetString(reader.GetOrdinal("notes")),

                        EmergencyContactJson = reader.IsDBNull(reader.GetOrdinal("emergency_contact"))
    ? null
    : JsonDocument.Parse(reader.GetString(reader.GetOrdinal("emergency_contact"))),

                        MedicalNotes = reader.IsDBNull(reader.GetOrdinal("medical_notes"))
    ? null
    : reader.GetString(reader.GetOrdinal("medical_notes")),

                        AttendanceCount = reader.IsDBNull(reader.GetOrdinal("attendance_count"))
    ? 0
    : reader.GetInt32(reader.GetOrdinal("attendance_count")),

                        LastAttended = reader.IsDBNull(reader.GetOrdinal("last_attended"))
    ? (DateTime?)null
    : reader.GetDateTime(reader.GetOrdinal("last_attended")),

                    });
                }

                return groups;
            }

            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        public async Task<bool> LeaveGroupAsync(Guid userId, Guid groupId)
        {
            try
            {

                const string sql = @"
        UPDATE yesgroupsmembers
        SET status = 'left'
        WHERE user_id = @UserId AND group_id = @GroupId;";

                await using var conn = new NpgsqlConnection(_connectionString);
                await conn.OpenAsync();

                await using var cmd = new NpgsqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@UserId", userId);
                cmd.Parameters.AddWithValue("@GroupId", groupId);

                var rowsAffected = await cmd.ExecuteNonQueryAsync();

                return rowsAffected > 0;
            }

            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }


        public async Task<UpdateGroupResDto> UpdateGroupAsync(Guid groupId, UpdateGroupReqDto dto)
        {
            try
            {

                const string sql = @"
        UPDATE yesgroups
        SET
            group_type = @GroupType,
            group_name = @GroupName,
            location = @Location,
            location_address = @LocationAddress,
            latitude = @Latitude,
            longitude = @Longitude,
            color = @Color,
            schedule = @Schedule,
            is_active = @IsActive,
            description = @Description,
            max_participants = @MaxParticipants,
            yoga_style = @YogaStyle,
            difficulty_level = @DifficultyLevel,
            price_per_session = @PricePerSession,
            currency = @Currency,
            requirements = @Requirements,
            equipment_needed = @EquipmentNeeded,
            meet_link = @MeetLink,
            updated_at = NOW()
        WHERE id = @GroupId
        RETURNING

    id,
    group_name,
    group_type,
    latitude,
    longitude,
    yoga_style,
    schedule,
    difficulty_level,
    description,
    max_participants,
    price_per_session,
    currency,
    requirements,
    equipment_needed,
    is_active,
    color,
    meet_link,
    created_at,
    updated_at;
;
    ";

                await using var conn = new NpgsqlConnection(_connectionString);
                await conn.OpenAsync();

                await using var cmd = new NpgsqlCommand(sql, conn);

                cmd.Parameters.AddWithValue("@GroupId", groupId);
                cmd.Parameters.AddWithValue("@GroupType", dto.groupType);
                cmd.Parameters.AddWithValue("@GroupName", dto.group_name);
                cmd.Parameters.Add(
                    "@Location",
                    NpgsqlDbType.Jsonb
                ).Value = JsonSerializer.Serialize(dto.location);
                cmd.Parameters.AddWithValue("@LocationAddress", (object?)dto.location_text ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Latitude", (object?)dto.latitude?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Longitude", (object?)dto.longitude ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Color", dto.color);
                cmd.Parameters.AddWithValue("@Schedule", dto.schedule);
                cmd.Parameters.AddWithValue("@IsActive", dto.is_active);
                cmd.Parameters.AddWithValue("@Description", (object?)dto.description ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@MaxParticipants", dto.max_participants);
                cmd.Parameters.AddWithValue("@YogaStyle", dto.yoga_style);
                cmd.Parameters.AddWithValue("@DifficultyLevel", dto.difficulty_level);
                cmd.Parameters.AddWithValue("@PricePerSession", dto.price_per_session);
                cmd.Parameters.AddWithValue("@Currency", dto.Currency ?? "INR");
                cmd.Parameters.AddWithValue("@Requirements",
                    dto.Requirements == null ? DBNull.Value : dto.Requirements.ToArray());
                cmd.Parameters.AddWithValue("@EquipmentNeeded",
                    dto.EquipmentNeeded == null ? DBNull.Value : dto.EquipmentNeeded.ToArray());
                cmd.Parameters.AddWithValue("@MeetLink", (object?)dto.meetLink ?? DBNull.Value);

                await using var reader = await cmd.ExecuteReaderAsync();

                if (!await reader.ReadAsync())
                    throw new Exception("Group not found");

                return new UpdateGroupResDto
                {
                    Id = reader.GetGuid(reader.GetOrdinal("id")),
                    GroupName = reader.GetString(reader.GetOrdinal("group_name")),
                    GroupType = reader.GetString(reader.GetOrdinal("group_type")),
                    Latitude = reader.IsDBNull(reader.GetOrdinal("latitude"))
                            ? null
                            : reader.GetDouble(reader.GetOrdinal("latitude")),
                    Longitude = reader.IsDBNull(reader.GetOrdinal("longitude"))
                            ? null
                            : reader.GetDouble(reader.GetOrdinal("longitude")),
                    YogaStyle = reader.GetString(reader.GetOrdinal("yoga_style")),
                    Schedule = reader.GetString(reader.GetOrdinal("schedule")),
                    DifficultyLevel = reader.GetString(reader.GetOrdinal("difficulty_level")),
                    Description = reader.GetString(reader.GetOrdinal("description")),
                    MaxParticipants = reader.GetInt32(reader.GetOrdinal("max_participants")),
                    PricePerSession = reader.GetDecimal(reader.GetOrdinal("price_per_session")),
                    Currency = reader.GetString(reader.GetOrdinal("currency")),
                    Requirements = reader.IsDBNull(reader.GetOrdinal("requirements")) ? null : reader.GetFieldValue<string[]>(reader.GetOrdinal("requirements")).ToList(),
                    EquipmentNeeded = reader.IsDBNull(reader.GetOrdinal("equipment_needed")) ? null : reader.GetFieldValue<string[]>(reader.GetOrdinal("equipment_needed")).ToList(),
                    IsActive = reader.GetBoolean(reader.GetOrdinal("is_active")),
                    Color = reader.GetString(reader.GetOrdinal("color")),
                    MeetLink = reader.IsDBNull(reader.GetOrdinal("meet_link"))
                            ? null
                            : reader.GetString(reader.GetOrdinal("meet_link")),
                    CreatedAt = reader.GetDateTime(reader.GetOrdinal("created_at"))
                };
            }

            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }
    }
}
