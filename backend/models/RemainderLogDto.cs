using System;
using System.Text.Json.Serialization;

public class ReminderLogDto
{
    public Guid Id { get; set; } = Guid.NewGuid();  // default UUID

    public Guid GroupId { get; set; }

    public string SessionDateISO { get; set; } = null!;

    public string ReminderType { get; set; } = null!; // "1hr" or "24hr"

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    [JsonPropertyName("_id")]
    public Guid _id => Id;
}
