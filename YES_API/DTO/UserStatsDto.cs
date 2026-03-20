namespace yesmain.DTOs;

public class UserStatsDto
{
    public Guid Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public int CurrentStreak { get; set; }
    public int TotalMinutesPracticed { get; set; }
    public int TotalSessionsAttended { get; set; }
}
