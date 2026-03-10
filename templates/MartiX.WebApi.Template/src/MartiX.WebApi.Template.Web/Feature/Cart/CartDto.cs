using MartiX.WebApi.Template.Web.Domain.CartAggregate;

namespace MartiX.WebApi.Template.Web.Feature.Cart;

public record CartDto(CartId Id, IReadOnlyList<CartItemDto> Items, decimal Total);

public record CartItemDto(int ProductId, int Quantity, decimal UnitPrice, decimal TotalPrice);

