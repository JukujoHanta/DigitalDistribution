using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using System.Data;
using Web.Components.Account.Pages.Manage;

namespace Web.Data
{
    public static class DatabaseInitializer
    {
        public static async Task InitializeAsync(IServiceProvider serviceProvider)
        {
            using var scope = serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
            var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole<int>>>();
            
            await context.Database.MigrateAsync();

            await SeedRolesAsync(roleManager);
            await SeedUsersAsync(userManager);
            await SeedCoreDataAsync(context);
        }

        private static async Task SeedRolesAsync(RoleManager<IdentityRole<int>> roleManager)
        {
            foreach (var role in new[] { "admin", "user" })
            {
                if (!await roleManager.RoleExistsAsync(role))
                {
                    await roleManager.CreateAsync(new IdentityRole<int>(role));
                }
            }
        }

        private static async Task SeedUsersAsync(UserManager<ApplicationUser> userManager)
        {
            var users = new[]
            {
                new { UserName = "admin", Email = "admin@mail.com", Role = "admin" },
                new { UserName = "user1", Email = "user1@mail.com", Role = "user" },
                new { UserName = "user2", Email = "user2@mail.com", Role = "user" }
            };

            foreach (var user in users)
            {
                if (await userManager.FindByEmailAsync(user.Email) == null)
                {
                    var newUser = new ApplicationUser
                    {
                        UserName = user.UserName,
                        Email = user.Email,
                        EmailConfirmed = true
                    };

                    await userManager.CreateAsync(newUser, "123");
                    await userManager.AddToRoleAsync(newUser, user.Role);
                }
            }
        }
        public static async Task SeedCoreDataAsync(ApplicationDbContext context)
        {
            if (!await context.Tags.AnyAsync())
            {
                await context.Tags.AddRangeAsync(
                    new Tag { Name = "РПГ", TagTypeId = 1 },
                    new Tag { Name = "Экшн", TagTypeId = 1 },
                    new Tag { Name = "Стратегия", TagTypeId = 1 }
                );
                await context.SaveChangesAsync();
            }
        }
    }
}