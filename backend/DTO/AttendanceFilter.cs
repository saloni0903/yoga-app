public class AttendanceFilterDto
{
    public int Page { get; set; } = 1;
    public int Limit { get; set; } = 20;
    public string Sort { get; set; } = "-marked_at";
    public string Populate { get; set; } = "";
}

public class UserDto
{
    public Guid _id { get; set; }
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public string Email { get; set; }
}

public class InstructorAttenDto
{
    public Guid _id { get; set; }
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public string Email{ get; set; }
}

public class AttendanceDto
{
    public Guid _id { get; set; }
    public Guid Id { get; set; }
    public DateTime MarkedAt { get; set; }
    public GroupDto Group { get; set; }
    public UserDto User { get; set; }
    public InstructorAttenDto InstructorAttendanceDto { get; set; }
}
