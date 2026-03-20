using yesmain.Models;

public interface IQrSessionRepo
{
    Task<SessionQrCode?> GetByTokenAsync(string token);
    Task InsertAsync(SessionQrCode qr);
    Task IncrementUsageAsync(Guid qrId);
    Task<List<SessionQrCode>> GetActiveForGroupAsync(Guid groupId, DateTime? sessionDate);
    Task DeactivateAsync(Guid id);
}
