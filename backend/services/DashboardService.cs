using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using yesmain.DTOs;
using yesmain.Services.Interfaces;

[Authorize]
public class DashboardService : IDashboardService
{
    private readonly IDashboardRepository _repo;
    private readonly IHttpContextAccessor _httpContext;

    public DashboardService(
        IDashboardRepository repo,
        IHttpContextAccessor httpContext)
    {
        _repo = repo;
        _httpContext = httpContext;
    }

    public async Task<DashboardResponseDto?> GetDashboardAsync()
    {
        try
        {
            var user = _httpContext.HttpContext?.User;
            var userIdStr = user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? user.FindFirst("sub")?.Value;

           var userStats = await _repo.GetUserStatsAsync(Guid.Parse(userIdStr));
            if (userStats == null)
                return null;

            var recentAttendance = await _repo.GetRecentAttendanceAsync(Guid.Parse(userIdStr));

            return new DashboardResponseDto
            {
                Stats = userStats,
                RecentAttendance = recentAttendance
            };
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }
}
