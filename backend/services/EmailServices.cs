using System.Net;
using System.Net.Mail;

public class EmailService : IEmailService
{
    private readonly IConfiguration _config;

    public EmailService(IConfiguration config)
    {
        _config = config;
    }

    public async Task SendAsync(string to, string subject, string body)
    {
        ServicePointManager.SecurityProtocol =
            SecurityProtocolType.Tls12 | SecurityProtocolType.Tls13;

        var smtpHost = _config["Email:Smtp:Host"];
        var smtpPort = int.Parse(_config["Email:Smtp:Port"]);
        var user = _config["Email:User"];
        var password = _config["Email:Password"];
        var fromName = _config["Email:FromName"];

        using var client = new SmtpClient(smtpHost, smtpPort)
        {
            EnableSsl = true,
            UseDefaultCredentials = false,
            Credentials = new NetworkCredential(user, password)
        };

        using var mail = new MailMessage
        {
            From = new MailAddress(user, fromName),
            Subject = subject,
            Body = body,
            IsBodyHtml = false
        };

        mail.To.Add(to);

        try
        {
            await client.SendMailAsync(mail);
        }
        catch (SmtpException ex)
        {
            throw new Exception(
                $"SMTP failed. StatusCode: {ex.StatusCode}, Message: {ex.Message}", ex);
        }
    }
}
