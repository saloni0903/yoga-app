using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using yesmain.DTOs;

[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthServices _authservices;

    public AuthController(IAuthServices authservices)
    {
        _authservices = authservices;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] CreateUserDto dto)
    {
        try
        {
            var token = await _authservices.CreateAsync(dto);
            return Ok(new { token });
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }

    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto dto)
    {
        try
        {
            var token = await _authservices.LoginAsync(dto);

            if (token == null)
                return Unauthorized("Invalid credentials");

            return Ok(new { token });
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }

    }


    [HttpGet("me")]
    public IActionResult Me()
    {
        try
        {

            return Ok(new
            {
                UserId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value,
                Email = User.FindFirst(ClaimTypes.Email)?.Value,
                Role = User.FindFirst(ClaimTypes.Role)?.Value
            });
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword(ForgotRequestDto dto)
    {

        try
        {
            var result =await _authservices.ForgotPasswordAsync(dto);
            return Ok(result);

        }

        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }

    }

    // RESET PASSWORD
    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword(RequestPasswordDto dto)
    {
        try
        {

            var user = await _authservices.ResetPasswordAsync(dto);

            return Ok(user);
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }

    }


    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile()
    {
        try
        {
            var result = await _authservices.GetProfileAsync();
            return Ok(new { success = true, data = result });
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile(UpdateProfileRequest dto)
    {
        try
        {

            var updatedProfile =await  _authservices.UpdateProfileAsync(dto);
            return Ok(new { success = true, data = updatedProfile });
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }

    }
}