namespace yesmain.DTOs;

public class DashboardResponseDto
{
    public UserStatsDto Stats { get; set; } = null!;
    public List<RecentAttendanceDto> RecentAttendance { get; set; } = new();
}
