using MartiX.WebApi.Template.Web.Domain.Interfaces;
using MartiX.WebApi.Template.Web.Infrastructure;
using MartiX.WebApi.Template.Web.Infrastructure.Email;

namespace MartiX.WebApi.Template.Web.Configurations;

public static class ServiceConfigs
{
  public static IServiceCollection AddServiceConfigs(this IServiceCollection services, Microsoft.Extensions.Logging.ILogger logger, WebApplicationBuilder builder)
  {
    services.AddInfrastructureServices(builder.Configuration, logger)
            .AddMediatorSourceGen(logger);

    if (builder.Environment.IsDevelopment())
    {
      // Use a local test email server
      services.AddScoped<IEmailSender, MimeKitEmailSender>();

      // Otherwise use this:
      //builder.Services.AddScoped<IEmailSender, FakeEmailSender>();

    }
    else
    {
      services.AddScoped<IEmailSender, MimeKitEmailSender>();
    }

    logger.LogInformation("{Project} services registered", "Mediator and Email Sender");

    return services;
  }


}
