using System.ComponentModel.DataAnnotations;

public class RequestPasswordDto
{
    [Required]
    public string Email { get; set; } = string.Empty;

    [Required]
    public string otp { get; set; } = string.Empty;

    [Required]
    public string Password { get; set; } = string.Empty;

}