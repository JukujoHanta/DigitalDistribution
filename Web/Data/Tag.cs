using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;

namespace Web.Data
{
    [Index(nameof(Name), IsUnique = true)]
    public class Tag
    {
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public required string? Name { get; set; }

        public required int? TagTypeId { get; set; }
        public TagType? TagType { get; set; }
        public ICollection<Product> Products { get; set; } = [];
    }
}
