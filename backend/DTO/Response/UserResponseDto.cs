using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using BCrypt.Net;

public class UserResponseDto
{
    public Guid Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;

    public string SamagraId { get; set; } = string.Empty;

    public string Location { get; set; } = string.Empty;

    public bool IsActive { get; set; } = true;
    public string? ProfileImage { get; set; }
    public DateTime? DateOfBirth { get; set; }

    public JsonDocument? EmergencyContact { get; set; }
    public JsonDocument? MedicalInfo { get; set; }

    public string Status { get; set; } = string.Empty;
    public JsonDocument? Preferences { get; set; }

    public List<string?> FcmTokens { get; set; }

    public string? ResetPasswordOtp { get; set; } = string.Empty;
    public DateTime? ResetPasswordExpires { get; set; }

    public bool? IsHealthProfileCompleted { get; set; }
    public int? CurrentStreak { get; set; }
    public int? TotalMinutesPracticed { get; set; }
    public int? TotalSessionsAttended { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public string FullName => $"{FirstName} {LastName}".Trim();
}
