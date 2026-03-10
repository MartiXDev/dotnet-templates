using System.Linq.Expressions;

namespace MartiX.WebApi.Specifications;

public abstract class Specification<T>
{
  protected Specification()
  {
    Query = new SpecificationBuilder<T>(this);
  }

  internal List<Expression<Func<T, bool>>> CriteriaExpressions { get; } = [];
  internal List<LambdaExpression> IncludeExpressions { get; } = [];

  protected SpecificationBuilder<T> Query { get; }
}

public sealed class SpecificationBuilder<T>(Specification<T> specification)
{
  public SpecificationBuilder<T> Where(Expression<Func<T, bool>> predicate)
  {
    specification.CriteriaExpressions.Add(predicate);
    return this;
  }

  public SpecificationBuilder<T> Include<TProperty>(Expression<Func<T, TProperty>> includeExpression)
  {
    specification.IncludeExpressions.Add(includeExpression);
    return this;
  }
}
