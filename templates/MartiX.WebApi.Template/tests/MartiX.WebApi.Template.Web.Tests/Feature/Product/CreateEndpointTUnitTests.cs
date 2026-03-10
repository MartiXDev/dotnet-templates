using MartiX.WebApi.SharedKernel;
using MartiX.WebApi.Template.Web.Feature.Product;
using MartiX.WebApi.Template.Web.Feature.Product.Create;
using Microsoft.AspNetCore.Http.HttpResults;
using NSubstitute;
using ProductEntity = MartiX.WebApi.Template.Web.Domain.ProductAggregate.Product;

namespace MartiX.WebApi.Template.Web.Tests.Feature.Product;

public class CreateEndpointTUnitTests
{
  [Test]
  public async Task ExecuteAsync_WhenCreateSucceeds_ReturnsCreatedProductRecord()
  {
    var repository = Substitute.For<IRepository<ProductEntity>>();
    repository.AddAsync(Arg.Any<ProductEntity>(), Arg.Any<CancellationToken>())
      .Returns(call => call.Arg<ProductEntity>());
    repository.SaveChangesAsync(Arg.Any<CancellationToken>()).Returns(1);
    var endpoint = new CreateEndpoint(repository);

    var response = await endpoint.ExecuteAsync(new CreateProductRequest { Name = "Created via endpoint", UnitPrice = 9.9m }, CancellationToken.None);

    await Assert.That(response.Result is not Created<ProductRecord>).IsFalse();
  }
}

