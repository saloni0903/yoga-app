using System.Security.Claims;
using yesmain.Models;

public class AttendanceService : IAttendanceService
{
    private readonly IAttendanceRepository _repo;
    private readonly IHttpContextAccessor _httpContextAccessor;


    public AttendanceService(IAttendanceRepository repo, IHttpContextAccessor httpContextAccessor)
    {
        _repo = repo;
        _httpContextAccessor = httpContextAccessor;
    }

    public async Task<AttendanceResponseDTO> MarkAttendanceAsync(AttendanceDTO dto)
    {
        try
        {

        if (!await _repo.IsMemberAsync(dto.UserId, dto.GroupId))
            throw new Exception("User is not a member of this group");

        if (await _repo.ExistsAsync(dto.UserId, dto.GroupId, dto.SessionDate,dto.QrCodeId))
            throw new Exception("Attendance already marked");


        var attendance = await _repo.MarkAttendanceAsync(new Attendance
        {
            UserId = dto.UserId,
            GroupId = dto.GroupId,
            SessionDate = dto.SessionDate,
            QrCodeId = dto.QrCodeId,
            AttendanceType = dto.AttendanceType
        });

        //await _repo.UpdateUserStatsAsync(dto.UserId, dto.GroupId, dto.SessionDate);

        return new AttendanceResponseDTO
        {
            Id = attendance.Id,
            UserId = attendance.UserId,
            GroupId = attendance.GroupId,
            SessionDate = attendance.SessionDate,
            QrCodeId = attendance.QrCodeId,
            AttendanceType = attendance.AttendanceType
        };
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }


    public async Task<AttendanceResponseDTO> ScanQrCodeAsync(string token)
    {
        try
        {

        var user = _httpContextAccessor.HttpContext?.User;

        if (user == null || !user.Identity!.IsAuthenticated)
            throw new UnauthorizedAccessException("User not authenticated");

        var userIdClaim = user.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? user.FindFirst("sub")?.Value
                ?? throw new Exception("User ID not found"); 
        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
            throw new InvalidOperationException("Invalid user id");

        var qrCode = await _repo.GetQrCodeAsync(token);
        if (qrCode == null || qrCode.ExpiresAt == null || qrCode.ExpiresAt < DateTime.UtcNow)
            throw new InvalidOperationException("Invalid or expired QR code");

            // Optional: wrap both operations in a transaction
            var attendance = await _repo.MarkAttendanceAsync(new Attendance
            {
                UserId = userId,
                GroupId = qrCode.GroupId,
                SessionDate = qrCode.SessionDate,
                QrCodeId = Guid.Parse(token),
                CheckInTime = DateTime.UtcNow,
                MarkedAt = DateTime.UtcNow
            });

        if (attendance == null)
            throw new Exception("Failed to mark attendance");

        //await _repo.UpdateUserStatsAsync(userId, qrCode.GroupId, qrCode.SessionDate);

        return new AttendanceResponseDTO
        {
            Id = attendance.Id,
            UserId = attendance.UserId,
            GroupId = attendance.GroupId,
            SessionDate = attendance.SessionDate,
            QrCodeId = attendance.QrCodeId,
            AttendanceType = attendance.AttendanceType
        };
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<(IEnumerable<AttendanceResponseDTO> attendances, int total)>
        GetUserAttendanceAsync(UserAttendanceFilterDTO filter)
    {
        var httpContext = _httpContextAccessor.HttpContext;

        if (httpContext?.User?.Identity?.IsAuthenticated != true)
        {
            throw new UnauthorizedAccessException("User not authenticated");
        }

        var user = httpContext.User;

        var userIdClaim =
               user.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? user.FindFirst("sub")?.Value
            ?? user.FindFirst("userId")?.Value;

        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            throw new InvalidOperationException("Invalid user id");
        }

        // Defensive defaults
        filter.Page = filter.Page <= 0 ? 1 : filter.Page;
        filter.Limit = filter.Limit <= 0 ? 10 : filter.Limit;

        // Fetch data
        var attendanceEntities =
            await _repo.GetUserAttendanceAsync(userId, filter);

        // Map to response DTO
        var attendanceList = attendanceEntities.Select(a =>
            new AttendanceResponseDTO
            {
                Id = a.Id,
                UserId = a.UserId,
                GroupId = a.GroupId,
                SessionDate = a.SessionDate,
                QrCodeId = a.QrCodeId,
                AttendanceType = a.AttendanceType
            }).ToList();

        // Fetch total count
        var total =
            await _repo.GetUserAttendanceCountAsync(userId, filter);

        return (attendanceList, total);
    }

    public async Task DeleteAttendanceAsync(Guid id)
    {
        try
        {
            await _repo.DeleteAsync(id);
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<(List<AttendanceDto> Records, int Total)> GetAttendancesAsync(AttendanceFilterDto filter)
    {
        try
        {

        return await _repo.GetAttendancesAsync(filter);
        }

        catch(Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

}
