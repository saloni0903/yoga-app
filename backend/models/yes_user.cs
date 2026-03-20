using System.ComponentModel.DataAnnotations;

public class YesUser
{
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required, EmailAddress]
    public string Email { get; set; } = null!;

    public string Role { get; set; } = "participant";

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
