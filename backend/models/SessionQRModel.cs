using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json;

namespace yesmain.Models
{
    public class SessionQrCode
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Guid GroupId { get; set; }

        [Required]
        public string Token { get; set; } = null!;

        [Required]
        public DateTime SessionDate { get; set; }

        [Required]
        public DateTime ExpiresAt { get; set; }

        [Required]
        public Guid CreatedBy { get; set; }

        public bool IsActive { get; set; } = true;

        public int UsageCount { get; set; } = 0;

        public int MaxUsage { get; set; } = 100;

        public DateTime? SessionStartTime { get; set; }

        public DateTime? SessionEndTime { get; set; }

        [Column(TypeName = "jsonb")]
        public JsonDocument LocationRestriction { get; set; }
            = JsonDocument.Parse("{\"enabled\": false}");

        public string? QrData { get; set; }

        [Column(TypeName = "jsonb")]
        public JsonDocument Metadata { get; set; }
            = JsonDocument.Parse("{}");

        public DateTime CreatedAt { get; set; }

        public DateTime UpdatedAt { get; set; }


        [NotMapped]
        public bool IsValid =>
            IsActive &&
            ExpiresAt > DateTime.UtcNow &&
            UsageCount < MaxUsage;

        [NotMapped]
        public long TimeUntilExpiry =>
            Math.Max(0, (long)(ExpiresAt - DateTime.UtcNow).TotalMilliseconds);
    }
}
