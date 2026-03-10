using System.Linq.Expressions;
using MartiX.WebApi.SharedKernel;
using Microsoft.EntityFrameworkCore;

namespace MartiX.WebApi.Specifications.EntityFrameworkCore;

public abstract class RepositoryBase<T>(DbContext dbContext) : IRepository<T>
  where T : class, IAggregateRoot
{
  private readonly DbSet<T> _dbSet = dbContext.Set<T>();

  public async Task<T?> FirstOrDefaultAsync(
    Specifications.Specification<T> specification,
    CancellationToken cancellationToken = default)
  {
    var query = ApplySpecification(specification);
    return await query.FirstOrDefaultAsync(cancellationToken);
  }

  public async Task<T> AddAsync(T entity, CancellationToken cancellationToken = default)
  {
    await _dbSet.AddAsync(entity, cancellationToken);
    await dbContext.SaveChangesAsync(cancellationToken);
    return entity;
  }

  public async Task UpdateAsync(T entity, CancellationToken cancellationToken = default)
  {
    _dbSet.Update(entity);
    await dbContext.SaveChangesAsync(cancellationToken);
  }

  public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) =>
    dbContext.SaveChangesAsync(cancellationToken);

  private IQueryable<T> ApplySpecification(Specifications.Specification<T> specification)
  {
    IQueryable<T> query = _dbSet;

    foreach (var includeExpression in specification.IncludeExpressions)
    {
      query = ApplyInclude(query, includeExpression);
    }

    foreach (var criteriaExpression in specification.CriteriaExpressions)
    {
      query = query.Where(criteriaExpression);
    }

    return query;
  }

  private static IQueryable<T> ApplyInclude(IQueryable<T> query, LambdaExpression includeExpression) =>
    EntityFrameworkQueryableExtensions.Include((dynamic)query, (dynamic)includeExpression);
}
