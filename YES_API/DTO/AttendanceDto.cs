// AttendanceDTO.cs
public class AttendanceDTO
{
    public Guid UserId { get; set; }
    public Guid GroupId { get; set; }
    public DateTime SessionDate { get; set; }
    public Guid QrCodeId { get; set; }
    public string AttendanceType { get; set; } = "present";
}

// AttendanceResponseDTO.cs
public class AttendanceResponseDTO
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid GroupId { get; set; }
    public DateTime SessionDate { get; set; }
    public Guid? QrCodeId { get; set; }
    public string AttendanceType { get; set; }
}

// ScanQRCodeDTO.cs
public class ScanQRCodeDTO
{
    public String Token { get; set; }
}

// UserAttendanceFilterDTO.cs
public class UserAttendanceFilterDTO
{
    public Guid? GroupId { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public int Page { get; set; } = 1;
    public int Limit { get; set; } = 10;
}
