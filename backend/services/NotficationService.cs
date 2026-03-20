public class NotificationService
{
    public Task SendAsync(Guid userId, string title, string body, object? payload = null)
    {
        // Implement FCM or Email
        Console.WriteLine($"Notify {userId}: {title} - {body}");
        return Task.CompletedTask;
    }
}
