using CloudTestingApp.Domain.Entities;
using CloudTestingApp.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace CloudTestingApp.Infrastructure.Persistence;

public class OrderRepository(ApplicationDbContext context) : IOrderRepository
{
    public async Task<Order?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        await context.Orders.FirstOrDefaultAsync(o => o.Id == id, ct);

    public async Task<IEnumerable<Order>> GetAllAsync(CancellationToken ct = default) =>
        await context.Orders.ToListAsync(ct);

    public async Task AddAsync(Order order, CancellationToken ct = default) =>
        await context.Orders.AddAsync(order, ct);

    public void Update(Order order) =>
        context.Orders.Update(order);

    public void Delete(Order order) =>
        context.Orders.Remove(order);

    public async Task SaveChangesAsync(CancellationToken ct = default) =>
        await context.SaveChangesAsync(ct);
}
