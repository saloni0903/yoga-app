using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Text.Json;
using yesmain.DTOs;

[ApiController]
[Route("api/group")]
public class GroupController : ControllerBase
{
    private readonly IGroupServices _groupService;

    private readonly HttpClient _httpClient;
    public GroupController(IGroupServices groupService,IHttpClientFactory httpClient)
    {
        _groupService = groupService;
        _httpClient = httpClient.CreateClient();

        // Required by Nominatim
        _httpClient.DefaultRequestHeaders.UserAgent.Clear();
        _httpClient.DefaultRequestHeaders.UserAgent.ParseAdd("YogaApp/1.0 (2909kapil2001@gmail.com)");
        _httpClient.DefaultRequestHeaders.Accept.Clear();
        _httpClient.DefaultRequestHeaders.Accept.Add(
            new MediaTypeWithQualityHeaderValue("application/json"));


    }

    [Authorize]
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] GroupRequestDto dto)
    {
        try
        {

            var group = await _groupService.CreateGroupAsync(dto);
            return Ok(new { success = true, data = group });
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [Authorize]
    [HttpPost("{groupId}/join")]
    public async Task<IActionResult> JoinGroup(Guid groupId)
    {

        try
        {

            var result = await _groupService.JoinGroupAsync(groupId);

            return StatusCode(StatusCodes.Status201Created, new
            {
                success = true,
                message = "Successfully joined the group",
                data = result
            });
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [Authorize]
    [HttpGet]
    public async Task<IActionResult> GetGroups([FromQuery] GroupFilterDto filter)
    {
        try
        {
            // Final combined list from service
            var allGroups = await _groupService.GetGroupsAsync(filter);

            // Safe pagination defaults
            var page = filter.page <= 0 ? 1 : filter.page;
            var limit = filter.limit <= 0 ? 10 : filter.limit;
            var skip = (page - 1) * limit;

            var total = allGroups.Count;

            // Node: allGroups.slice(skip, skip + limit)
            var paginatedGroups = allGroups
                .Skip(skip)
                .Take(limit)
                .ToList();

            return Ok(new
            {
                success = true,
                data = new
                {
                    groups = paginatedGroups,
                    pagination = new
                    {
                        current = page,
                        pages = (int)Math.Ceiling(total / (double)limit),
                        total
                    }
                }
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new
            {
                success = false,
                message = "Failed to fetch groups",
                error = ex.Message
            });
        }
    }

    [Authorize]
    [HttpGet("my-groups")]
    public async Task<IActionResult> MyGroups()
    {
        try
        {

            return Ok(await _groupService.GetMyGroupsAsync());
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [Authorize]
    [HttpGet("{id}")]
    public async Task<IActionResult> GetGroupById(Guid id)
    {
        var group = await _groupService.GetByIdAsync(id);

        if (group == null)
        {
            return NotFound(new
            {
                success = false,
                message = "Group not found"
            });
        }

        return Ok(new
        {
            success = true,
            data = group
        });
    }


    [Authorize]
    [HttpDelete("{groupId}/leave")]
    public async Task<IActionResult> Leave(Guid groupId)
    {
        await _groupService.LeaveAsync(groupId);
        return Ok(new { success = true });
    }

    [Authorize]
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateGroupReqDto dto)
    {
        try
        {

            await _groupService.UpdateAsync(id, dto);
            return Ok(new { success = true });
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [Authorize]
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        try
        {
            await _groupService.DeleteAsync(id);
            return Ok(new { success = true });
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }

    }

    [Authorize]
    [HttpGet("{groupId}/members")]

    public async Task<IActionResult> GetGroupMembers(Guid groupId)
    {
        try
        {
            return Ok(await _groupService.GetGroupMemberAsync(groupId));
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [Authorize]
    [HttpGet("reverse-geocode")]
    public async Task<IActionResult> ReverseGeocode( double? lat, double? lon)
    {
        if (lat == null || lon == null)
        {
            return BadRequest(new
            {
                success = false,
                message = "Latitude and longitude are required."
            });
        }

        try
        {
            var url =
                $"https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat={lat}&lon={lon}";

            var response = await _httpClient.GetAsync(url);

            response.EnsureSuccessStatusCode();

            var json = await response.Content.ReadAsStringAsync();

            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;

            var fullAddress = root.TryGetProperty("display_name", out var displayName)
                ? displayName.GetString()
                : "Unknown location";

            string city = string.Empty;

            if (root.TryGetProperty("address", out var address))
            {
                if (address.TryGetProperty("city", out var c))
                    city = c.GetString();
                else if (address.TryGetProperty("town", out var t))
                    city = t.GetString();
                else if (address.TryGetProperty("village", out var v))
                    city = v.GetString();
            }

            return Ok(new
            {
                success = true,
                data = new
                {
                    address = fullAddress,
                    city
                }
            });
        }
        catch (Exception ex)
        {
            Console.WriteLine("Reverse geocoding error: " + ex.Message);

            return StatusCode(500, new
            {
                success = false,
                message = "Failed to fetch address."
            });
        }
    }
}
