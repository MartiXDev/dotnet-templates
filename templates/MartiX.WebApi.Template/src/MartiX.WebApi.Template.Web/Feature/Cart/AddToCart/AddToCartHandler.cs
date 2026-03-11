using MartiX.WebApi.Template.Web.Domain.CartAggregate;
using MartiX.WebApi.Template.Web.Domain.CartAggregate.Specifications;
using MartiX.WebApi.Template.Web.Domain.ProductAggregate;
using MartiX.WebApi.Template.Web.Domain.ProductAggregate.Specifications;
using CartEntity = MartiX.WebApi.Template.Web.Domain.CartAggregate.Cart;
using ProductEntity = MartiX.WebApi.Template.Web.Domain.ProductAggregate.Product;

namespace MartiX.WebApi.Template.Web.Feature.Cart.AddToCart;

public record AddToCartCommand(CartId? CartId, int ProductId, int Quantity) : ICommand<Result<CartDto>>;

public class AddToCartHandler(
  IRepository<CartEntity> cartRepository,
  IReadRepository<ProductEntity> productRepository)
  : ICommandHandler<AddToCartCommand, Result<CartDto>>
{
  public async ValueTask<Result<CartDto>> Handle(AddToCartCommand request, CancellationToken cancellationToken)
  {
    // Validate product exists
    var productSpec = new ProductByIdSpec(ProductId.From(request.ProductId));
    var product = await productRepository.FirstOrDefaultAsync(productSpec, cancellationToken);
    if (product == null)
    {
      return Result<CartDto>.NotFound("Product not found");
    }

    // Get or create cart
    CartEntity cart;
    if (request.CartId.HasValue)
    {
      var cartSpec = new CartByIdSpec(request.CartId.Value);
      var existingCart = await cartRepository.FirstOrDefaultAsync(cartSpec, cancellationToken);
      if (existingCart == null)
      {
        return Result<CartDto>.NotFound("Cart not found");
      }
      cart = existingCart;
    }
    else
    {
      // Create new cart - AddAsync saves by default
      cart = new CartEntity();
      cart = await cartRepository.AddAsync(cart, cancellationToken);
    }

    // Add item to cart
    cart.AddItem(request.ProductId, request.Quantity, product.UnitPrice);

    // Update the cart with the new items
    await cartRepository.UpdateAsync(cart, cancellationToken);

    // Map to DTO
    var items = cart.Items.Select(i => new CartItemDto(
      i.ProductId,
      i.Quantity,
      i.UnitPrice,
      i.Quantity * i.UnitPrice
    )).ToList();

    var total = items.Sum(i => i.TotalPrice);

    return new CartDto(cart.Id, items, total);
  }
}
