var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();

var frontendOrigin = builder.Configuration["FrontendOrigin"];

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        var origins = new List<string>
        {
            "http://localhost:4200",
            "http://localhost:8080",
            "http://tms.local.com:8080"
        };

        if (!string.IsNullOrWhiteSpace(frontendOrigin))
        {
            origins.Add(frontendOrigin);
        }

        policy.WithOrigins(origins.Distinct().ToArray())
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors("AllowFrontend");
app.UseAuthorization();
app.MapControllers();

app.Run();
