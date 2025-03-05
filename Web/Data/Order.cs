namespace Web.Data
{
    public class Order
    {
        public int Id { get; set; }
        public DateTime UpdateDate { get; set; } = DateTime.UtcNow;

        public int UserId { get; set; }
        public ApplicationUser User { get; set; } = null!;
        public List<OrderItem> OrderItems { get; set; } = [];
    }
}
