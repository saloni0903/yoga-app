public class GroupDto
{
    public Guid _id { get; set; }
    public Guid id { get; set; }        

    public string group_name { get; set; }
    public string groupType { get; set; }

    public string description { get; set; }
    public string yoga_style { get; set; }

    public double? latitude { get; set; }
    public double? longitude { get; set; }
    public double? distance { get; set; }

    public string location_address { get; set; }
    public string location_text { get; set; }

    public DateTime created_at { get; set; }

    // IMPORTANT: Node uses instructor_id as OBJECT, not GUID
    public InstructorDto instructor_id { get; set; }

    public InstructorAttenDto InstructorAttendanceDto { get; set; }

}


public class PaginationDto
{
    public int current { get; set; }
    public int pages { get; set; }
    public int total { get; set; }
}
