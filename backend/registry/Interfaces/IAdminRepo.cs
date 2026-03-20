using yesmain.DTOs;

public interface IAdminRepository
{
    Task<IEnumerable<UserResponseDto>> GetAllInstructorsAsync(GetInstructorDto dto);
    Task<bool> UpdateInstructorStatusAsync(Guid id, string status);
    Task<bool> DeleteInstructorAsync(Guid id);

    Task<DashboardStatsDto> GetDashboardStatsAsync();
    Task<IEnumerable<AttendanceOverTimeDto>> GetAttendanceOverTimeAsync(int period);
    Task<IEnumerable<ActivityFeedDto>> GetActivityFeedAsync(int limit);
    Task<IEnumerable<TopGroupDto>> GetTopGroupsAsync(int limit);
}
