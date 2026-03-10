using MartiX.WebApi.Template.Web.Domain.ProductAggregate;

namespace MartiX.WebApi.Template.Web.Feature.Product;

public record ProductDto(ProductId Id, string Name, decimal UnitPrice);

