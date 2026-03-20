using System.ComponentModel.DataAnnotations;
using System.Text.Json;

public class UserRequestDto
{
    public Guid Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    [Required]
    public string Email{ get; set; } = string.Empty;
    [Required]
    [MinLength(8)]
    public string Password{ get; set; } = string.Empty;

    public string Phone { get; set; } = string.Empty;
    public string Role { get; set; } = "participant";
    public string SamagraId { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public string Status { get; set; } = "approved";
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public JsonDocument EmergencyContact { get; set; } = JsonDocument.Parse("{}");
    public JsonDocument Preferences { get; set; } = JsonDocument.Parse("{}");
    public JsonDocument MediacalInfo { get; set; } = JsonDocument.Parse("{}");
    public string[]? FcmTokens { get; set; }
}