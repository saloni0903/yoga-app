using System.Text.Json;

namespace yesmain.DTOs
{
    public class HealthResponseDto
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }

        public JsonDocument Responses { get; set; } = JsonDocument.Parse("{}");

        public int? TotalScore { get; set; }

        public DateTime Date { get; set; }

        public UserHealthDto User { get; set; } = null!;

    }
}

public class UserHealthDto
{
    public Guid Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
}
