using System;

namespace yesmain.Models
{

    public class GroupMember
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid UserId { get; set; }
        public Guid GroupId { get; set; }
        public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
        public string Status { get; set; } = "Active";
        public string Role { get; set; } = "Member";
        public string PaymentStatus { get; set; } = "Pending";
        public DateTime? LastPaymentDate { get; set; }
        public DateTime? NextPaymentDue { get; set; }
        public string? Notes { get; set; }
        public string? EmergencyContactJson { get; set; }
        public string? MedicalNotes { get; set; }
        public int AttendanceCount { get; set; } = 0;
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
