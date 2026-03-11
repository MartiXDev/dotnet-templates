using MartiX.WebApi.SharedKernel;
using Mediator;

namespace MartiX.WebApi.Template.Web.Infrastructure;

public sealed class MediatorDomainEventDispatcher(IPublisher publisher) : IDomainEventDispatcher
{
  public async Task DispatchAndClearEvents(
    IEnumerable<HasDomainEventsBase> entitiesWithEvents,
    CancellationToken cancellationToken = default)
  {
    foreach (var entity in entitiesWithEvents)
    {
      foreach (var domainEvent in entity.DomainEvents.OfType<INotification>())
      {
        await publisher.Publish(domainEvent, cancellationToken);
      }

      entity.ClearDomainEvents();
    }
  }
}
