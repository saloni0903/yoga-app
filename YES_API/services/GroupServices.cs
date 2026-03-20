using yesmain.Models;
using yesmain.registry;
using Npgsql;
using NpgsqlTypes;
using System.Security.Claims;
using yesmain.DTOs;


public class GroupServices : IGroupServices
{
    private readonly IGroupRepo _groupRepository;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly string _connectionString;


    public GroupServices(IGroupRepo groupRepository, IHttpContextAccessor httpContextAccessor, IConfiguration config)
    {
        _groupRepository = groupRepository;
        _httpContextAccessor = httpContextAccessor;
        _connectionString = config.GetConnectionString("DefaultConnection");
    }

    public async Task<GroupResponseDto> CreateGroupAsync(GroupRequestDto dto)
    {
        var user = _httpContextAccessor.HttpContext?.User
            ?? throw new UnauthorizedAccessException("Unauthorized");

        if (!user.Identity!.IsAuthenticated)
            throw new UnauthorizedAccessException("Unauthorized");

        var role = user.FindFirst(ClaimTypes.Role)?.Value
            ?? user.FindFirst("role")?.Value;

        if (role != "instructor")
            throw new UnauthorizedAccessException("Only instructors can create groups");

        var userIdStr = user.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? user.FindFirst("sub")?.Value
            ?? throw new Exception("User ID not found");

        if (!Guid.TryParse(userIdStr, out var instructorId))
            throw new Exception("Invalid user id");

        var group = new Group
        {
            GroupName = dto.GroupName,
            InstructorId = instructorId,
            GroupType = dto.GroupType,

            LocationAddress = dto.LocationText,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,

            Schedule = dto.Schedule,

            Color = dto.Color,
            Description = dto.Description,

            YogaStyle = dto.YogaStyle,
            DifficultyLevel = dto.DifficultyLevel,
            PricePerSession = dto.PricePerSession,
            MaxParticipants = dto.MaxParticipants,

            MeetLink = dto.MeetLink,

            Requirements = dto.Requirements ?? new List<string>(),
            EquipmentNeeded = dto.EquipmentNeeded ?? new List<string>(),

            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        await _groupRepository.CreateGroupAsync(group);

        return new GroupResponseDto
        {
            Id = group.Id,
            InstructorId = group.InstructorId,

            GroupType = group.GroupType,
            group_name = group.GroupName,

            LocationAddress = group.LocationAddress,
            Latitude = group.Latitude,
            Longitude = group.Longitude,

            MeetLink = group.MeetLink,

            // ✅ List, not single object
            Schedule = group.Schedule,

            Color = group.Color,

            YogaStyle = group.YogaStyle,
            DifficultyLevel = group.DifficultyLevel,
            MaxParticipants = group.MaxParticipants,
            PricePerSession = group.PricePerSession,
            Currency = group.Currency,

            Description = group.Description,

            Requirements = group.Requirements,
            EquipmentNeeded = group.EquipmentNeeded,

            IsActive = group.IsActive,
            CreatedAt = group.CreatedAt,
            UpdatedAt = group.UpdatedAt
        };
    }

    public async Task<JoinGroupResponseDto> JoinGroupAsync(Guid id)
    {
        try
        {

            var user = _httpContextAccessor.HttpContext?.User;

            if (user == null || !user.Identity!.IsAuthenticated)
            {
                throw new Exception("Unauthorized");
            }
            var userId = Guid.Parse(user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? user.FindFirst("sub")?.Value);

            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            Guid? instructorId = null;
            string groupName;

            await using (var cmd = new NpgsqlCommand(
                "SELECT instructor_id,group_name From yesgroups where id = @id", conn))
            {
                cmd.Parameters.AddWithValue("@id", id);

                await using var reader = await cmd.ExecuteReaderAsync();

                if (!await reader.ReadAsync())
                {
                    throw new Exception("Group not found");
                }

                instructorId = reader.IsDBNull(0) ? null : reader.GetGuid(0);
                groupName = reader.GetString(1);
            }

            await using (var checkCmd = new NpgsqlCommand(
                    @"SELECT 1 FROM yesgroupmembers 
                  WHERE user_id = @userId AND group_id = @groupId", conn))
            {
                checkCmd.Parameters.AddWithValue("@userId", userId);
                checkCmd.Parameters.AddWithValue("@groupId", id);

                var exists = await checkCmd.ExecuteScalarAsync();
                if (exists != null)
                    throw new Exception("User is already a member of this group");
            }

            var joinedAt = DateTime.UtcNow;

            await using (var insertCmd = new NpgsqlCommand(
                @"INSERT INTO yesgroupmembers
                  (id, user_id, group_id, joined_at, status, role, payment_status)
                  VALUES
                  (gen_random_uuid(), @userId, @groupId, @joinedAt, 'Active', 'Member', 'Pending')",
                conn))
            {
                insertCmd.Parameters.AddWithValue("@userId", userId);
                insertCmd.Parameters.AddWithValue("@groupId", id);
                insertCmd.Parameters.AddWithValue("@joinedAt", joinedAt);

                await insertCmd.ExecuteNonQueryAsync();
            }

            return new JoinGroupResponseDto
            {
                GroupId = id,
                UserId = userId,
                JoinedAt = joinedAt,
                Status = "Active"
            };

        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }

    }

    public async Task<bool> DeleteAsync(Guid groupId)
    {
        try
        {
            var user = _httpContextAccessor.HttpContext?.User;

            if (user == null || !user.Identity!.IsAuthenticated)
            {
                throw new Exception("Unauthorized");
            }

            var role = user?.FindFirst(ClaimTypes.Role)?.Value;

            if (role != "instructor")
            {
                throw new Exception("Only instructors can delete the groups");
            }

            var result = _groupRepository.DeleteGroupAsync(groupId);

            if (result == null)
            {
                throw new Exception("The group does not exists");
            }

            return true;
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }
    public async Task<GroupResponseDto> GetByIdAsync(Guid groupId)
    {
        try
        {
            var result = await _groupRepository.GetByIdGroupAsync(groupId);
            return result;
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }

    }
    public async Task<List<GroupDto>> GetGroupsAsync(GroupFilterDto dto)
    {

        try
        {
            var offline = await _groupRepository.GetOfflineGroupsAsync(dto);

            var online = await _groupRepository.GetOnlineGroupsAsync(dto);

            var all = offline.Concat(online).ToList();
            return all;
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }

    }
    public async Task<List<GroupResponseDto>> GetMyGroupsAsync()
    {
        var user = _httpContextAccessor.HttpContext?.User
            ?? throw new UnauthorizedAccessException("Unauthorized");

        if (!user.Identity!.IsAuthenticated)
            throw new UnauthorizedAccessException("Unauthorized");

        var userIdStr =
            user.FindFirst(ClaimTypes.NameIdentifier)?.Value ??
            user.FindFirst("sub")?.Value;

        if (!Guid.TryParse(userIdStr, out var userId))
            throw new UnauthorizedAccessException("Invalid user id in token");

        return await _groupRepository.GetMyGroupListAsync(userId);
    }


    public async Task<List<GroupMemberResponseDto>> GetGroupMemberAsync(Guid GroupId)
    {

        try
        {
            var user = _httpContextAccessor.HttpContext?.User;

            if (user == null || !user.Identity!.IsAuthenticated)
            {
                throw new Exception("Unauthorized");
            }
            var userId = Guid.Parse(user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? user.FindFirst("sub")?.Value);

            return await _groupRepository.GetGroupMemberListAsync(GroupId);

        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }

    }
    public async Task<bool> LeaveAsync(Guid groupId)
    {

        try
        {
            var user = _httpContextAccessor.HttpContext?.User;

            if (user == null || !user.Identity!.IsAuthenticated)
            {
                throw new Exception("Unauthorized");
            }
            var userId = Guid.Parse(user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? user.FindFirst("sub")?.Value);

            var results = _groupRepository.LeaveGroupAsync(userId, groupId);

            if (results == null)
            {
                throw new Exception("You are not part of this group");
            }

            return true;
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }


    }
    public async Task<UpdateGroupResDto> UpdateAsync(Guid groupId, UpdateGroupReqDto dto)
    {

        try
        {
            var user = _httpContextAccessor.HttpContext?.User;

            if (user == null || !user.Identity!.IsAuthenticated)
            {
                throw new Exception("Unauthorized");
            }

            var role = user.FindFirst(ClaimTypes.Role)?.Value ?? user.FindFirst("role")?.Value;

            if (role != "instructor")
            {
                throw new Exception("only instructor can update groups");
            }

            var result = await _groupRepository.UpdateGroupAsync(groupId, dto);

            return result;

        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

}