using System;

namespace yesmain.DTOs
{
    public class JoinGroupResponseDto
    {
        public Guid GroupId { get; set; }
        public Guid UserId { get; set; }
        public DateTime JoinedAt { get; set; }
        public string Status { get; set; }
    }
}
