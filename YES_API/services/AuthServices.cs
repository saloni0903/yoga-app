using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using yesmain.DTOs;
using yesmain.Services;

public class AuthServices : IAuthServices
{
    private readonly IAuthRepositry _authRepository;
    private readonly IJwtService _jwtService;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly IEmailService _emailServices;

    public AuthServices(
        IAuthRepositry authRepository,
        IJwtService jwtService,
        IHttpContextAccessor httpContextAccessor,
        IEmailService emailServices)
    {
        _authRepository = authRepository;
        _jwtService = jwtService;
        _httpContextAccessor = httpContextAccessor;
        _emailServices = emailServices;
    }

    public async Task<string> CreateAsync(CreateUserDto dto)
    {
        try
        {

            var fullName = dto.fullName.Trim();
            var parts = fullName.Split(' ', 2, StringSplitOptions.RemoveEmptyEntries);

            var firstName = parts.Length > 0 ? parts[0] : "";
            var lastName = parts.Length > 1 ? parts[1] : "";

            var user = new UserRequestDto
            {
                Id = Guid.NewGuid(),
                Email = dto.email.Trim().ToLower(),
                Password = dto.password, // hashed in repo
                FirstName = firstName,
                LastName = lastName,
                Phone = dto.phone,
                SamagraId = dto.samagraId,
                Role = dto.role,
                Location = dto.location,
                Status = dto.role == "instructor" ? "pending" : "approved",
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _authRepository.CreateUserAsyncRepo(user);

            var newuser = new YesUser
            {
                Id = user.Id,
                Email = dto.email.Trim().ToLower(),
                Role = dto.role,
                CreatedAt = DateTime.UtcNow
            };

            return _jwtService.GenerateToken(newuser);
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<string> LoginAsync(LoginDto dto)
    {
        try
        {

        var user = await _authRepository.LoginUserAsyncRepo(
            dto
        );

        return _jwtService.GenerateToken(user);
        }


        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<string> ForgotPasswordAsync(ForgotRequestDto dto)
    {
        try
        {

        var user = dto.Email;
            
        if(user == null)
        {
            return "No email found";
        }

        var otp = await _authRepository.ForgotPasswordAsyncRepo(dto);

        return otp;
        }

        catch(Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<string> ResetPasswordAsync(RequestPasswordDto dto)
    {
        try
        {
            var user = dto.Email;

            if(user == null)
            {
                return "Please give a valid Email";
            }

            var otp = dto.otp;

            if(otp == null)
            {
                return "please provide a valid otp";
            }


            var result = await _authRepository.ResetPasswordAsyncRepo(dto);

            return result;
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }

    }

    public async Task<UserProfileResponseDto> GetProfileAsync()
    {
        try
        {

        var userId = GetUserIdFromContext();
        return await _authRepository.GetProfileAsyncRepo(userId);
        }


        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public async Task<UserProfileResponseDto> UpdateProfileAsync(UpdateProfileRequest dto)
    {
        try
        {
            var userId = GetUserIdFromContext();
            return await _authRepository.UpdateProfileAsyncRepo(userId, dto);
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    private Guid GetUserIdFromContext()
    {
        try
        {

            var httpContext = _httpContextAccessor.HttpContext;

            if (httpContext == null)
                throw new UnauthorizedAccessException("HTTP context is not available");

            var userIdClaim =
                httpContext.User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? httpContext.User.FindFirst("sub")?.Value
                ?? httpContext.User.FindFirst("userId")?.Value;

            if (string.IsNullOrWhiteSpace(userIdClaim))
                throw new UnauthorizedAccessException("User is not authenticated");

            if (!Guid.TryParse(userIdClaim, out var userId))
                throw new UnauthorizedAccessException("Invalid user identifier");

            return userId;
        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }
}
