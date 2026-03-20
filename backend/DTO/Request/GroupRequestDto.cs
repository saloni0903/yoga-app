
using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using System.Text.Json.Serialization;

public class GroupRequestDto
    {
        // Core
        [Required]
        [MaxLength(100)]
        [JsonPropertyName("group_name")]
        public string GroupName { get; set; } = string.Empty;

        [Required]
        [RegularExpression("^(online|offline)$")]
        [JsonPropertyName("groupType")]
        public string GroupType { get; set; } = "offline";

        // Offline only
        [JsonPropertyName("location_text")]
        public string? LocationText { get; set; }

        public double? Latitude { get; set; }
        public double? Longitude { get; set; }

        // UI
        [Required]
        public string Color { get; set; } = "#2E7D6E";

        [MaxLength(1000)]
        public string? Description { get; set; }

        // Session
        [Required]
        [JsonPropertyName("yoga_style")]
        public string YogaStyle { get; set; } = "hatha";

        [Required]
        [JsonPropertyName("difficulty_level")]
        public string DifficultyLevel { get; set; } = "all-level";

        [Range(0, 999999)]
        [JsonPropertyName("price_per_session")]
        public decimal PricePerSession { get; set; } = 0;

        [Range(1, 500)]
        [JsonPropertyName("max_participants")]
        public int MaxParticipants { get; set; } = 20;

        public string? Currency { get; set; } = "INR";

        // Online only
        public string? MeetLink { get; set; }

        // Flags
        [JsonPropertyName("isActive")]
        public bool IsActive { get; set; } = true;

        // Arrays
        public List<string> Requirements { get; set; } = new();
        public List<string> EquipmentNeeded { get; set; } = new();

        // ✅ FIXED: schedule is REQUIRED, NON-NULL, and NOT nullable items
        [Required]
        public GroupScheduleDto? Schedule { get; set; } = new();
}
public class GroupScheduleDto
{
    [JsonPropertyName("days")]
    public List<string> Days { get; set; } = new();

    [JsonPropertyName("startDate")]
    public DateTime StartDate { get; set; }

    [JsonPropertyName("endDate")]
    public DateTime EndDate { get; set; }

    [JsonPropertyName("startTime")]
    public string StartTime { get; set; } = string.Empty;

    [JsonPropertyName("endTime")]
    public string EndTime { get; set; } = string.Empty;
}

public class DeserializeProgram
{
    public static void Main()
    {
        string json = @"{
            ""days"": [""Thursday""],
            ""endDate"": ""2026-01-29T18:08:04.601"",
            ""endTime"": ""08:00"",
            ""startDate"": ""2026-01-29T18:08:04.601"",
            ""startTime"": ""07:00""
        }";

        // Deserialize single object
        GroupScheduleDto schedule = JsonSerializer.Deserialize<GroupScheduleDto>(json)!;

        Console.WriteLine($"Days: {string.Join(", ", schedule.Days)}");
        Console.WriteLine($"StartDate: {schedule.StartDate}");
        Console.WriteLine($"EndDate: {schedule.EndDate}");
        Console.WriteLine($"StartTime: {schedule.StartTime}");
        Console.WriteLine($"EndTime: {schedule.EndTime}");
    }
}
