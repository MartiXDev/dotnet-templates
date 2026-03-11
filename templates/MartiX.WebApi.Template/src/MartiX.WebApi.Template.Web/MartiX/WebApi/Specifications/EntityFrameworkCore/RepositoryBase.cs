using System.Linq.Expressions;
using MartiX.WebApi.SharedKernel;
using Microsoft.EntityFrameworkCore;
using System.Reflection;

namespace MartiX.WebApi.Specifications.EntityFrameworkCore;

public abstract class RepositoryBase<T>(DbContext dbContext) : IRepository<T>
  where T : class, IAggregateRoot
{
  private static readonly MethodInfo IncludeMethodDefinition = typeof(EntityFrameworkQueryableExtensions)
    .GetMethods(BindingFlags.Public | BindingFlags.Static)
    .Single(method =>
      method.Name == nameof(EntityFrameworkQueryableExtensions.Include) &&
      method.IsGenericMethodDefinition &&
      method.GetParameters().Length == 2 &&
      method.GetParameters()[1].ParameterType.IsGenericType &&
      method.GetParameters()[1].ParameterType.GetGenericTypeDefinition() == typeof(Expression<>));

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
    (IQueryable<T>)IncludeMethodDefinition
      .MakeGenericMethod(typeof(T), includeExpression.ReturnType)
      .Invoke(null, [query, includeExpression])!;
}
