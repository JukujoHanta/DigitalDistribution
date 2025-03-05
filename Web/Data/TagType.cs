using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;

namespace Web.Data
{
    [Index(nameof(Name), IsUnique = true)]
    public class TagType
    {
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public required string? Name { get; set; }

        public List<Tag> Tags { get; set; } = [];
    }
}
