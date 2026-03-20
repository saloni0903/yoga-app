using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/qr")]
public class QRController : ControllerBase
{
    private readonly ISessionQRService _service;

    public QRController(ISessionQRService service)
    {
        _service = service;
    }

    [HttpPost("generate")]
    public async Task<IActionResult> Generate([FromBody]GenerateQRRequest req)
    {
        try
        {
            var qrCode = await _service.GenerateAsync(req);

            return StatusCode(StatusCodes.Status201Created, new
            {
                success = true,
                message = "QR code generated successfully",
                data = qrCode
            });
        }


        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost("scan")]
    public async Task<IActionResult> Scan([FromBody] ScanQRRequest req)
    {
        try
        {

        return Ok( await _service.ValidateAndUseAsync(req.Token, req.Location));
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpGet("group/{groupId}")]
    public async Task<IActionResult> GetGroup(Guid groupId, DateTime? sessionDate)
    {
        try
        {

        return Ok(await _service.GetActiveForGroupAsync(groupId, sessionDate));
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPut("{id}/deactivate")]
    public async Task<IActionResult> Deactivate(Guid id)
    {
        try
        {
            await _service.DeactivateAsync(id);
            return Ok();
        }

        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }
}
