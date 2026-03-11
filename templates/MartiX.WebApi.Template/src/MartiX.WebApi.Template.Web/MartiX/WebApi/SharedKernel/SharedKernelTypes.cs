using MartiX.WebApi.Results;

namespace MartiX.WebApi.SharedKernel;

public class ValidationError(string errorMessage, string? identifier = null)
  : MartiX.WebApi.Results.ValidationError(errorMessage, identifier);

public interface IAggregateRoot;

public abstract class HasDomainEventsBase
{
  private readonly List<object> _domainEvents = [];

  public IReadOnlyCollection<object> DomainEvents => _domainEvents.AsReadOnly();

  protected void RegisterDomainEvent(object domainEvent) => _domainEvents.Add(domainEvent);

  public void ClearDomainEvents() => _domainEvents.Clear();
}

public abstract class EntityBase<TEntity, TId> : HasDomainEventsBase
{
  public TId Id { get; protected set; } = default!;
}

public interface IReadRepository<T>
  where T : class, IAggregateRoot
{
  Task<T?> FirstOrDefaultAsync(
    Specifications.Specification<T> specification,
    CancellationToken cancellationToken = default);
}

public interface IRepository<T> : IReadRepository<T>
  where T : class, IAggregateRoot
{
  Task<T> AddAsync(T entity, CancellationToken cancellationToken = default);
  Task UpdateAsync(T entity, CancellationToken cancellationToken = default);
  Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}

public interface IDomainEventDispatcher
{
  Task DispatchAndClearEvents(
    IEnumerable<HasDomainEventsBase> entitiesWithEvents,
    CancellationToken cancellationToken = default);
}
