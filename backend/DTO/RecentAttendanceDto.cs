namespace yesmain.DTOs;

public class RecentAttendanceDto
{
    public Guid Id { get; set; }
    public DateTime SessionDate { get; set; }
    public string AttendanceType { get; set; } = string.Empty;
    public int SessionDuration { get; set; }
}
