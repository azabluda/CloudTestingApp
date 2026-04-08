using CloudTestingApp.Domain.Entities;

namespace CloudTestingApp.Domain.Interfaces;

public interface IOrderRepository
{
    Task<Order?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<IEnumerable<Order>> GetAllAsync(CancellationToken ct = default);
    Task AddAsync(Order order, CancellationToken ct = default);
    void Update(Order order);
    void Delete(Order order);
    Task SaveChangesAsync(CancellationToken ct = default);
}
