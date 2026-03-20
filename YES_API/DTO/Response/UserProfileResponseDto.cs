
public class UserProfileResponseDto
{
    public Guid Id {get; set;}
    public string Email {get; set;} = string.Empty;
    public string Role { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public string SamagraId { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}