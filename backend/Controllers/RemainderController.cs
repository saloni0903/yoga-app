using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/reminder-log")]
public class ReminderLogController : ControllerBase
{
    private readonly ReminderLogService _service;

    public ReminderLogController(ReminderLogService service)
    {
        _service = service;
    }

    [HttpPost]
    public IActionResult AddReminder([FromBody] ReminderLogDto log)
    {
        try
        {

        var inserted = _service.AddReminder(log);
        if (!inserted)
            return Conflict(new { success = false, message = "Reminder already exists." });

        return Ok(new { success = true, data = log });
        }

        catch(Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpGet("{groupId}/{reminderType}")]
    public IActionResult GetReminders(Guid groupId, string reminderType)
    {
        try
        {

        var reminders = _service.GetReminders(groupId, reminderType);
        return Ok(new { success = true, data = reminders });
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }
}
