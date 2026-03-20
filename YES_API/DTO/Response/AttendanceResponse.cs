using System;

namespace yesmain.DTOs
{
    public class AttendanceResponseDto
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid GroupId { get; set; }
        public DateTime SessionDate { get; set; }
        public string? AttendanceType { get; set; } = "present";
        public DateTime CheckInTime { get; set; }
        public DateTime? CheckOutTime { get; set; }
        public bool IsPresent { get; set; }
        public int ActualDuration { get; set; }
    }
}
