public class GenerateQRRequest
{
    public Guid group_id { get; set; }
    public DateTime SessionDate { get; set; }
    public SessionQROptions? Options { get; set; }
}

public class ScanQRRequest
{
    public string Token { get; set; } = string.Empty;
    public LocationDto? Location { get; set; }
}

public class SessionQROptions
{
    public DateTime? SessionStartTime { get; set; }
    public DateTime? SessionEndTime { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public int? MaxUsage { get; set; }
    public object? LocationRestriction { get; set; }
    public object? Metadata { get; set; }
}

public class LocationDto
{
    public double Latitude { get; set; }
    public double Longitude { get; set; }
}
