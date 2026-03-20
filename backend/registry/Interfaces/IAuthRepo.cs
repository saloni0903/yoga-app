using Microsoft.AspNetCore.Identity.Data;
using yesmain.DTOs;

public interface IAuthRepositry
{
    Task CreateUserAsyncRepo(UserRequestDto user);
    Task<YesUser> LoginUserAsyncRepo(LoginDto dto);
    Task<UserProfileResponseDto> GetProfileAsyncRepo(Guid userId);
    Task<UserProfileResponseDto> UpdateProfileAsyncRepo(Guid userId,UpdateProfileRequest dto);
    Task<string> ForgotPasswordAsyncRepo(ForgotRequestDto dto);
    Task<string> ResetPasswordAsyncRepo(RequestPasswordDto dto);


}