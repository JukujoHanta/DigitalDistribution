namespace Web.Data
{
    public class Product
    {
        public int Id { get; set; }
        public string Slug { get; set; } = null!;
        public string Name { get; set; } = null!;
        public string Description { get; set; } = null!;
        public decimal Price { get; set; }
        public DateTime ReleaseDate { get; set; }

        public List<Tag> Tags { get; set; } = [];
        public List<OrderItem> OrderItems { get; set; } = [];
    }
}
