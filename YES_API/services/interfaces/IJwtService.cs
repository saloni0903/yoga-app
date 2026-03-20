
namespace yesmain.Services
{
    public interface IJwtService
    {
        string GenerateToken(YesUser user);
    }
}
