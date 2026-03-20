using yesmain.DTOs;

namespace yesmain.Services
{
    public interface IUserService
    {
        Task<List<UserResponseDto>> GetAllAsync();
        Task<UserResponseDto> GetByIdAsync();
        Task<List<UserResponseDto>> GetByLocationAsync(string location);
        Task<List<UserResponseDto>> GetAllInstructorByLocationAsync(string location);

        Task<UserResponseDto> UpdateAsync(UpdateUserDto dto);
        Task<bool> DeleteAsync();
    }
}
