using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

[ApiController]
[Route("api/attendance")]
public class AttendanceController : ControllerBase
{
    private readonly IAttendanceService _attendanceService;

    public AttendanceController(IAttendanceService attendanceService)
    {
        _attendanceService = attendanceService;
    }

    [HttpPost("mark")]
    public async Task<IActionResult> MarkAttendance([FromBody] AttendanceDTO dto)
    {
        try
        {
            var result = await _attendanceService.MarkAttendanceAsync(dto);
            return Ok(result);
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost("scan")]
    public async Task<IActionResult> ScanQRCode([FromBody] ScanQRCodeDTO dto)
    {
        try
        {

            var result = await _attendanceService.ScanQrCodeAsync(dto.Token.ToString());
            return Ok(result);
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [Authorize]
    [HttpGet("user")]
    public async Task<IActionResult> GetUserAttendance([FromQuery] UserAttendanceFilterDTO filter)
    {
        try
        {
            var (attendance, total) = await _attendanceService.GetUserAttendanceAsync(filter);

            var page = filter.Page <= 0 ? 1 : filter.Page;
            var limit = filter.Limit <= 0 ? 10 : filter.Limit;

            return Ok(new
            {
                success = true,
                data = new
                {
                    attendance = attendance,
                    pagination = new
                    {
                        current = page,
                        pages = (int)Math.Ceiling((double)total / limit),
                        total = total
                    }
                }
            });

        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }


    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteAttendance(Guid id)
    {
        try
        {
            await _attendanceService.DeleteAttendanceAsync(id);
            return NoContent();
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpGet]
    public async Task<IActionResult> GetAttendances([FromQuery] AttendanceFilterDto filter)
    {
        try
        {
            var (records, total) = await _attendanceService.GetAttendancesAsync(filter);
            int pages = (int)Math.Ceiling(total / (double)filter.Limit);

            return Ok(new
            {
                success = true,
                data = records,
                pagination = new
                {
                    current = filter.Page,
                    limit = filter.Limit,
                    pages,
                    total
                }
            });
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine(ex);
            return StatusCode(500, new
            {
                success = false,
                message = "Failed to fetch attendance records",
                error = ex.Message
            });
        }
    }


}
