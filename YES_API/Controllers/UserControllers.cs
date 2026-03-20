using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using yesmain.DTOs;
using yesmain.Services;

namespace yesmain.Controllers
{
    [ApiController]
    [Route("api/")]
    public class UsersController : ControllerBase
    {
        private readonly IUserService _userService;

        public UsersController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpGet()]
        [Authorize]
        public async Task<IActionResult> GetAll()
        {
            try
            {
                var users = await _userService.GetAllAsync();
                return Ok(users);
            }

            catch(Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpGet("me")]
        [Authorize]
        public async Task<IActionResult> GetById()
        {
            try
            {
                var user = await _userService.GetByIdAsync();
                return Ok(user);
            }

            catch(Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }


        [HttpGet("location/{location}")]
        [Authorize]
        public async Task<IActionResult> GetAllLocation(string location)
        {
            try
            {
                var users =await  _userService.GetByLocationAsync(location);
                return Ok(users);
            }

            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpGet("instructor/location/{location}")]
        [Authorize]
        public async Task<IActionResult> GetAllInstructorByLocation(string location)
        {
            try
            {
                var users = await _userService.GetAllInstructorByLocationAsync(location);
                return Ok(users);
            }

            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }


        [Authorize]
        [HttpPut("update")]
        public async Task<IActionResult> Update([FromBody] UpdateUserDto dto)
        {
            var user = await _userService.UpdateAsync(dto);

            return Ok(new
            {
                success = true,
                data = user,
                message = "User updated Successfully"
            });
        }

        [HttpDelete("/delete")]
        [Authorize]

        public async Task<IActionResult> Delete()
        {
            try
            {
            var user = await _userService.DeleteAsync();
            return Ok(new { message = "User is deleted"});

            }

            catch(Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpGet("/ping")]
        public IActionResult Ping() => Ok("Server is running");

    }
}
