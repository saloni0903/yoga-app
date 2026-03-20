using yesmain.Models;

public interface IAttendanceService
{
    Task<AttendanceResponseDTO> MarkAttendanceAsync(AttendanceDTO dto);
    Task<AttendanceResponseDTO> ScanQrCodeAsync(string token);
    Task DeleteAttendanceAsync(Guid attendanceId);

    Task<(List<AttendanceDto> Records, int Total)> GetAttendancesAsync(AttendanceFilterDto filter);

    Task<(IEnumerable<AttendanceResponseDTO> attendances, int total)> GetUserAttendanceAsync(UserAttendanceFilterDTO filter);
}
