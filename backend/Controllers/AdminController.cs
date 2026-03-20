using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/admin")]
[Authorize]
public class AdminController : ControllerBase
{
    private readonly IAdminService _service;

    public AdminController(IAdminService service)
    {
        _service = service;
    }

    [HttpGet("instructors")]
    public async Task<IActionResult> GetInstructors([FromQuery] GetInstructorDto dto)
    {
        try
        {

         return Ok(new { success = true, data = await _service.GetAllInstructorsAsync(dto) });
        }

        catch(Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPut("instructors/{id}/status")]
    public async Task<IActionResult> UpdateStatus(
        Guid id,
        [FromBody] InstructorStatusUpdateDto dto)
    {
        try
        {
            var valid = new[] { "approved", "rejected", "suspended", "pending" };
            if (!valid.Contains(dto.Status))
                return BadRequest(new { success = false, message = "Invalid status" });

            var result = await _service.UpdateInstructorStatusAsync(id, dto.Status);
            return Ok(new { success = result, message = $"Instructor status updated to {dto.Status}" });
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }


    }

    [HttpDelete("instructors/{id}")]
    public async Task<IActionResult> DeleteInstructor(Guid id)
    {
        try
        {

            var result = await _service.DeleteInstructorAsync(id);
            if (!result)
                return NotFound(new { success = false, message = "Instructor not found" });

            return Ok(new { success = true, message = "Instructor removed" });
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpGet("stats")]
    public async Task<IActionResult> Stats()
    {
        try
        {
            return Ok(new { success = true, data = await _service.GetDashboardStatsAsync() });
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpGet("stats/attendance-over-time")]
    public async Task<IActionResult> AttendanceOverTime([FromQuery] int period = 30)
    {
        try
        {

            var data = await _service.GetAttendanceOverTimeAsync(period);
            return Ok(new
            {
                success = true,
                data = data.Select(d => new
                {
                    date = d.Date.ToString("MMM dd"),
                    attendance = d.Attendance
                })
            });
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpGet("activity-feed")]
    public async Task<IActionResult> ActivityFeed([FromQuery] int limit = 7)
    {
        try
        {
            return Ok(new { success = true, data = await _service.GetActivityFeedAsync(limit) });
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpGet("stats/top-groups")]
    public async Task<IActionResult> TopGroups([FromQuery] int limit = 5)
    {
        try
        {
            return Ok(new { success = true, data = await _service.GetTopGroupsAsync(limit) });
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }

    }
}
