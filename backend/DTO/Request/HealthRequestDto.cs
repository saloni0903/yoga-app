using System.Text.Json;

namespace yesmain.DTOs
{
    public class HealthRequestDto
    {
        public JsonDocument responses { get; set; } = JsonDocument.Parse("{}");
        public int score { get; set; }
    }
}