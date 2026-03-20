using System.Threading.Tasks;
using System;
using yesmain.DTOs;

namespace yesmain.Registry
{
    public interface IUserRepository
    {
   
        Task<List<UserResponseDto>> GetAllListAsync();
        Task<List<UserResponseDto>> GetAllLocationListAsync(string location);
        Task<List<UserResponseDto>> GetAllInstructorByLocationListAsync(string location);
        Task<UserResponseDto> GetByIdRepoAsync(Guid id);
        Task<UserResponseDto> UpdateListAsync(Guid id,UserRequestDto dto);
        Task<bool> DeleteListAsync(Guid id);
    }

}
