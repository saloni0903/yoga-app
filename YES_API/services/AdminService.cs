using System.Security.Claims;

public class AdminService : IAdminService
{
    private readonly IAdminRepository _repo;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public AdminService(
        IAdminRepository repo,
        IHttpContextAccessor httpContextAccessor)
    {
        _repo = repo;
        _httpContextAccessor = httpContextAccessor;
    }

    private ClaimsPrincipal ValidateAdmin()
    {
        var principal = _httpContextAccessor.HttpContext?.User;

        if (principal == null || !principal.Identity!.IsAuthenticated)
        {
            throw new UnauthorizedAccessException("Unauthorized");
        }

        var role =
            principal.FindFirst(ClaimTypes.Role)?.Value ??
            principal.FindFirst("role")?.Value;

        if (role != "admin")
        {
            throw new UnauthorizedAccessException("Only admin is authorized");
        }

        return principal;
    }


    public async Task<IEnumerable<UserResponseDto>> GetAllInstructorsAsync(GetInstructorDto dto)
    {
        try
        {
            ValidateAdmin();
            return await _repo.GetAllInstructorsAsync(dto);
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<bool> UpdateInstructorStatusAsync(Guid id, string status)
    {
        try
        {
            ValidateAdmin();
            return await _repo.UpdateInstructorStatusAsync(id, status);
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<bool> DeleteInstructorAsync(Guid id)
    {
        try
        {
            ValidateAdmin();
            return await _repo.DeleteInstructorAsync(id);
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }


    public async Task<DashboardStatsDto> GetDashboardStatsAsync()
    {
        try
        {
            ValidateAdmin();
            return await _repo.GetDashboardStatsAsync();
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<IEnumerable<AttendanceOverTimeDto>> GetAttendanceOverTimeAsync(int period)
    {
        try
        {
            ValidateAdmin();
            return await _repo.GetAttendanceOverTimeAsync(period);
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<IEnumerable<ActivityFeedDto>> GetActivityFeedAsync(int limit)
    {
        try
        {
            ValidateAdmin();
            return await _repo.GetActivityFeedAsync(limit);
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<IEnumerable<TopGroupDto>> GetTopGroupsAsync(int limit)
    {
        try
        {
            ValidateAdmin();
            return await _repo.GetTopGroupsAsync(limit);
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }
}
