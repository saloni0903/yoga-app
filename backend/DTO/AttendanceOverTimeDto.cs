public class AttendanceOverTimeDto
{
    public DateTime Date { get; set; }
    public int Attendance { get; set; }
}

public class AttendaceOverTimeRequestDto
{
    public int period { get; set; } = 30;
}