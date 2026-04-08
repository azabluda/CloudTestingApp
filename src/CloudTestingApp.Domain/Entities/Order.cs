namespace CloudTestingApp.Domain.Entities;

public class Order
{
    public Guid Id { get; init; }
    public string CustomerName { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
    public DateTimeOffset CreatedAt { get; init; } = DateTimeOffset.UtcNow;
    public OrderStatus Status { get; set; } = OrderStatus.Pending;
}

public enum OrderStatus
{
    Pending,
    Processing,
    Shipped,
    Delivered,
    Cancelled
}
