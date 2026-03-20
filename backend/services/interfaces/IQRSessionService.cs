using yesmain.Models;

public interface ISessionQRService
{
    Task<SessionQrCode> GenerateAsync(GenerateQRRequest request);
    Task<SessionQrCode> ValidateAndUseAsync(string token, LocationDto? location);
    Task<List<SessionQrCode>> GetActiveForGroupAsync(Guid groupId, DateTime? sessionDate);
    Task DeactivateAsync(Guid id);
}
