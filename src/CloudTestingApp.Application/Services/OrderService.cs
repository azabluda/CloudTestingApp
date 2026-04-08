using CloudTestingApp.Application.DTOs;
using CloudTestingApp.Domain.Common;
using CloudTestingApp.Domain.Entities;
using CloudTestingApp.Domain.Interfaces;

namespace CloudTestingApp.Application.Services;

public interface IOrderService
{
    Task<Result<OrderDto>> GetOrderByIdAsync(Guid id, CancellationToken ct = default);
    Task<Result<IEnumerable<OrderDto>>> GetAllOrdersAsync(CancellationToken ct = default);
    Task<Result<OrderDto>> CreateOrderAsync(CreateOrderRequest request, CancellationToken ct = default);
    Task<Result> UpdateOrderStatusAsync(Guid id, OrderStatus status, CancellationToken ct = default);
    Task<Result> DeleteOrderAsync(Guid id, CancellationToken ct = default);
}

public class OrderService(IOrderRepository orderRepository) : IOrderService
{
    public async Task<Result<OrderDto>> GetOrderByIdAsync(Guid id, CancellationToken ct = default)
    {
        var order = await orderRepository.GetByIdAsync(id, ct);
        if (order is null) return Result<OrderDto>.Failure("Order not found.");
        
        return Result<OrderDto>.Success(MapToDto(order));
    }

    public async Task<Result<IEnumerable<OrderDto>>> GetAllOrdersAsync(CancellationToken ct = default)
    {
        var orders = await orderRepository.GetAllAsync(ct);
        return Result<IEnumerable<OrderDto>>.Success(orders.Select(MapToDto));
    }

    public async Task<Result<OrderDto>> CreateOrderAsync(CreateOrderRequest request, CancellationToken ct = default)
    {
        var order = new Order
        {
            Id = Guid.NewGuid(),
            CustomerName = request.CustomerName,
            TotalAmount = request.TotalAmount,
            CreatedAt = DateTimeOffset.UtcNow,
            Status = OrderStatus.Pending
        };

        await orderRepository.AddAsync(order, ct);
        await orderRepository.SaveChangesAsync(ct);

        return Result<OrderDto>.Success(MapToDto(order));
    }

    public async Task<Result> UpdateOrderStatusAsync(Guid id, OrderStatus status, CancellationToken ct = default)
    {
        var order = await orderRepository.GetByIdAsync(id, ct);
        if (order is null) return Result.Failure("Order not found.");

        order.Status = status;
        orderRepository.Update(order);
        await orderRepository.SaveChangesAsync(ct);

        return Result.Success();
    }

    public async Task<Result> DeleteOrderAsync(Guid id, CancellationToken ct = default)
    {
        var order = await orderRepository.GetByIdAsync(id, ct);
        if (order is null) return Result.Failure("Order not found.");

        orderRepository.Delete(order);
        await orderRepository.SaveChangesAsync(ct);

        return Result.Success();
    }

    private static OrderDto MapToDto(Order order) =>
        new(order.Id, order.CustomerName, order.TotalAmount, order.CreatedAt, order.Status);
}
