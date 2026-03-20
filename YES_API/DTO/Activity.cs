public class ActivityFeedDto
{
    public Guid Id { get; set; }
    public string Type { get; set; } = "";
    public DateTime Timestamp { get; set; }
    public object Details { get; set; } = new object();
}
