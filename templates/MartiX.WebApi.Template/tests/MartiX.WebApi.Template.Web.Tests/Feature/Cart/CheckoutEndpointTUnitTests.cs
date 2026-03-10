using FastEndpoints;
using MartiX.WebApi.Template.Web.Feature.Cart.Checkout;
using Mediator;
using Microsoft.AspNetCore.Http.HttpResults;
using NSubstitute;

namespace MartiX.WebApi.Template.Web.Tests.Feature.Cart;

public class CheckoutEndpointTUnitTests
{
  [Test]
  public async Task ExecuteAsync_WhenResultInvalid_MapsRequestAndReturnsValidationProblem()
  {
    var mediator = Substitute.For<IMediator>();
    CheckoutCommand? captured = null;
    var cartId = Guid.NewGuid();
    mediator.Send(Arg.Do<CheckoutCommand>(command => captured = command), Arg.Any<CancellationToken>())
      .Returns(MartiX.WebApi.Results.Result<CheckoutResult>.Invalid(new MartiX.WebApi.Results.ValidationError("Cart is empty")));

    var endpoint = new CheckoutEndpoint(mediator);
    var response = await endpoint.ExecuteAsync(new CheckoutRequest { CartId = cartId, Email = "guest@test.dev" }, CancellationToken.None);

    await Assert.That(captured).IsNotNull();
    var command = captured!;
    await Assert.That(command.CartId.Value == cartId && command.Email == "guest@test.dev").IsTrue();
    await Assert.That(response.Result is not ValidationProblem).IsFalse();
  }
}
