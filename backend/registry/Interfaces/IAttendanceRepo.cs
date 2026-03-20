using yesmain.Models;

public interface IAttendanceRepository
{
    Task<bool> IsMemberAsync(Guid userId, Guid groupId);
    Task<bool> ExistsAsync(Guid userId, Guid groupId, DateTime sessionDate, Guid qrcodeId);
    Task<Attendance> MarkAttendanceAsync(Attendance attendance);
    Task<SessionQrCode> GetQrCodeAsync(string token);
    Task UpdateUserStatsAsync(Guid userId, Guid groupId, DateTime sessionDate);
    Task DeleteAsync(Guid id);
    Task<IEnumerable<Attendance>> GetUserAttendanceAsync(Guid userId, UserAttendanceFilterDTO dto);
    Task<int> GetUserAttendanceCountAsync(Guid userId ,UserAttendanceFilterDTO dto);
    Task<Attendance> GetByIdAsync(Guid id);

    Task<(List<AttendanceDto> Records, int Total)> GetAttendancesAsync(AttendanceFilterDto filter);

}
