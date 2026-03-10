using MartiX.WebApi.Template.Web.Domain.CartAggregate;
using MartiX.WebApi.Template.Web.Domain.GuestUserAggregate;
using MartiX.WebApi.Template.Web.Domain.OrderAggregate;
using MartiX.WebApi.Template.Web.Domain.ProductAggregate;
using Vogen;

namespace MartiX.WebApi.Template.Web.Infrastructure.Data.Config;

[EfCoreConverter<ProductId>]
[EfCoreConverter<CartId>]
[EfCoreConverter<CartItemId>]
[EfCoreConverter<GuestUserId>]
[EfCoreConverter<OrderId>]
[EfCoreConverter<OrderItemId>]
[EfCoreConverter<Quantity>]
[EfCoreConverter<Price>]
internal partial class VogenEfCoreConverters;
