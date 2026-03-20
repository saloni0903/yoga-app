using System;

namespace yesmain.DTOs
{
    public class AttendanceCreateDto
    {
        public Guid GroupId { get; set; }
        public DateTime SessionDate { get; set; }
        public string AttendanceType { get; set; } = "present";
        public Guid? QrCodeId { get; set; }
        public string? Notes { get; set; }
        public string? InstructorNotes { get; set; }
        public int? Rating { get; set; }
        public string? Feedback { get; set; }
        public bool LocationVerified { get; set; }
        public string? GpsCoordinates { get; set; }
        public string? DeviceInfo { get; set; }
    }
}