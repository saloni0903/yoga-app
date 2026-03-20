using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json;

namespace yesmain.DTOs
{
    public class UpdateGroupReqDto
    {

        public string groupType { get; set; } = "offline"; // online | offline

        public string group_name { get; set; } = string.Empty;

        // JSONB location object
        public JsonDocument? location { get; set; } = null!;

        public string? location_text { get; set; }

        public double? latitude { get; set; }

        public double? longitude { get; set; }


        public string color { get; set; } = "#2E7D6E";

        public JsonDocument schedule { get; set; } = null!;

        public bool is_active { get; set; }


        public string? description { get; set; }

        public int max_participants { get; set; } = 20;


        public string yoga_style { get; set; } = "hatha";


        public string difficulty_level { get; set; } = "all-levels";

        public decimal price_per_session { get; set; } = 0;


        public string? Currency { get; set; } = "INR";

        [Column("requirements", TypeName = "text[]")]
        public List<string>? Requirements { get; set; } 

        [Column("equipment_needed", TypeName = "text[]")]
        public List<string>? EquipmentNeeded { get; set; }

        public string? meetLink { get; set; }
     
    }
}
