using System;

namespace yesmain.Models
{
    public class Attendance
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid GroupId { get; set; }
        public DateTime SessionDate { get; set; }
        public DateTime MarkedAt { get; set; } 
        public Guid QrCodeId { get; set; }
        public string AttendanceType { get; set; } = "present";
        public DateTime CheckInTime { get; set; }
        public DateTime? CheckOutTime { get; set; }
        public int SessionDuration { get; set; }
        public string? Notes { get; set; }
        public string? InstructorNotes { get; set; }
        public int? Rating { get; set; }
        public string? Feedback { get; set; }
        public bool LocationVerified { get; set; }
        public string? GpsCoordinates { get; set; }
        public string? DeviceInfo { get; set; }


        public int ActualDuration =>
            CheckOutTime.HasValue
                ? (int)Math.Round((CheckOutTime.Value - CheckInTime).TotalMinutes)
                : SessionDuration;

        public bool IsPresent =>
            AttendanceType == "present" || AttendanceType == "late";
    }
}
