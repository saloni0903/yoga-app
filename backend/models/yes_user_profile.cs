using System.ComponentModel.DataAnnotations;
using System.Text.Json;

public class UserProfile
{
    [Key]
    public Guid Id { get; set; }   // FK → yes_users.id

    [Required]
    public string FirstName { get; set; } = null!;

    [Required]
    public string LastName { get; set; } = null!;

    [MinLength(10), MaxLength(10)]
    public string? Phone { get; set; }

    [MinLength(9), MaxLength(9)]
    public string? SamagraId { get; set; }

    public string? Location { get; set; }

    public bool IsActive { get; set; } = true;

    public string? ProfileImage { get; set; }

    public DateTime? DateOfBirth { get; set; }

    public JsonDocument? EmergencyContact { get; set; }

    public JsonDocument? MedicalInfo { get; set; }

    public string Status { get; set; } = "approved";

    public JsonDocument? Preferences { get; set; }

    public bool IsHealthProfileCompleted { get; set; } = false;

    public int CurrentStreak { get; set; } = 0;

    public int TotalMinutesPracticed { get; set; } = 0;

    public int TotalSessionsAttended { get; set; } = 0;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
