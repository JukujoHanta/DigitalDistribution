using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace Web.Data
{
    public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : IdentityDbContext<ApplicationUser, IdentityRole<int>, int>(options)
    {
        public DbSet<Tag> Tags { get; set; }
        public DbSet<Product> Products { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);
        }
        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    => optionsBuilder
        .UseSqlite("Data Source=DigitalDistribution.db")
        .UseSeeding((context, _) =>
        {
            var tag = context.Set<Tag>().FirstOrDefault(b => b.Name == "http://test.com");
            if (testBlog == null)
            {
                context.Set<Blog>().Add(new Blog { Url = "http://test.com" });
                context.SaveChanges();
            }
        });
    }
}
