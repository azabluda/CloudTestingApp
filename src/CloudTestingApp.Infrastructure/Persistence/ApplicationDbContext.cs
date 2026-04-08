using CloudTestingApp.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace CloudTestingApp.Infrastructure.Persistence;

public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : DbContext(options)
{
    public DbSet<Order> Orders => Set<Order>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Order>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.CustomerName).IsRequired().HasMaxLength(200);
            entity.Property(e => e.TotalAmount).HasPrecision(18, 2);
        });

        base.OnModelCreating(modelBuilder);
    }
}
