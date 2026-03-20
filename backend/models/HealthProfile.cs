using System;
using System.Text.Json;

namespace yesmain.Models
{
    public class HealthProfile
    {
        public Guid Id { get; set; } = Guid.NewGuid();

        public Guid UserId { get; set; }

        public JsonDocument Responses { get; set; } = JsonDocument.Parse("{}");

        public int? TotalScore { get; set; }

        public DateTime Date { get; set; } = DateTime.UtcNow;

        public Guid _id => Id;
    }
}
