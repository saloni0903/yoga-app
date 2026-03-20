using System;
using System.Text.Json;

namespace yesmain.Models
{

    public class GroupMemberResponseDto
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid GroupId { get; set; }
        public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
        public string Status { get; set; } 
        public string Role { get; set; } 
        public string PaymentStatus { get; set; } 
        public DateTime? LastPaymentDate { get; set; }
        public DateTime? NextPaymentDue { get; set; }
        public string? Notes { get; set; }
        public JsonDocument? EmergencyContactJson { get; set; }
        public string? MedicalNotes { get; set; }
        public int AttendanceCount { get; set; } 
        public DateTime? LastAttended { get; set; }

        // Computed property
        public int MembershipDurationDays
        {
            get
            {
                if (JoinedAt == default) return 0;
                return (int)Math.Ceiling((DateTime.UtcNow - JoinedAt).TotalDays);
            }
        }
    }
}
