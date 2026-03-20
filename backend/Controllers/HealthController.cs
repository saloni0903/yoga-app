using Microsoft.AspNetCore.Mvc;
using yesmain.DTOs;
using yesmain.Services.Interfaces;

namespace yesmain.Controllers
{
    [ApiController]
    [Route("api/health")]
    public class HealthController : ControllerBase
    {
        private readonly IHealthServices _services;
        public HealthController(IHealthServices services)
        {
            _services = services;
        }
        [HttpPost("register")]
        public async Task<IActionResult> Create([FromBody] HealthRequestDto dto)
        {
            try
            {
                var user = await _services.RegisterHealth(dto);
                return Ok(new {success = true, message = "Health profile saved"});

            }

            catch (Exception ex)
            {
                return BadRequest(ex.Message);   
            }
        }
        [HttpGet]
        public async Task<IActionResult> GetHealth()
        {
            try
            {
                var profiles = await _services.GetHealthAsync();
                return Ok(new
                {
                    success = true,
                    message = "Health profiles fetched successfully",
                    data = profiles
                });

            }

            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }
    }
}