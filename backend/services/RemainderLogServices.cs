public class ReminderLogService
{
    private readonly ReminderLogRepository _repository;

    public ReminderLogService(ReminderLogRepository repository)
    {
        _repository = repository;
    }

    public bool AddReminder(ReminderLogDto log)
    {
        try
        {

        // You can add business rules here
        return _repository.InsertReminderLog(log);
        }

        catch(Exception ex)
        {
            throw new Exception(ex.Message);
        }
    }

    public List<ReminderLogDto> GetReminders(Guid groupId, string reminderType)
    {
        try
        {

        return _repository.GetReminderLogs(groupId, reminderType);
        }


        catch (Exception ex)
        {
            throw new Exception(ex.Message);
        }


    }
}
