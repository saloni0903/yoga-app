using yesmain.DTOs;

namespace yesmain.Services.Interfaces
{
    public interface IHealthServices
    {
        Task<Guid> RegisterHealth(HealthRequestDto dto);
        Task<List<HealthResponseDto>> GetHealthAsync();
    }
}