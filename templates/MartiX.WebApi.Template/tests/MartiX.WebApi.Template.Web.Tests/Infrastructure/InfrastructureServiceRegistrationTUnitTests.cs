using MartiX.WebApi.SharedKernel;
using MartiX.WebApi.Template.Web.Domain.Interfaces;
using MartiX.WebApi.Template.Web.Feature.Product.List;
using MartiX.WebApi.Template.Web.Infrastructure;
using MartiX.WebApi.Template.Web.Infrastructure.Data;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using NSubstitute;

namespace MartiX.WebApi.Template.Web.Tests.Infrastructure;

public class InfrastructureServiceRegistrationTUnitTests
{
  [Test]
  public async Task AddInfrastructureServices_Throws_WhenConnectionStringMissing()
  {
    var services = new ServiceCollection();
    var config = new ConfigurationManager();
    var logger = Substitute.For<ILogger>();

    await Assert.That(() => services.AddInfrastructureServices(config, logger)).Throws<Exception>();
  }

  [Test]
  public async Task AddInfrastructureServices_WhenConnectionStringPresent_RegistersCoreServices()
  {
    var services = new ServiceCollection();
    var config = new ConfigurationManager
    {
      ["ConnectionStrings:AppDb"] = "Server=localhost,1433;Database=AppDb;User ID=sa;Password=Test123$;TrustServerCertificate=true"
    };
    var logger = Substitute.For<ILogger>();

    services.AddInfrastructureServices(config, logger);

    await Assert.That(services.Any(d => d.ServiceType == typeof(EventDispatchInterceptor))).IsTrue();
    await Assert.That(services.Any(d => d.ServiceType == typeof(IListProductsQueryService))).IsTrue();
    await Assert.That(services.Any(d => d.ServiceType == typeof(IRepository<>))).IsTrue();
    await Assert.That(services.Any(d => d.ServiceType == typeof(IReadRepository<>))).IsTrue();
  }
}

