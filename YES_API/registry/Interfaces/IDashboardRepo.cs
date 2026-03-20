using yesmain.DTOs;

public interface IDashboardRepository
{
    Task<UserStatsDto?> GetUserStatsAsync(Guid userId);
    Task<List<RecentAttendanceDto>> GetRecentAttendanceAsync(Guid userId);
}
