using System.ComponentModel.DataAnnotations;
using System.Text.Json;

public class UserCredential
{
    [Key]
    public Guid Id { get; set; }   // FK → yes_users.id

    [Required]
    public string PasswordHash { get; set; } = null!;

    public JsonDocument FcmTokens { get; set; } =
        JsonDocument.Parse("[]");

    public string? ResetPasswordOtp { get; set; }

    public DateTime? ResetPasswordExpires { get; set; }
}
