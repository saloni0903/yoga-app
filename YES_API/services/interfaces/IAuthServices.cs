using yesmain.DTOs;

public interface IAuthServices
{
    Task<string> CreateAsync(CreateUserDto dto);
    Task<string> LoginAsync(LoginDto dto);
    Task<string> ForgotPasswordAsync(ForgotRequestDto dto);
    Task<string> ResetPasswordAsync(RequestPasswordDto dto);
    Task<UserProfileResponseDto> GetProfileAsync();
    Task<UserProfileResponseDto> UpdateProfileAsync(UpdateProfileRequest dto);
}