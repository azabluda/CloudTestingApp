using CloudTestingApp.Application.DTOs;
using CloudTestingApp.Application.Services;
using CloudTestingApp.Domain.Entities;
using CloudTestingApp.Domain.Interfaces;
using CloudTestingApp.Infrastructure.Persistence;
using CloudTestingApp.ServiceDefaults;

var builder = WebApplication.CreateBuilder(args);

// Aspire service defaults (OpenTelemetry, health checks, resilience)
builder.AddServiceDefaults();

// Add services to the container.
builder.Services.AddOpenApi();

// Database — Aspire injects the connection string automatically when running
// under the AppHost. For standalone/K8s the fallback reads appsettings.json.
builder.AddNpgsqlDbContext<ApplicationDbContext>("cloudtestingapp");

// DI
builder.Services.AddScoped<IOrderRepository, OrderRepository>();
builder.Services.AddScoped<IOrderService, OrderService>();

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowBlazor", policy =>
    {
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
    });
});

var app = builder.Build();

// Migrate Database
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    await context.Database.EnsureCreatedAsync();
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.MapDefaultEndpoints();

app.UseCors("AllowBlazor");

app.MapStaticAssets();

// Endpoints
var orders = app.MapGroup("/api/orders");

orders.MapGet("/", async (IOrderService orderService, CancellationToken ct) =>
{
    var result = await orderService.GetAllOrdersAsync(ct);
    return result.IsSuccess ? Results.Ok(result.Value) : Results.BadRequest(result.Error);
});

orders.MapGet("/{id:guid}", async (Guid id, IOrderService orderService, CancellationToken ct) =>
{
    var result = await orderService.GetOrderByIdAsync(id, ct);
    return result.IsSuccess ? Results.Ok(result.Value) : Results.NotFound(result.Error);
});

orders.MapPost("/", async (CreateOrderRequest request, IOrderService orderService, CancellationToken ct) =>
{
    var result = await orderService.CreateOrderAsync(request, ct);
    return result.IsSuccess ? Results.Created($"/api/orders/{result.Value!.Id}", result.Value) : Results.BadRequest(result.Error);
});

orders.MapPut("/{id:guid}/status", async (Guid id, OrderStatus status, IOrderService orderService, CancellationToken ct) =>
{
    var result = await orderService.UpdateOrderStatusAsync(id, status, ct);
    return result.IsSuccess ? Results.NoContent() : Results.BadRequest(result.Error);
});

orders.MapDelete("/{id:guid}", async (Guid id, IOrderService orderService, CancellationToken ct) =>
{
    var result = await orderService.DeleteOrderAsync(id, ct);
    return result.IsSuccess ? Results.NoContent() : Results.BadRequest(result.Error);
});

app.MapFallbackToFile("index.html");

app.Run();
