using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace yesmain.Controllers;

[ApiController]
[Route("api/dashboard")]
[Authorize]
public class DashboardController : ControllerBase
{
    private readonly IDashboardService _dashboardService;

    public DashboardController(IDashboardService dashboardService)
    {
        _dashboardService = dashboardService;
    }

    [HttpGet]
    public async Task<IActionResult> GetDashboard()
    {
        try
        {

            var result = await _dashboardService.GetDashboardAsync();

            if (result is null)
                return NotFound(new { success = false, message = "User not found" });

            return Ok(new
            {
                success = true,
                data = result
            });
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }
}
    