using yesmain.DTOs;

public interface IDashboardService
{
    Task<DashboardResponseDto?> GetDashboardAsync();
}
