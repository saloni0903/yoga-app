using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;
using yesmain.registry;
using yesmain.Registry;
using yesmain.Registry.Interfaces;
using yesmain.Services;
using yesmain.Services.Interfaces;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddHttpContextAccessor();

builder.Services.AddControllers();
builder.Services.AddScoped<IDashboardService, DashboardService>();
builder.Services.AddScoped<IAuthServices, AuthServices>();
builder.Services.AddScoped<IJwtService,JwtService >();
builder.Services.AddScoped<IUserService,UserService >();
builder.Services.AddScoped<IGroupServices,GroupServices >();
builder.Services.AddScoped<IAttendanceService, AttendanceService>();
builder.Services.AddScoped<IHealthServices, HealthServices>();
builder.Services.AddScoped<ISessionQRService, SessionQRService>();
builder.Services.AddScoped<IQrSessionRepo, SessionQRRepository>();
builder.Services.AddScoped<IAdminRepository, AdminRepository>();
builder.Services.AddScoped<IAdminService, AdminService>();
builder.Services.AddScoped<ReminderLogRepository>();
builder.Services.AddScoped<ReminderLogService>();

builder.Services.AddScoped<IUserRepository>(provider =>
{
    var configuration = provider.GetRequiredService<IConfiguration>();
    return new UserRepository(configuration);
});

builder.Services.AddScoped<IGroupRepo>(provider =>
{
    var configuration = provider.GetRequiredService<IConfiguration>();
    return new GroupRepository(configuration);
});

builder.Services.AddScoped<IAttendanceRepository>(provider =>
{
    var configuration = provider.GetRequiredService<IConfiguration>();
    return new AttendanceRepository(configuration);
});

builder.Services.AddScoped<IHealthRepo>(provider =>
{
    var configuration = provider.GetRequiredService<IConfiguration>();
    return new HealthRegistry(configuration);
});


builder.Services.AddScoped<IQrSessionRepo>(provider =>
{
    var configuration = provider.GetRequiredService<IConfiguration>();
    return new SessionQRRepository(configuration);
});

builder.Services.AddScoped<IDashboardRepository>(provider =>
{
    var configuration = provider.GetRequiredService<IConfiguration>();
    return new DashboardRepository(configuration);
});

builder.Services.AddScoped<IAuthRepositry>(provider =>
{
    var configuration = provider.GetRequiredService<IConfiguration>();
    return new AuthRepositry(configuration);
});

builder.Services.AddScoped<IEmailService>(provider =>
{
    var configuration = provider.GetRequiredService<IConfiguration>();
    return new EmailService(configuration);
});
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowReactApp", policy =>
    {
        policy
            .WithOrigins("http://localhost:5173")
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
        policy
          .SetIsOriginAllowed(origin =>
          {
              if (Uri.TryCreate(origin, UriKind.Absolute, out var uri))
              {
                  return uri.Host == "localhost";
              }
              return false;
          }).AllowAnyMethod().AllowAnyHeader().AllowCredentials();
    });

    
});


builder.WebHost.ConfigureKestrel(options =>
{
    options.ListenLocalhost(7155, listenOptions =>
    {
        listenOptions.UseHttps(); // Ensure HTTPS is enabled
    });
});


builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "YES API",
        Version = "v1"
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter: Bearer {token}"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var jwtConfig = builder.Configuration.GetSection("Jwt");
var key = Encoding.UTF8.GetBytes(jwtConfig["Key"]!);

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtConfig["Issuer"],
        ValidAudience = jwtConfig["Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(key),
        NameClaimType = "sub",        
        RoleClaimType = "role"
    };

    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            context.Token = context.Request.Cookies["access_token"];
            return Task.CompletedTask;
        }
    };
});
builder.Services.AddHttpClient();

builder.Services.AddAuthorization();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
app.UseRouting();
app.UseCors("AllowReactApp");
app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.Run();
