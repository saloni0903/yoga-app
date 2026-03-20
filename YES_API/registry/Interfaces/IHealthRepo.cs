using yesmain.DTOs;
using yesmain.Models;

namespace yesmain.Registry.Interfaces
{
    public interface IHealthRepo
    {
        Task<Guid> CreateHealthReport(HealthProfile health);
        Task<List<HealthResponseDto>> GetHealthReport();
    }
}