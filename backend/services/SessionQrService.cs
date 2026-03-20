using System.Security.Claims;
using System.Security.Cryptography;
using System.Text.Json;
using yesmain.Models;

public class SessionQRService : ISessionQRService
{
    private readonly IQrSessionRepo _repo;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public SessionQRService(IQrSessionRepo repo, IHttpContextAccessor httpContextAccessor)
    {
        _repo = repo;
        _httpContextAccessor = httpContextAccessor;
    }

    private static string GenerateToken()
    {
        try
        {

        var bytes = RandomNumberGenerator.GetBytes(32);
        return Convert.ToHexString(bytes).ToLower();
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<SessionQrCode> GenerateAsync(GenerateQRRequest req)
    {
        try
        {

        var user = _httpContextAccessor.HttpContext?.User;

        if (user == null || !user.Identity!.IsAuthenticated)
        {
            throw new Exception("Unauthorized");
        }

        var role = user.FindFirst(ClaimTypes.Role)?.Value ?? user.FindFirst("role")?.Value;

        var userIdStr = user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? user.FindFirst("sub")?.Value;

        if(role != "instructor")
        {
            throw new Exception("Only Instructors can generate the QR code");
        }

            // Ensure req.SessionDate is valid
            var sessionDate = req.SessionDate != default ? req.SessionDate : DateTime.UtcNow.Date;

            // Ensure options is not null
            var options = req.Options ?? new SessionQROptions();

            // Set start, end, and expires safely
            var start = options.SessionStartTime.HasValue
                ? options.SessionStartTime.Value
                : sessionDate.AddHours(9); // default 9 AM if not provided

            var end = options.SessionEndTime.HasValue
                ? options.SessionEndTime.Value
                : start.AddHours(1); // default 1-hour session

            var expires = options.ExpiresAt.HasValue
                ? options.ExpiresAt.Value
                : end.AddMinutes(30); // default expires 30 mins after end

            // Validate that end is after start
            if (end <= start)
                throw new ArgumentException("SessionEndTime must be after SessionStartTime");

            // Validate that expires is after end
            if (expires <= end)
                throw new ArgumentException("ExpiresAt must be after SessionEndTime");

            // Create the QR object
            var qr = new SessionQrCode
            {
                Id = Guid.NewGuid(),
                GroupId = req.group_id,
                Token = GenerateToken(),

                SessionDate = sessionDate,
                SessionStartTime = start,
                SessionEndTime = end,
                ExpiresAt = expires,
                CreatedBy = Guid.Parse(userIdStr),
                MaxUsage = options.MaxUsage ?? 100,

                LocationRestriction = JsonSerializer.SerializeToDocument(
                    options.LocationRestriction ?? new { enabled = false }),
                Metadata = JsonSerializer.SerializeToDocument(
                    options.Metadata ?? new { })
            };


            await _repo.InsertAsync(qr);
            return qr;
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<SessionQrCode> ValidateAndUseAsync(
        string token, LocationDto? location)
    {
        try
        {

        var qr = await _repo.GetByTokenAsync(token)
            ?? throw new Exception("Invalid QR code");

        if (!qr.IsValid)
            throw new Exception("QR code expired or usage exceeded");

        // Location validation hook (future)
        await _repo.IncrementUsageAsync(qr.Id);
        qr.UsageCount++;

        return qr;
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<List<SessionQrCode>> GetActiveForGroupAsync(
        Guid groupId, DateTime? sessionDate)
    {
        try
        {

            return await _repo.GetActiveForGroupAsync(groupId, sessionDate);
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task DeactivateAsync(Guid id)
    {
        try
        {
             await _repo.DeactivateAsync(id);
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }
}
