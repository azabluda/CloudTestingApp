using CloudTestingApp.Domain.Entities;

namespace CloudTestingApp.Application.DTOs;

public record OrderDto(
    Guid Id,
    string CustomerName,
    decimal TotalAmount,
    DateTimeOffset CreatedAt,
    OrderStatus Status);

public record CreateOrderRequest(
    string CustomerName,
    decimal TotalAmount);
