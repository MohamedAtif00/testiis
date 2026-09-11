using Microsoft.AspNetCore.Mvc;
using ProductsApi.Models;

namespace ProductsApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private static readonly List<Product> Products =
    [
        new() { Id = 1, Name = "Laptop", Price = 999.00m, Category = "Electronics" },
        new() { Id = 2, Name = "Coffee Mug", Price = 12.50m, Category = "Kitchen" },
        new() { Id = 3, Name = "Desk Chair", Price = 249.99m, Category = "Furniture" },
        new() { Id = 4, Name = "Wireless Mouse", Price = 29.99m, Category = "Electronics" },
        new() { Id = 5, Name = "Notebook", Price = 5.99m, Category = "Office" },
        new() { Id = 6, Name = "Water Bottle", Price = 18.00m, Category = "Kitchen" }
    ];

    [HttpGet]
    public ActionResult<IEnumerable<Product>> GetProducts()
    {
        return Ok(Products);
    }
}
