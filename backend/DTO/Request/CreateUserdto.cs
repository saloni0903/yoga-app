using System;
using System.ComponentModel.DataAnnotations;

namespace yesmain.DTOs
{
    public class CreateUserDto
    {
        [Required, EmailAddress]
        public string email { get; set; } = string.Empty;

        [Required, MinLength(8)]
        public string password { get; set; } = string.Empty;

        [Required]
        public string fullName { get; set; } = string.Empty;

        [Required]
        public string phone { get; set; } = string.Empty;
        
        [Required]
        public string samagraId { get; set; } = string.Empty;

        public string role { get; set; } = "participant";

        [Required]
        public string location { get; set; } = string.Empty;
    }
}
