using System.Security.Claims;
using System.Security.Principal;
using yesmain.DTOs;
using yesmain.Models;
using yesmain.Registry.Interfaces;
using yesmain.Services.Interfaces;

namespace yesmain.Services
{
    public class HealthServices : IHealthServices
    {
        private readonly IHealthRepo _repo;
        private readonly IHttpContextAccessor _context;
        public HealthServices(IHealthRepo repo, IHttpContextAccessor context)
        {
            _repo = repo;
            _context = context;
        }

        public async Task<Guid> RegisterHealth(HealthRequestDto dto)
        {
            try
            {

                var user = _context.HttpContext?.User;

                if (user == null || !user.Identity!.IsAuthenticated)
                {
                    throw new Exception("Unauthorized");
                }


                var userIdStr = user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? user.FindFirst("sub")?.Value;

                var health = new HealthProfile
                {
                    UserId = Guid.Parse(userIdStr),
                    TotalScore = dto.score,
                    Responses = dto.responses,
                    Date = DateTime.UtcNow
                };

                return await _repo.CreateHealthReport(health);
            }

            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        public async Task<List<HealthResponseDto>> GetHealthAsync()
        {
            try
            {

                var user = _context.HttpContext?.User;

                if (user == null || !user.Identity!.IsAuthenticated)
                {
                    throw new Exception("Unauthorized");
                }

                var userIdStr = user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? user.FindFirst("sub")?.Value;

                var role =
                    user.FindFirst(ClaimTypes.Role)?.Value ??
                    user.FindFirst("role")?.Value;

                if(role != "admin")
                {
                    throw new Exception("Only admin can view the health data");
                }

                 return await _repo.GetHealthReport();

            }

            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }

        }


    }
}