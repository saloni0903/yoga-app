using Npgsql;
using System.Security.Claims;
using yesmain.DTOs;
using yesmain.Registry;

namespace yesmain.Services
{
    public class UserService : IUserService
    {
        private readonly IUserRepository _userRepository;
        private readonly IJwtService _jwtService;
        private readonly IHttpContextAccessor _httpContextAccessor;

        public UserService(IUserRepository userRepository, IJwtService jwtService, IHttpContextAccessor httpContextAccessor)
        {
            _userRepository = userRepository;
            _jwtService = jwtService;
            _httpContextAccessor = httpContextAccessor;
        }

        public async Task<List<UserResponseDto>> GetAllAsync()
        {
            try
            {

                var user = _httpContextAccessor.HttpContext?.User;

                if (user == null || !user.Identity!.IsAuthenticated)
                {
                    throw new Exception("Unauthorized");
                }

                var role = user.FindFirst(ClaimTypes.Role)?.Value ?? user.FindFirst("role")?.Value;

                var userIdStr = user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? user.FindFirst("sub")?.Value;

                if (role != "admin")
                {
                    throw new Exception("Only admin can access this list");
                }

                var records = await _userRepository.GetAllListAsync();

                return records;
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }

        }

        public async Task<List<UserResponseDto>> GetByLocationAsync(string location)
        {
            try
            {

                var user = _httpContextAccessor.HttpContext?.User;

                if (user == null || !user.Identity!.IsAuthenticated)
                {
                    throw new Exception("Unauthorized");
                }

                var role = user.FindFirst(ClaimTypes.Role)?.Value ?? user.FindFirst("role")?.Value;

                var userIdStr = user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? user.FindFirst("sub")?.Value;

                if (role != "admin")
                {
                    throw new Exception("Only admin can access this list");
                }

                var records = await _userRepository.GetAllLocationListAsync(location);

                return records;
            }

            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        public async Task<List<UserResponseDto>> GetAllInstructorByLocationAsync(string location)
        {
            try
            {

                var user = _httpContextAccessor.HttpContext?.User;

                if (user == null || !user.Identity!.IsAuthenticated)
                {
                    throw new Exception("Unauthorized");
                }

                var role = user.FindFirst(ClaimTypes.Role)?.Value ?? user.FindFirst("role")?.Value;

                var userIdStr = user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? user.FindFirst("sub")?.Value;

                if (role != "admin")
                {
                    throw new Exception("Only admin can access this list");
                }

                var records = await _userRepository.GetAllInstructorByLocationListAsync(location);

                return records;
            }

            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        public async Task<UserResponseDto> UpdateAsync(UpdateUserDto dto)
        {
            var user = _httpContextAccessor.HttpContext?.User;

            if (user == null || !user.Identity!.IsAuthenticated)
                throw new UnauthorizedAccessException("Unauthorized");

            var userIdStr =
                user.FindFirst(ClaimTypes.NameIdentifier)?.Value ??
                user.FindFirst("sub")?.Value;

            if (!Guid.TryParse(userIdStr, out var userId))
                throw new Exception("Invalid user id");

            var updateUser = new UserRequestDto
            {
                Id = Guid.Parse(userIdStr),
                FirstName = dto.FirstName,
                LastName = dto.LastName,
                Phone = dto.Phone,
                SamagraId = dto.SamagraId,
                Location = dto.Location,
                FcmTokens = dto.FcmTokens,   
                UpdatedAt = DateTime.UtcNow
            };

            return await _userRepository.UpdateListAsync(userId, updateUser);
        }

        public async Task<bool> DeleteAsync()
        {
            try
            {

                var user = _httpContextAccessor.HttpContext?.User;

                if (user == null || !user.Identity!.IsAuthenticated)
                {
                    throw new Exception("Unauthorized");
                }

                var role = user.FindFirst(ClaimTypes.Role)?.Value ?? user.FindFirst("role")?.Value;

                var userIdStr = user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? user.FindFirst("sub")?.Value;


                var records = await _userRepository.DeleteListAsync(Guid.Parse(userIdStr));

                return records;
            }

            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        public async Task<UserResponseDto> GetByIdAsync()
        {
            try
            {

                var user = _httpContextAccessor.HttpContext?.User;

                if (user == null || !user.Identity!.IsAuthenticated)
                {
                    throw new Exception("Unauthorized");
                }

                var role = user.FindFirst(ClaimTypes.Role)?.Value ?? user.FindFirst("role")?.Value;

                var userIdStr = user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? user.FindFirst("sub")?.Value;


                var records = await _userRepository.GetByIdRepoAsync(Guid.Parse(userIdStr));

                return records;

            }

            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }
    }
}
