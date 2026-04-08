using CloudTestingApp.Domain.Entities;

namespace CloudTestingApp.Application.DTOs;

public record OrderDto(
    Guid Id,
    string CustomerName,
    decimal TotalAmount,
    DateTimeOffset CreatedAt,
    OrderStatus Status);

public class CreateOrderRequest
{
    public string CustomerName { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }

    public CreateOrderRequest() { }
    public CreateOrderRequest(string customerName, decimal totalAmount)
    {
        CustomerName = customerName;
        TotalAmount = totalAmount;
    }
}
