using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace yesmain.Models
{
    public class Group
    {
        [Key]
        [Column("id")]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        [Column("instructor_id")]
        public Guid InstructorId { get; set; }

        [Required]
        [Column("groupType")]
        public string GroupType { get; set; } = "offline"; // online | offline

        [Required]
        [MaxLength(100)]
        [Column("group_name")]
        public string GroupName { get; set; } = null!;

        // JSONB location object
        [Column("location", TypeName = "jsonb")]
        public object? Location { get; set; }

        [Column("location_address")]
        public string? LocationAddress { get; set; }

        [Column("latitude")]
        public double? Latitude { get; set; }

        [Column("longitude")]
        public double? Longitude { get; set; }

        [Required]
        [Column("color")]
        public string Color { get; set; } = "#2E7D6E";

        [Required]
        [Column("is_active")]
        public bool IsActive { get; set; }

        [MaxLength(1000)]
        [Column("description")]
        public string? Description { get; set; }

        [Required]
        [Column("max_participants")]
        public int MaxParticipants { get; set; } = 20;

        [Required]
        [Column("yoga_style")]
        public string YogaStyle { get; set; } = "hatha";

        [Required]
        [Column("difficulty_level")]
        public string DifficultyLevel { get; set; } = "all-levels";

        [Required]
        [Column("price_per_session", TypeName = "decimal(10,2)")]
        public decimal PricePerSession { get; set; } = 0;

        [Required]
        [MaxLength(3)]
        [Column("currency")]
        public string Currency { get; set; } = "INR";

        [Column("requirements", TypeName = "text[]")]
        public List<string> Requirements { get; set; } = new();

        [Column("equipment_needed", TypeName = "text[]")]
        public List<string> EquipmentNeeded { get; set; } = new();

        [Column("meetLink")]
        public string? MeetLink { get; set; }

        [Required]
        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Required]
        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [NotMapped]
        public object? Coordinates =>
            Latitude.HasValue && Longitude.HasValue
                ? new { latitude = Latitude, longitude = Longitude }
                : null;

        [NotMapped]
        public string? LocationText =>
            GroupType == "offline"
                ? LocationAddress
                : null;

        // Sequelize-style `_id`
        [NotMapped]
        public Guid _id => Id;

        public GroupScheduleDto Schedule { get; set; } = new();

    }
}
