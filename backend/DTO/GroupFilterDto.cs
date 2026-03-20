public class GroupFilterDto
{

    public string? search { get; set; } = "";
    public double? latitude { get; set; }
    public double? longitude { get; set; }
    public int page { get; set; } = 1;
    public int limit { get; set; } = 10;
    public Guid? instructor_id { get; set; }
}
