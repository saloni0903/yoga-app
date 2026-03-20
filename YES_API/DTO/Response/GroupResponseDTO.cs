public class GroupResponseDto
{
    public Guid Id { get; set; }
    public Guid InstructorId { get; set; }

    public string GroupType { get; set; } = string.Empty;
    public string group_name { get; set; } = string.Empty;

    public string? LocationAddress { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    public string? MeetLink { get; set; }

    public GroupScheduleDto Schedule { get; set; } = new();

    public string Color { get; set; } = "#4caf50";
    public string YogaStyle { get; set; } = "hatha";
    public string DifficultyLevel { get; set; } = "all-levels";

    public int MaxParticipants { get; set; }
    public decimal PricePerSession { get; set; }
    public string Currency { get; set; } = "INR";

    public string? Description { get; set; }

    public List<string> Requirements { get; set; } = new();
    public List<string> EquipmentNeeded { get; set; } = new();

    public bool IsActive { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
